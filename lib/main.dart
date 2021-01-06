import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

const Map<String, String> rankMap = {
  "0": "Unrated",
  "1": "Unknown 1",
  "2": "Unknown 2",
  "3": "Iron 1",
  "4": "Iron 2",
  "5": "Iron 3",
  "6": "Bronze 1",
  "7": "Bronze 2",
  "8": "Bronze 3",
  "9": "Silver 1",
  "10": "Silver 2",
  "11": "Silver 3",
  "12": "Gold 1",
  "13": "Gold 2",
  "14": "Gold 3",
  "15": "Platinum 1",
  "16": "Platinum 2",
  "17": "Platinum 3",
  "18": "Diamond 1",
  "19": "Diamond 2",
  "20": "Diamond 3",
  "21": "Immortal 1",
  "22": "Immortal 2",
  "23": "Immortal 3",
  "24": "Radiant"
};

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  MyApp({Key key}) : super(key: key);

  @override
  _MyAppState createState() {
    return _MyAppState();
  }
}

class NetworkService {
  final JsonDecoder _decoder = new JsonDecoder();
  final JsonEncoder _encoder = new JsonEncoder();

  Map<String, String> headers = {
    'Content-Type': 'application/json; charset=UTF-8',
  };
  Map<String, String> cookies = {};

  void _updateCookie(http.Response response) {
    String allSetCookie = response.headers['set-cookie'];

    if (allSetCookie != null) {
      var setCookies = allSetCookie.split(',');

      for (var setCookie in setCookies) {
        var cookies = setCookie.split(';');

        for (var cookie in cookies) {
          _setCookie(cookie);
        }
      }

      headers['cookie'] = _generateCookieHeader();
    }
  }

  void _setCookie(String rawCookie) {
    if (rawCookie.length > 0) {
      var keyValue = rawCookie.split('=');
      if (keyValue.length == 2) {
        var key = keyValue[0].trim();
        var value = keyValue[1];

        // ignore keys that aren't cookies
        if (key == 'path' || key == 'expires') return;

        this.cookies[key] = value;
      }
    }
  }

  String _generateCookieHeader() {
    String cookie = "";

    for (var key in cookies.keys) {
      if (cookie.length > 0) cookie += ";";
      cookie += key + "=" + cookies[key];
    }

    return cookie;
  }

  Future<dynamic> put(String url, {body, encoding}) {
    return http
        .put(url,
            body: _encoder.convert(body), headers: headers, encoding: encoding)
        .then((http.Response response) {
      final String res = response.body;
      final int statusCode = response.statusCode;

      _updateCookie(response);

      if (statusCode < 200 || statusCode > 400 || json == null) {
        throw new Exception("Error while fetching data");
      }
      return _decoder.convert(res);
    });
  }

  Future<dynamic> post(String url, {body, encoding}) {
    return http
        .post(url,
            body: _encoder.convert(body), headers: headers, encoding: encoding)
        .then((http.Response response) {
      final String res = response.body;
      final int statusCode = response.statusCode;

      _updateCookie(response);

      if (statusCode < 200 || statusCode > 400 || json == null) {
        throw new Exception("Error while fetching data");
      }
      return _decoder.convert(res);
    });
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
                      return Column(
                        children: [
                          Text(
                            'Rank : ' +
                                rankMap[snapshot.data.first['TierAfterUpdate']
                                    .toString()],
                          ),
                          Text(
                            'Competitive Movement : ' +
                                snapshot.data.first['CompetitiveMovement']
                                    .toString(),
                          ),
                          Text(
                            'Points For last 3 match : ' + points.toString(),
                          ),
                          Text(
                            'Rank Point : ' +
                                snapshot.data.first['TierProgressAfterUpdate']
                                    .toString(),
                          ),
                          Text('Elo : ' +
                              ((snapshot.data.first['TierAfterUpdate'] * 100) -
                                      300 +
                                      snapshot.data
                                          .first['TierProgressAfterUpdate'])
                                  .toString()),
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
