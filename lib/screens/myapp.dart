import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:valo_elo/constants/maps.dart';
import 'package:valo_elo/models/network_service.dart';
import 'package:http/http.dart' as http;
import 'package:valo_elo/widgets/point_card.dart';

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
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _obscureText = true;
  String _region = 'na';
  String _user;
  Future<List<dynamic>> _matches;
  String _accessToken;
  String _entitlementToken;
  bool _isLoading = false;
  List<int> points = List();

  void _toggleLogin() {
    setState(() {
      _obscureText = !_obscureText;
    });
  }

  void showInSnackBar(String value) {
    FocusScope.of(context).requestFocus(FocusNode());
    _scaffoldKey.currentState?.removeCurrentSnackBar();
    var kFont;
    _scaffoldKey.currentState.showSnackBar(SnackBar(
      content: Text(
        value,
        textAlign: TextAlign.center,
        style:
            TextStyle(color: Colors.white, fontSize: 16.0, fontFamily: kFont),
      ),
      backgroundColor: Colors.black.withOpacity(0.5),
      duration: Duration(seconds: 3),
    ));
  }

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
      print("=================== user_id ===================");
      print(jsonDecode(response.body)['sub']);
      return jsonDecode(response.body)['sub'];
    } else {
      showInSnackBar('Failed to get user id');
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
      showInSnackBar('Failed to get Entitilement token');
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
        'X-Riot-ClientPlatform':
            'ew0KCSJwbGF0Zm9ybVR5cGUiOiAiUEMiLA0KCSJwbGF0Zm9ybU9TIjogIldpbmRvd3MiLA0KCSJwbGF0Zm9ybU9TVmVyc2lvbiI6ICIxMC4wLjE5MDQyLjEuMjU2LjY0Yml0IiwNCgkicGxhdGZvcm1DaGlwc2V0IjogIlVua25vd24iDQp9'
      },
    );
    print(response.statusCode);
    print(jsonDecode(response.body));

    if (response.statusCode == 201 || response.statusCode == 200) {
      return jsonDecode(response.body)['Matches'];
    } else {
      showInSnackBar('Failed to Compitetive Details');
      throw Exception('Failed to get compi details');
    }
  }

  void updateToLatestGames(List<dynamic> matches) {
    if (matches != null && matches.isNotEmpty) {
      int count = 0;
      matches.forEach((game) {
        if (game["TierAfterUpdate"] == 0) {
          points.add(0);
          print("Tier not changed");
        } else {
          points.insert(0, game["RankedRatingEarned"]);
          count++;
        }

        if (count >= 3) // 3 recent matches found
          return;
      });

      //Send Points to Function that changes the UI
    }
    setState(() {});
  }

  Color getProgressColor(int points) {
    if (points < 25)
      return Colors.red;
    else if (points < 75)
      return Colors.yellow;
    else
      return Colors.green;
  }

  @override
  void dispose() {
    _controllerUsername.dispose();
    _controllerPassword.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    return Scaffold(
      key: _scaffoldKey,
      body: Container(
        color: Colors.white,
        alignment: Alignment.center,
        child: (_user == null)
            ? SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    SizedBox(
                      height: size.height * 0.065,
                      width: size.width,
                    ),
                    Image.network(
                      'https://i.ibb.co/PZQm2Cd/CITYPNG-COM-HD-Valorant-Black-Symbol-Icon-Sign-Logo-PNG-5019x2800.png',
                      height: 64,
                    ),
                    SizedBox(
                      height: size.height * 0.02,
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 26),
                      child: Text(
                        'Sign in with your\nRiot Account',
                        style: TextStyle(
                            fontSize: 36, fontWeight: FontWeight.bold),
                      ),
                    ),
                    SizedBox(
                      height: size.height * 0.05,
                    ),
                    buildLoginForm(size),
                    SizedBox(
                      height: size.height * 0.025,
                    ),
                    Container(
                      margin: const EdgeInsets.all(12.0),
                      padding: const EdgeInsets.all(12.0),
                      decoration: BoxDecoration(
                        border: Border.all(
                          width: 2,
                          color: Colors.black,
                        ),
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      child: buildDropDown(),
                    ),
                    SizedBox(
                      height: size.height * 0.05,
                    ),
                    Align(
                      alignment: Alignment.center,
                      child: SizedBox(
                        width: 80,
                        height: 80,
                        child: RaisedButton(
                          hoverColor: Colors.redAccent.shade200,
                          color: Colors.black,
                          child: _isLoading
                              ? CircularProgressIndicator(
                                  backgroundColor: Colors.white,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.redAccent.shade200,
                                  ),
                                )
                              : Icon(
                                  Icons.arrow_forward_rounded,
                                  size: 42,
                                  color: Colors.white,
                                ),
                          focusColor: Colors.redAccent.shade200,
                          splashColor: Colors.redAccent.shade200,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                              side: BorderSide.none),
                          onPressed: _isLoading
                              ? () {
                                  print('wait, its loading');
                                }
                              : () async {
                                  if (_formKey.currentState.validate()) {
                                    setState(() {
                                      _isLoading = true;
                                    });
                                    NetworkService session = NetworkService();
                                    String url =
                                        'https://auth.riotgames.com/api/v1/authorization';
                                    print(await session.post(url, body: {
                                      "client_id": "play-valorant-web-prod",
                                      "nonce": "1",
                                      "redirect_uri":
                                          "https://playvalorant.com/opt_in" +
                                              "",
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
                                    print(authResponse);
                                    if (authResponse['type'] == 'response') {
                                      print(authResponse['response']
                                          ['parameters']['uri']);
                                      String authURL = authResponse['response']
                                          ['parameters']['uri'];
                                      setState(() {
                                        _accessToken =
                                            RegExp("access_token=(.+?)&scope=")
                                                .stringMatch(authURL)
                                                .split('=')[1]
                                                .split('&')[0];
                                      });

                                      print(
                                          "=================== accesss token ===================");
                                      print(_accessToken);
                                      _entitlementToken =
                                          await getEntitlementToken();
                                      setState(() {});
                                      print(
                                          "=================== entitlement token ===================");
                                      print(_entitlementToken);
                                      _user = await getUserId();
                                      _matches = getCompiDetails(_user);
                                      updateToLatestGames(await _matches);
                                      setState(() {});
                                    } else {
                                      showInSnackBar(
                                          'Username or Password incorrect!!!');
                                    }
                                    setState(() {
                                      _isLoading = false;
                                    });
                                  }
                                },
                        ),
                      ),
                    )
                  ],
                ),
              )
            : FutureBuilder<List>(
                future: _matches,
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    Map<dynamic, dynamic> match = snapshot.data.firstWhere(
                        (element) => element['RankedRatingAfterUpdate'] != 0,
                        orElse: () => snapshot.data.first);
                    int rr = match['RankedRatingAfterUpdate'];
                    return Container(
                      color: Color.fromRGBO(15, 25, 35, 1),
                      width: size.width,
                      height: size.height,
                      child: Column(
                        children: [
                          SizedBox(height: size.height * 0.1),
                          CircularPercentIndicator(
                            radius: 150.0,
                            lineWidth: 10.0,
                            percent: rr / 100,
                            center: Image.network(
                              'https://firebasestorage.googleapis.com/v0/b/cloud-storage-test-ac898.appspot.com/o/${match['TierAfterUpdate']}.png?alt=media&token=d0388a4f-69b6-40a9-8dde-4e10c6f61bee',
                              width: 100,
                              height: 100,
                            ),
                            backgroundWidth: 5.0,
                            circularStrokeCap: CircularStrokeCap.round,
                            progressColor: getProgressColor(rr),
                          ),
                          SizedBox(height: size.height * 0.02),
                          Text(
                            '' + rankMap[match['TierAfterUpdate'].toString()],
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 20),
                          ),
                          SizedBox(height: size.height * 0.008),
                          Text(
                            'Rank Point : ' + rr.toString(),
                            style: TextStyle(color: Colors.white, fontSize: 16),
                          ),
                          Text(
                            'Elo : ' +
                                ((match['TierAfterUpdate'] * 100) - 300 + rr)
                                    .toString(),
                            style: TextStyle(color: Colors.white, fontSize: 16),
                          ),
                          // Text(
                          //   'Competitive Movement : ' +
                          //       match['CompetitiveMovement'].toString(),
                          // ),
                          SizedBox(height: size.height * 0.032),
                          Text(
                            'Rating for last 3 match ',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 20),
                          ),
                          SizedBox(height: size.height * 0.032),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              PointCard(size: size, points: points[0]),
                              PointCard(size: size, points: points[1]),
                              PointCard(size: size, points: points[2]),
                            ],
                          ),
                          SizedBox(
                            height: size.height * 0.1,
                          ),
                          RaisedButton(
                              color: Colors.redAccent,
                              splashColor: Colors.greenAccent,
                              onPressed: () async {
                                _matches = getCompiDetails(_user);
                                updateToLatestGames(await _matches);
                                setState(() {});
                              },
                              child: Text('Refresh')),
                          SizedBox(height: size.height * 0.032),
                          Text(
                            'Command for discord bot is ',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 20),
                          ),
                          SizedBox(height: size.height * 0.032),
                          SelectableText(
                            '!setup $_user $_region',
                            style: TextStyle(
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    );
                  } else if (snapshot.hasError) {
                    return Text("${snapshot.error}");
                  }

                  return CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Colors.redAccent.shade200,
                    ),
                  );
                },
              ),
      ),
    );
  }

  Stack buildDropDown() {
    return Stack(
      children: [
        Transform.translate(
          offset: Offset(5, -22),
          child: Text(
            '   Region   ',
            style: TextStyle(backgroundColor: Colors.white),
          ),
        ),
        DropdownButtonHideUnderline(
          child: DropdownButton(
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Color.fromRGBO(182, 182, 182, 1),
            ),
            isExpanded: true,
            value: _region,
            items: [
              DropdownMenuItem(
                child: Text(
                  'Asia',
                  style: TextStyle(color: Colors.black),
                ),
                value: 'ap',
              ),
              DropdownMenuItem(
                child: Text(
                  'Europe',
                  style: TextStyle(color: Colors.black),
                ),
                value: 'eu',
              ),
              DropdownMenuItem(
                child: Text(
                  'Korea',
                  style: TextStyle(color: Colors.black),
                ),
                value: 'kr',
              ),
              DropdownMenuItem(
                child: Text(
                  'North America',
                  style: TextStyle(color: Colors.black),
                ),
                value: 'na',
              ),
            ],
            onChanged: (value) {
              setState(() {
                _region = value;
              });
            },
            icon: Icon(Icons.map),
          ),
        ),
      ],
    );
  }

  Center buildLoginForm(Size size) {
    return Center(
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: size.width * 0.9,
              decoration: BoxDecoration(
                color: Color.fromRGBO(237, 237, 237, 1),
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: TextFormField(
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                  validator: (String value) {
                    if (value.isEmpty) return 'Please enter your username';
                    return null;
                  },
                  controller: _controllerUsername,
                  decoration: InputDecoration(
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.only(left: 15),
                      hintText: 'USERNAME',
                      hintStyle: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color.fromRGBO(182, 182, 182, 1))),
                ),
              ),
            ),
            SizedBox(
              height: size.height * 0.025,
            ),
            Container(
              width: size.width * 0.9,
              decoration: BoxDecoration(
                color: Color.fromRGBO(237, 237, 237, 1),
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: TextFormField(
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                  validator: (String value) {
                    if (value.isEmpty) return 'Please enter your password';
                    return null;
                  },
                  textAlignVertical: TextAlignVertical.center,
                  controller: _controllerPassword,
                  obscureText: _obscureText,
                  decoration: InputDecoration(
                      suffixIcon: GestureDetector(
                        onTap: _toggleLogin,
                        child: Icon(
                          _obscureText
                              ? FontAwesomeIcons.eye
                              : FontAwesomeIcons.eyeSlash,
                          color: Colors.black,
                        ),
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.only(left: 15),
                      hintText: 'PASSWORD',
                      hintStyle: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color.fromRGBO(182, 182, 182, 1))),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
