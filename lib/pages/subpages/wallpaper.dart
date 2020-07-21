import 'package:flutter/material.dart';

class SelectedWall extends StatefulWidget {
  final String url;
  const SelectedWall({Key key, @required this.url}) : super(key: key);

  @override
  _SelectedWallState createState() => _SelectedWallState();
}

class _SelectedWallState extends State<SelectedWall> {
  /// Returns AppBar.
  Widget _buildSetBar() => Container(
        child: Row(
          children: <Widget>[
            Spacer(),
            Container(
              margin: EdgeInsets.fromLTRB(0, 0, 0, 15),
              alignment: Alignment.bottomRight,
              child: RawMaterialButton(
                onPressed: () {},
                // elevation: 3.0,
                fillColor: Colors.pinkAccent,
                child: Container(
                  child: Icon(
                    Icons.file_download,
                    size: 27.0,
                    color: Colors.white,
                  ),
                ),
                padding: EdgeInsets.all(15.0),
                shape: CircleBorder(),
              ),
            ),
            Container(
              margin: EdgeInsets.fromLTRB(0, 0, 0, 15),
              alignment: Alignment.bottomRight,
              child: RawMaterialButton(
                onPressed: () {},
                // elevation: 3.0,
                fillColor: Colors.pinkAccent,
                child: Container(
                  child: Icon(
                    Icons.format_paint,
                    color: Colors.white,
                    size: 27.0,
                  ),
                ),
                padding: EdgeInsets.all(15.0),
                shape: CircleBorder(),
              ),
            ),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: Colors.transparent,
        fontFamily: 'Poppins',
        // accentColor: Colors.grey[400],
        canvasColor: Colors.transparent,
      ),
      home: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: <Widget>[
            Container(
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
                      onTap: () =>
                          Navigator.pop(context), // handle your onTap here
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
                  Spacer(),
                  Container(
                    margin: EdgeInsets.fromLTRB(10, 35, 0, 0),
                    alignment: Alignment.topRight,
                    child: InkWell(
                      onTap: () =>
                          Navigator.pop(context), // handle your onTap here
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
                      onTap: () =>
                          Navigator.pop(context), // handle your onTap here
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
            DraggableScrollableSheet(
              initialChildSize: 0.25,
              minChildSize: 0.2,
              maxChildSize: 0.5,
              builder:
                  (BuildContext context, ScrollController scrollController) {
                return Container(
                  margin: EdgeInsets.fromLTRB(5, 0, 5, 0),
                  padding: EdgeInsets.fromLTRB(5, 0, 5, 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(10.0),
                        topRight: Radius.circular(10.0)),
                  ),
                  child: ListView.builder(
                    controller: scrollController,
                    itemCount: 25,
                    itemBuilder: (BuildContext context, int index) {
                      return ListTile(title: Text('Item $index'));
                    },
                  ),
                );
              },
            ),
            Container(
              child: _buildSetBar(),
            ),
          ],
        ),
        // floatingActionButton: FloatingActionButton(
        //     onPressed: () => {},
        //     child: Icon(Icons.format_paint),
        //     backgroundColor: Colors.pink[600]),
      ),
    );
  }
}
