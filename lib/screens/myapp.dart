import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:valo_elo/constants/maps.dart';
import 'package:http/http.dart' as http;
import 'package:valo_elo/widgets/point_card.dart';

class MyApp extends StatefulWidget {
  MyApp({Key? key}) : super(key: key);

  @override
  _MyAppState createState() {
    return _MyAppState();
  }
}

class _MyAppState extends State<MyApp> {
  final TextEditingController _controllerPlayerName =
      TextEditingController(text: 'shroud');
  final TextEditingController _controllerTagline =
      TextEditingController(text: '7877');
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final GlobalKey<ScaffoldMessengerState> _scaffoldKey =
      GlobalKey<ScaffoldMessengerState>();
  String _region = 'na';
  int _currentTier = 0;
  int _rr = 0;
  int _elo = 0;
  List<int> _rrChange = [0, 0, 0];
  bool _isLoading = false;
  bool playerFound = false;

  @override
  void initState() {
    getRankDetails();
    super.initState();
  }

  void showInSnackBar(String value) {
    FocusScope.of(context).requestFocus(FocusNode());
    _scaffoldKey.currentState?.removeCurrentSnackBar();
    _scaffoldKey.currentState!.showSnackBar(SnackBar(
      content: Text(
        value,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Colors.white,
          fontSize: 16.0,
        ),
      ),
      backgroundColor: Colors.black.withOpacity(0.5),
      duration: Duration(seconds: 3),
    ));
  }

  Future<void> getRankDetails() async {
    final url = Uri.parse(
        'https://api.henrikdev.xyz/valorant/v1/mmr-history/$_region/${_controllerPlayerName.text}/${_controllerTagline.text}');
    print(url);
    final http.Response response = await http.get(url);
    print(response.statusCode);
    print(jsonDecode(response.body));

    if (response.statusCode == 201 || response.statusCode == 200) {
      final data = jsonDecode(response.body)['data'];
      final currentData = data[0];
      setState(() {
        playerFound = true;
        _rr = currentData['ranking_in_tier'] ?? 0;
        _currentTier = currentData['currenttier'] ?? 0;
        _elo = currentData['elo'] ?? 0;
        for (int i = 0; i < 3; i++) {
          _rrChange[i] = data[i]['mmr_change_to_last_game'] ?? 0;
        }
      });
    } else {
      setState(() {
        playerFound = false;
      });
    }
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
    _controllerPlayerName.dispose();
    _controllerTagline.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    final bool isLandscape = size.width > size.height;
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Color.fromRGBO(15, 25, 35, 1),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Color.fromRGBO(5, 15, 25, 1),
        title: Container(
          padding: const EdgeInsets.all(12.0),
          alignment: Alignment.centerRight,
          child: buildLoginForm(size),
        ),
      ),
      body: playerFound ? SingleChildScrollView(
        child: Flex(
          direction: isLandscape ? Axis.horizontal : Axis.vertical,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Container(
                  color: Color.fromRGBO(15, 25, 35, 1),
                  width: isLandscape ? size.width * 0.5 : size.width,
                  child: Column(
                    children: [
                      SizedBox(height: size.height * 0.1),
                      CircularPercentIndicator(
                        radius: 150.0,
                        lineWidth: 10.0,
                        percent: _rr > 100 ? 1.0 : _rr / 100,
                        center: Image.network(
                          'https://cloudflare-ipfs.com/ipfs/QmV5yhqTxQKQSNPEwKsBCa1qE7YhsAhvcNCbKMhjgtVZJN/$_currentTier.png',
                          width: 100,
                          height: 100,
                        ),
                        backgroundWidth: 5.0,
                        circularStrokeCap: CircularStrokeCap.round,
                        progressColor: getProgressColor(_rr),
                      ),
                      SizedBox(height: size.height * 0.02),
                      SizedBox(height: size.height * 0.008),
                      Text(
                        'Rank Point : ' + _rr.toString(),
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                      Text(
                        'Elo : ' + _elo.toString(),
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
                          PointCard(size: size, points: _rrChange[0]),
                          PointCard(size: size, points: _rrChange[1]),
                          PointCard(size: size, points: _rrChange[2]),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Column(
              children: [
                Container(
                  width: isLandscape ? size.width  * 0.5 : size.width,
                )
              ],
            ),
          ],
        ),
      ) : Center(
        child: Text('Player Not Found',style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),),
      ),
    );
  }

  Widget buildDropDown() {
    return DropdownButtonHideUnderline(
      child: DropdownButton(
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: Color.fromRGBO(15, 25, 35, 1),
        ),
        isExpanded: true,
        value: _region,
        items: [
          DropdownMenuItem(
            child: Text(
              'Asia',
              style: TextStyle(color: Colors.white),
            ),
            value: 'ap',
          ),
          DropdownMenuItem(
            child: Text(
              'Europe',
              style: TextStyle(color: Colors.white),
            ),
            value: 'eu',
          ),
          DropdownMenuItem(
            child: Text(
              'Korea',
              style: TextStyle(color: Colors.white),
            ),
            value: 'kr',
          ),
          DropdownMenuItem(
            child: Text(
              'North America',
              style: TextStyle(color: Colors.white),
            ),
            value: 'na',
          ),
        ],
        onChanged: (dynamic value) {
          setState(() {
            _region = value ?? 'na';
          });
        },
        icon: Icon(Icons.map),
      ),
    );
  }

  Container buildLoginForm(Size size) {
    return Container(
      width: size.width > size.height ? size.width * 0.7 : size.width,
      child: Form(
        key: _formKey,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Expanded(
              flex: size.width > size.height ? 2 : 1,
              child: Container(
                decoration: BoxDecoration(
                  color: Color.fromRGBO(25, 35, 45, 1),
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: TextFormField(
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                  validator: (String? value) {
                    if (value!.isEmpty) return 'Please enter your PlayerName';
                    return null;
                  },
                  controller: _controllerPlayerName,
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.only(left: 15),
                    hintText: 'Player Name',
                    hintStyle: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color.fromRGBO(182, 182, 182, 1),
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(
              width: size.shortestSide * 0.01,
            ),
            Expanded(
              flex: size.width > size.height ? 2 : 1,
              child: Container(
                decoration: BoxDecoration(
                  color: Color.fromRGBO(25, 35, 45, 1),
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: TextFormField(
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                  validator: (String? value) {
                    if (value!.isEmpty)
                      return 'Please enter your Tagline';
                    else if (value.length >= 6) return 'Invalid Tagline';
                    return null;
                  },
                  controller: _controllerTagline,
                  decoration: InputDecoration(
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.only(left: 15),
                      hintText: 'Tagline',
                      hintStyle: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color.fromRGBO(182, 182, 182, 1))),
                ),
              ),
            ),
            Expanded(
              flex: 1,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: buildDropDown(),
              ),
            ),
            SizedBox(
              width: 40,
              height: 40,
              child: RaisedButton(
                hoverColor: Colors.redAccent.shade200,
                color: Colors.black,
                child: _isLoading
                    ? Container(
                        child: CircularProgressIndicator(
                          backgroundColor: Colors.white,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.redAccent.shade200,
                          ),
                        ),
                      )
                    : Icon(
                        Icons.arrow_forward_rounded,
                        size: 20,
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
                        if (_formKey.currentState!.validate()) {
                          setState(() {
                            _isLoading = true;
                          });
                          await getRankDetails();
                          setState(() {
                            _isLoading = false;
                          });
                        }
                      },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
