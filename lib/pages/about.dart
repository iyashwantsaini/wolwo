import 'package:flutter/material.dart';

class About extends StatefulWidget {
  @override
  _AboutState createState() => _AboutState();
}

class _AboutState extends State<About> {
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
            child: const Text('About!'),
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
