import 'package:flutter/material.dart';
import 'package:valo_elo/screens/myapp.dart';

void main() {
  runApp(App());
}

class App extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Valorant Elo Tracker',
      home: MyApp(),
    );
  }
}