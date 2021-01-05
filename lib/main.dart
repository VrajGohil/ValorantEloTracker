import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'package:dio/dio.dart';

class ApiProvider {
  Dio _dio;
  String aToken = '';

  final BaseOptions options = new BaseOptions(
    baseUrl: 'https://auth.riotgames.com/api/v1/authorization',
    connectTimeout: 15000,
    receiveTimeout: 13000,
  );
  static final ApiProvider _instance = ApiProvider._internal();

  factory ApiProvider() => _instance;

  ApiProvider._internal() {
    _dio = Dio(options);
    _dio.interceptors
        .add(InterceptorsWrapper(onRequest: (Options options) async {
      // to prevent other request enter this interceptor.
      _dio.interceptors.requestLock.lock();
      // We use a new Dio(to avoid dead lock) instance to request token.
      //Set the cookie to headers
      options.headers["cookie"] = aToken;

      _dio.interceptors.requestLock.unlock();
      return options; //continue
    }));
  }

  Future<void> authenticate(String username, String password) async {
    final request = {
      "type": "auth",
      "username": username,
      "password": password
    };
    final response = await _dio.put('/', data: json.encode(request));
    print("authenticate res ===" + response.data.toString());
  }

  Future<void> getAuthorization() async {
    final request = {
      "client_id": "play-valorant-web-prod",
      "nonce": "1",
      "redirect_uri": "https://beta.playvalorant.com/opt_in",
      "response_type": "token id_token",
      "scope": "account openid"
    };
    final response = await _dio.post('/', data: request);
    //get cooking from response
    final cookies = response.headers.map['set-cookie'];
    if (cookies.isNotEmpty && cookies.length == 2) {
      final authToken = cookies[1]
          .split(';')[0]; //it depends on how your server sending cookie
      //save this authToken in local storage, and pass in further api calls.
      aToken =
          authToken; //saving this to global variable to refresh current api calls to add cookie.
      print("authtoken ===" + authToken);
    }

    print("cookies ===" + cookies.toString());
    //print(response.headers.toString());

    print(response.data.toString());
  }
}

const Map<String, String> rank = {
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

class _MyAppState extends State<MyApp> {
  final TextEditingController _controllerBearer = TextEditingController();
  final TextEditingController _controllerEntitlement = TextEditingController();
  String _region = 'na';
  Future<String> _user;
  Future<List<dynamic>> _matches;

  Future<String> getUserId() async {
    final http.Response response = await http.post(
      'https://auth.riotgames.com/userinfo',
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer ${_controllerBearer.text}',
      },
      body: jsonEncode(<String, String>{}),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      return jsonDecode(response.body)['sub'];
    } else {
      throw Exception('Failed to get user id');
    }
  }

  Future<List<dynamic>> getCompiDetails(String user) async {
    final http.Response response = await http.get(
      'https://pd.$_region.a.pvp.net/mmr/v1/players/$user/competitiveupdates?startIndex=0&endIndex=20',
      headers: <String, String>{
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${_controllerBearer.text}',
        'X-Riot-Entitlements-JWT': '${_controllerEntitlement.text}',
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
                      controller: _controllerBearer,
                      decoration: InputDecoration(
                          hintText: 'Enter Bearer Authentication Token'),
                    ),
                    TextField(
                      controller: _controllerEntitlement,
                      decoration:
                          InputDecoration(hintText: 'Entitlement Token'),
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
                          _user = getUserId();
                          print("clicked");
                        });
                        _matches = getCompiDetails(await _user);
                        setState(() {});
                      },
                    ),
                  ],
                )
              : FutureBuilder<String>(
                  future: _user,
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      return Text(snapshot.data);
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
