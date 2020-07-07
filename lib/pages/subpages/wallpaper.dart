import 'package:flutter/material.dart';

class SelectedWall extends StatefulWidget {
  @override
  _SelectedWallState createState() => _SelectedWallState();
}

class _SelectedWallState extends State<SelectedWall> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          elevation: 0.0,
          title: Text('',
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 25,
            ),
          ),
          backgroundColor: Colors.white,
          actions: <Widget>[
            InkWell(
              onTap: () => Navigator.pop(context), // handle your onTap here
              child: Container(
                padding: EdgeInsets.all(10.0),
                child: Icon(
                  Icons.cancel,
                  color: Colors.blue,
                  size: 30.0,
                ),
              ),
            ),
          ],
        ),
        body: Center(
          child: RaisedButton(
            child: Text('SELECTEDWALL'),
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ),
    );
  }
}