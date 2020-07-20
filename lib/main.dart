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
    // set status bar color
    // SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark.copyWith(
    //   statusBarColor: Colors.black12,
    // ));
    return MaterialApp(
      theme: ThemeData(
        scaffoldBackgroundColor: Colors.white,
        fontFamily: 'Poppins',
        // accentColor: Colors.grey[400],
        canvasColor: Colors.transparent,
      ),
      home: Structure(),
      debugShowCheckedModeBanner: false,
    );
  }
}
