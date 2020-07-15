import 'package:flutter/material.dart';
import 'package:random_color/random_color.dart';

import '../transition/scaletrans.dart';
import './subpages/wallpaper.dart';

RandomColor _randomColor = RandomColor();

class Favourites extends StatefulWidget {
  @override
  _FavouritesState createState() => _FavouritesState();
}

class _FavouritesState extends State<Favourites> {
  @override
  Widget build(BuildContext context) {
    // used to set size of each image view element
    // final double itemHeight = 344;
    // print(itemHeight);
    // final double itemWidth = 196;
    // print(itemWidth);
    var size = MediaQuery.of(context).size;

    return Container(
      color: Color.fromRGBO(247, 202, 201, 1),
      // color: Colors.amber,
      padding: EdgeInsets.fromLTRB(4, 8, 0, 4),
      width: size.width,
      height: size.height,
      child: GlowingOverscrollIndicator(
        axisDirection: AxisDirection.down,
        color: Colors.white,
        child: ListView(
          shrinkWrap: true,
          children: <Widget>[
            Center(
              child: Row(
                children: <Widget>[
                  Column(
                    children: <Widget>[
                      Center(
                        child: Container(
                            height: 270,
                            width: size.width / 2.1,
                            margin: EdgeInsets.all(3.0),
                            child: new Stack(
                              children: <Widget>[
                                new Positioned(
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(10.0),
                                    child: Container(
                                      width: size.width / 2.1,
                                      height: 270,
                                      decoration: BoxDecoration(
                                        color: _randomColor.randomColor(
                                            colorBrightness:
                                                ColorBrightness.light),
                                      ),
                                      child: Image.network(
                                        'https://wallpaperaccess.com/full/1559285.jpg',
                                        loadingBuilder:
                                            (context, child, progress) {
                                          return progress == null
                                              ? child
                                              : LinearProgressIndicator();
                                        },
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                ),
                                new Positioned.fill(
                                    child: new Material(
                                        borderRadius:
                                            BorderRadius.circular(10.0),
                                        color: Colors.transparent,
                                        child: new InkWell(
                                          splashColor: _randomColor.randomColor(
                                              colorBrightness:
                                                  ColorBrightness.light),
                                          onTap: () => {
                                            Future.delayed(
                                                const Duration(
                                                    milliseconds: 200), () {
                                              Navigator.push(
                                                  context,
                                                  ScaleRoute(
                                                      page: SelectedWall(
                                                          url:
                                                              'https://wallpaperaccess.com/full/1559285.jpg')));
                                            }),
                                          },
                                        ))),
                                new Positioned(
                                  right: 10.0,
                                  bottom: 10.0,
                                  child: new Icon(
                                    Icons.favorite,
                                    size: 25,
                                    color: Colors.pink,
                                  ),
                                ),
                              ],
                            )),
                      ),
                    ],
                  ),
                  Column(
                    children: <Widget>[
                      Center(
                        child: Container(
                            height: 270,
                            width: size.width / 2.1,
                            margin: EdgeInsets.all(3.0),
                            child: new Stack(
                              children: <Widget>[
                                new Positioned(
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(10.0),
                                    child: Container(
                                      width: size.width / 2.1,
                                      height: 270,
                                      decoration: BoxDecoration(
                                        color: _randomColor.randomColor(
                                            colorBrightness:
                                                ColorBrightness.light),
                                      ),
                                      child: Image.network(
                                        'https://wallpaperaccess.com/full/1559285.jpg',
                                        loadingBuilder:
                                            (context, child, progress) {
                                          return progress == null
                                              ? child
                                              : LinearProgressIndicator();
                                        },
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                ),
                                new Positioned.fill(
                                    child: new Material(
                                        borderRadius:
                                            BorderRadius.circular(10.0),
                                        color: Colors.transparent,
                                        child: new InkWell(
                                          splashColor: _randomColor.randomColor(
                                              colorBrightness:
                                                  ColorBrightness.light),
                                          onTap: () => {
                                            Future.delayed(
                                                const Duration(
                                                    milliseconds: 200), () {
                                              Navigator.push(
                                                  context,
                                                  ScaleRoute(
                                                      page: SelectedWall(
                                                          url:
                                                              'https://wallpaperaccess.com/full/1559285.jpg')));
                                            }),
                                          },
                                        ))),
                                new Positioned(
                                  right: 10.0,
                                  bottom: 10.0,
                                  child: new Icon(
                                    Icons.favorite,
                                    size: 25,
                                    color: Colors.pink,
                                  ),
                                ),
                              ],
                            )),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
