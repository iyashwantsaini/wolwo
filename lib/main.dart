import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import './components/structure.dart';

void main() {
  runApp(App());
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
}

class App extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        theme: ThemeData(
          scaffoldBackgroundColor: Colors.white,
          fontFamily: 'Poppins',
        ),
        home: Structure());
  }
}
