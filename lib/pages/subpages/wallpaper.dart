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
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: Colors.white,
        fontFamily: 'Poppins',
        // accentColor: Colors.grey[400],
        canvasColor: Colors.transparent,
      ),
      home: Scaffold(
        backgroundColor: Colors.white,
        body: Container(
          constraints: BoxConstraints.expand(),
          decoration: BoxDecoration(
              image: DecorationImage(
                  image: NetworkImage(widget.url), fit: BoxFit.cover)),
          child: Row(
            children: <Widget>[
              Container(
                margin: EdgeInsets.fromLTRB(10, 35, 0, 0),
                alignment: Alignment.topLeft,
                child: InkWell(
                  onTap: () => Navigator.pop(context), // handle your onTap here
                  child: Container(
                    padding: EdgeInsets.all(10.0),
                    child: Icon(
                      Icons.cancel,
                      color: Colors.white,
                      size: 30.0,
                    ),
                  ),
                ),
              ),
              Container(
                margin: EdgeInsets.fromLTRB(220, 35, 0, 0),
                alignment: Alignment.topRight,
                child: InkWell(
                  onTap: () => Navigator.pop(context), // handle your onTap here
                  child: Container(
                    padding: EdgeInsets.all(10.0),
                    child: Icon(
                      Icons.info_outline,
                      color: Colors.white,
                      size: 30.0,
                    ),
                  ),
                ),
              ),
              Container(
                margin: EdgeInsets.fromLTRB(0, 35, 0, 0),
                alignment: Alignment.topRight,
                child: InkWell(
                  onTap: () => Navigator.pop(context), // handle your onTap here
                  child: Container(
                    padding: EdgeInsets.all(10.0),
                    child: Icon(
                      Icons.open_in_browser,
                      color: Colors.white,
                      size: 30.0,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
            onPressed: () => {},
            child: Icon(Icons.format_paint),
            backgroundColor: Colors.pink[600]),
      ),
    );
  }

}
