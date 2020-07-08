import 'package:flutter/material.dart';

class SelectedWall extends StatefulWidget {
  final String url;
  const SelectedWall({Key key, @required this.url}) : super(key: key);

  @override
  _SelectedWallState createState() => _SelectedWallState();
}

class _SelectedWallState extends State<SelectedWall> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        backgroundColor: Colors.white,
        body: Container(
          constraints: BoxConstraints.expand(),
          decoration: BoxDecoration(
              image: DecorationImage(
                  image: NetworkImage(widget.url), fit: BoxFit.cover)),
          child: Container(
            margin: EdgeInsets.fromLTRB(0, 30, 10, 0),
            alignment: Alignment.topRight,
            child: InkWell(
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
          ),
        ),
      ),
    );
  }
}
