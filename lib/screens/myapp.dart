import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:valo_elo/constants/maps.dart';
import 'package:valo_elo/models/network_service.dart';
import 'package:http/http.dart' as http;

class MyApp extends StatefulWidget {
  MyApp({Key key}) : super(key: key);

  @override
  _MyAppState createState() {
    return _MyAppState();
  }
}

class _MyAppState extends State<MyApp> {
  final TextEditingController _controllerUsername = TextEditingController();
  final TextEditingController _controllerPassword = TextEditingController();
  String _region = 'na';
  Future<String> _user;
  Future<List<dynamic>> _matches;
  Future<String> _authURL;
  String _accessToken;
  String _entitlementToken;
  List<int> points = [0, 0, 0];

  Future<String> getUserId() async {
    final http.Response response = await http.post(
      'https://auth.riotgames.com/userinfo',
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $_accessToken',
      },
      body: jsonEncode(<String, String>{}),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      return jsonDecode(response.body)['sub'];
    } else {
      throw Exception('Failed to get user id');
    }
  }

  Future<String> getEntitlementToken() async {
    final http.Response response = await http.post(
      'https://entitlements.auth.riotgames.com/api/token/v1',
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $_accessToken',
      },
      body: jsonEncode(<String, String>{}),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      return jsonDecode(response.body)['entitlements_token'];
    } else {
      throw Exception('Failed to get user id');
    }
  }

  Future<List<dynamic>> getCompiDetails(String user) async {
    final http.Response response = await http.get(
      'https://pd.$_region.a.pvp.net/mmr/v1/players/$user/competitiveupdates?startIndex=0&endIndex=20',
      headers: <String, String>{
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_accessToken',
        'X-Riot-Entitlements-JWT': '$_entitlementToken',
      },
    );
    print(response.statusCode);
    print(jsonDecode(response.body));

    if (response.statusCode == 201 || response.statusCode == 200) {
      return jsonDecode(response.body)['Matches'];
    } else {
      throw Exception('Failed to get compi details');
    }
  }

  void updateToLatestGames(List<dynamic> matches) {
    if (matches != null && matches.isNotEmpty) {
      int count = 0, i = 0;
      matches.forEach((game) {
        if (game["CompetitiveMovement"] == "MOVEMENT_UNKNOWN") {
          // not a ranked game
        } else if (game["CompetitiveMovement"] == "PROMOTED") {
          // player promoted
          int before = game["TierProgressBeforeUpdate"];
          int after = game["TierProgressAfterUpdate"];
          int differ = (after - before) + 100;
          points[i++] = differ;
          count++;
        } else if (game["CompetitiveMovement"] == "DEMOTED") {
          // player demoted
          int before = game["TierProgressBeforeUpdate"];
          int after = game["TierProgressAfterUpdate"];
          int differ = (after - before) - 100;
          points[i++] = differ;
          count++;
        } else {
          int before = game["TierProgressBeforeUpdate"];
          int after = game["TierProgressAfterUpdate"];
          points[i++] = after - before;
          count++;
        }

        if (count >= 3) // 3 recent matches found
          return;
      });

      //Send Points to Function that changes the UI
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Valorant Elo Tracker',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: Scaffold(
        appBar: AppBar(
          title: Text('Valorant Elo Tracker'),
        ),
        body: Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.all(8.0),
          child: (_user == null)
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    TextField(
                      controller: _controllerUsername,
                      decoration: InputDecoration(hintText: 'Riot Username'),
                    ),
                    TextField(
                      controller: _controllerPassword,
                      decoration: InputDecoration(hintText: 'Password'),
                    ),
                    DropdownButton(
                      isExpanded: true,
                      value: _region,
                      items: [
                        DropdownMenuItem(
                          child: Text('Asia'),
                          value: 'ap',
                        ),
                        DropdownMenuItem(
                          child: Text('North America'),
                          value: 'na',
                        ),
                        DropdownMenuItem(
                          child: Text('Europe'),
                          value: 'eu',
                        ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _region = value;
                        });
                      },
                      icon: Icon(Icons.map),
                    ),
                    ElevatedButton(
                      child: Text('Check Elo'),
                      onPressed: () async {
                        setState(() {
                          _user = _user;
                        });
                        NetworkService session = NetworkService();
                        String url =
                            'https://auth.riotgames.com/api/v1/authorization';
                        print(await session.post(url, body: {
                          "client_id": "play-valorant-web-prod",
                          "nonce": "1",
                          "redirect_uri":
                              "https://beta.playvalorant.com/opt_in" + "",
                          "response_type": "token id_token",
                          "scope": "account openid"
                        }));
                        Map authResponse = await session.put(
                          url,
                          body: {
                            "type": "auth",
                            "username": _controllerUsername.text,
                            "password": _controllerPassword.text
                          },
                        );
                        print(authResponse['response']['parameters']['uri']);
                        String authURL =
                            authResponse['response']['parameters']['uri'];
                        setState(() {
                          _accessToken = RegExp("access_token=(.+?)&scope=")
                              .stringMatch(authURL)
                              .split('=')[1]
                              .split('&')[0];
                        });

                        print(
                            "=================== accesss token ===================");
                        print(_accessToken);
                        _entitlementToken = await getEntitlementToken();
                        setState(() {});
                        print(
                            "=================== entitlement token ===================");
                        print(_entitlementToken);
                        setState(() {
                          _user = getUserId();
                          print("clicked");
                        });
                        _matches = getCompiDetails(await _user);
                        updateToLatestGames(await _matches);
                        setState(() {});
                      },
                    ),
                  ],
                )
              : FutureBuilder<List>(
                  future: _matches,
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      Map<dynamic, dynamic> match = snapshot.data.firstWhere(
                          (element) =>
                              element['CompetitiveMovement'] !=
                              'MOVEMENT_UNKNOWN');
                      return Column(
                        children: [
                          Text(
                            'Rank : ' +
                                rankMap[match['TierAfterUpdate'].toString()],
                          ),
                          Text(
                            'Competitive Movement : ' +
                                match['CompetitiveMovement'].toString(),
                          ),
                          Text(
                            'Points For last 3 match : ' + points.toString(),
                          ),
                          Text(
                            'Rank Point : ' +
                                match['TierProgressAfterUpdate'].toString(),
                          ),
                          Text('Elo : ' +
                              ((match['TierAfterUpdate'] * 100) -
                                      300 +
                                      match['TierProgressAfterUpdate'])
                                  .toString()),
                          ElevatedButton(
                              onPressed: () async {
                                _matches = getCompiDetails(await _user);
                                updateToLatestGames(await _matches);
                                setState(() {});
                              },
                              child: Text('Refresh'))
                        ],
                      );
                    } else if (snapshot.hasError) {
                      return Text("${snapshot.error}");
                    }

                    return CircularProgressIndicator();
                  },
                ),
        ),
      ),
    );
  }
}
