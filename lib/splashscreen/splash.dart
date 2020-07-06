import 'package:flutter/material.dart';

class Splash extends StatefulWidget {
  @override
  _SplashState createState() => _SplashState();
}

class _SplashState extends State<Splash> {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      width: double.infinity,
      // margin: EdgeInsets.all(10),
      child: Column(
        children: <Widget>[
          Container(
            padding: const EdgeInsets.all(8),
            child: const Text('Splash!'),
            color: Colors.teal[200],
          ),
          Container(
            padding: const EdgeInsets.all(8),
            child: const Text('Sound of screams but the'),
            color: Colors.teal[300],
          ),
        ],
      ),
    );
  }
}
