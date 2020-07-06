import 'package:flutter/material.dart';

class About extends StatefulWidget {
  @override
  _AboutState createState() => _AboutState();
}

class _AboutState extends State<About> {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey[200],
      width: double.infinity,
      // margin: EdgeInsets.all(10),
      child: Column(
        children: <Widget>[
          Container(
            width: double.infinity,
            height: 40,
            padding: const EdgeInsets.all(8),
            child: const Text('Home!'),
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
