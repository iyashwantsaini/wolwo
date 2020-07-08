import 'package:flutter/material.dart';

class Settings extends StatefulWidget {
  @override
  _SettingsState createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Color.fromRGBO(206, 147, 216,1),
      width: double.infinity,
      // margin: EdgeInsets.all(10),
      child: Column(
        children: <Widget>[
          Container(
            width: double.infinity,
            height: 40,
            padding: const EdgeInsets.all(8),
            child: const Text('Settings!'),
            color: Colors.teal[200],
          ),
          Container(
            width: double.infinity,
            height: 40,
            padding: const EdgeInsets.all(8),
            child: const Text('Sound of screams but the'),
            color: Colors.teal[300],
          ),
        ],
      ),
    );
  }
}
