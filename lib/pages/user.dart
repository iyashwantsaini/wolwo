import 'package:flutter/material.dart';

class User extends StatefulWidget {
  @override
  _UserState createState() => _UserState();
}

class _UserState extends State<User> {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Color.fromRGBO(255, 204, 128,1),
      width: double.infinity,
      // margin: EdgeInsets.all(10),
      child: Column(
        children: <Widget>[
          Container(
            width: double.infinity,
            height: 40,
            padding: const EdgeInsets.all(8),
            child: const Text('User!'),
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
