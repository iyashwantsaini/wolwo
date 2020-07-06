import 'package:flutter/material.dart';

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  @override
  Widget build(BuildContext context) {
    // used to set size of each image view element
    var size = MediaQuery.of(context).size;
    final double itemHeight = (size.height - kToolbarHeight - 24) / 2;
    final double itemWidth = size.width / 2;

    return Container(
      padding: EdgeInsets.fromLTRB(2, 6, 2, 2),
      color: Colors.grey[200],
      width: double.infinity,
      child: GridView.count(
        crossAxisCount: 2,
        childAspectRatio: (itemWidth / itemHeight),
        controller: new ScrollController(keepScrollOffset: false),
        shrinkWrap: true,
        scrollDirection: Axis.vertical,
        children: <Widget>[
          Container(
              padding: EdgeInsets.all(3.0),
              child: new Stack(
                children: <Widget>[
                  new Positioned(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10.0),
                      child: Image.network(
                        'https://wallpaperaccess.com/full/1559285.jpg',
                        loadingBuilder: (context, child, progress) {
                          return progress == null
                              ? child
                              : LinearProgressIndicator();
                        },
                      ),
                    ),
                  ),
                  new Positioned(
                    right: 10.0,
                    bottom: 10.0,
                    child: new Icon(
                      Icons.favorite_border,
                      size: 25,
                      color: Colors.white,
                    ),
                  ),
                ],
              )),
          Container(
              padding: EdgeInsets.all(3.0),
              child: new Stack(
                children: <Widget>[
                  new Positioned(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10.0),
                      child: Image.network(
                        'https://wallpaperaccess.com/full/1559285.jpg',
                        loadingBuilder: (context, child, progress) {
                          return progress == null
                              ? child
                              : LinearProgressIndicator();
                        },
                      ),
                    ),
                  ),
                  new Positioned(
                    right: 10.0,
                    bottom: 10.0,
                    child: new Icon(
                      Icons.favorite_border,
                      size: 25,
                      color: Colors.white,
                    ),
                  ),
                ],
              )),
          Container(
              padding: EdgeInsets.all(3.0),
              child: new Stack(
                children: <Widget>[
                  new Positioned(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10.0),
                      child: Image.network(
                        'https://wallpaperaccess.com/full/1559285.jpg',
                        loadingBuilder: (context, child, progress) {
                          return progress == null
                              ? child
                              : LinearProgressIndicator();
                        },
                      ),
                    ),
                  ),
                  new Positioned(
                    right: 10.0,
                    bottom: 10.0,
                    child: new Icon(
                      Icons.favorite_border,
                      size: 25,
                      color: Colors.white,
                    ),
                  ),
                ],
              )),
          Container(
              padding: EdgeInsets.all(3.0),
              child: new Stack(
                children: <Widget>[
                  new Positioned(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10.0),
                      child: Image.network(
                        'https://wallpaperaccess.com/full/1559285.jpg',
                        loadingBuilder: (context, child, progress) {
                          return progress == null
                              ? child
                              : LinearProgressIndicator();
                        },
                      ),
                    ),
                  ),
                  new Positioned(
                    right: 10.0,
                    bottom: 10.0,
                    child: new Icon(
                      Icons.favorite_border,
                      size: 25,
                      color: Colors.white,
                    ),
                  ),
                ],
              )),
        ],
      ),
    );
  }
}
