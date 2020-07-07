import 'package:flutter/material.dart';

class SelectedWall extends StatefulWidget {
  @override
  _SelectedWallState createState() => _SelectedWallState();
}

class _SelectedWallState extends State<SelectedWall> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue,
      body: Center(
        child: RaisedButton(
          child: Text('ScaleTransition'),
          onPressed: () => Navigator.pop(context),
        ),
      ),
    );
  }
}