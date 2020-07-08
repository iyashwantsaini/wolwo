import 'package:flutter/material.dart';
import 'package:random_color/random_color.dart';
import '../transition/scaletrans.dart';

import './subpages/wallpaper.dart';

RandomColor _randomColor = RandomColor();

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  @override
  Widget build(BuildContext context) {
    // used to set size of each image view element
    var size = MediaQuery.of(context).size;
    final double itemHeight = 344;
    // print(itemHeight);
    final double itemWidth = 196;
    // print(itemWidth);

    return Container(
      color: Color.fromRGBO(129, 212, 250,1),
      // color: Colors.amber,
      padding: EdgeInsets.fromLTRB(4, 8, 4, 4),
      width: double.infinity,
      child: GlowingOverscrollIndicator(
        axisDirection: AxisDirection.down,
        color: Colors.white,
        child: GridView.count(
          // physics: const AlwaysScrollableScrollPhysics (),
          crossAxisCount: 2,
          childAspectRatio: (itemWidth / itemHeight),
          controller: new ScrollController(keepScrollOffset: false),
          shrinkWrap: true,
          scrollDirection: Axis.vertical,
          children: <Widget>[
            Container(
                color: Color.fromRGBO(129, 212, 250,1),
                margin: EdgeInsets.all(3.0),
                child: new Stack(
                  children: <Widget>[
                    new Positioned(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10.0),
                        child: Container(
                          decoration: BoxDecoration(
                            color: _randomColor.randomColor(
                                colorBrightness: ColorBrightness.light),
                          ),
                          child: Image.network(
                            'https://wallpaperaccess.com/full/1559285.jpg',
                            loadingBuilder: (context, child, progress) {
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
                            color: Colors.transparent,
                            child: new InkWell(
                              splashColor: _randomColor.randomColor(
                                  colorBrightness: ColorBrightness.light),
                              onTap: () => {
                                Future.delayed(
                                    const Duration(milliseconds: 200), () {
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
                        Icons.favorite_border,
                        size: 25,
                        color: Colors.white,
                      ),
                    ),
                  ],
                )),
            Container(
                margin: EdgeInsets.all(3.0),
                child: new Stack(
                  children: <Widget>[
                    new Positioned(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10.0),
                        child: Container(
                          decoration: BoxDecoration(
                            color: _randomColor.randomColor(
                                colorBrightness: ColorBrightness.light),
                          ),
                          child: Image.network(
                            'https://wallpaperaccess.com/full/1559285.jpg',
                            loadingBuilder: (context, child, progress) {
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
                            color: Colors.transparent,
                            child: new InkWell(
                              splashColor: _randomColor.randomColor(
                                  colorBrightness: ColorBrightness.light),
                              onTap: () => {
                                Future.delayed(
                                    const Duration(milliseconds: 200), () {
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
                        Icons.favorite_border,
                        size: 25,
                        color: Colors.white,
                      ),
                    ),
                  ],
                )),
            Container(
                margin: EdgeInsets.all(3.0),
                child: new Stack(
                  children: <Widget>[
                    new Positioned(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10.0),
                        child: Container(
                          decoration: BoxDecoration(
                            color: _randomColor.randomColor(
                                colorBrightness: ColorBrightness.light),
                          ),
                          child: Image.network(
                            'https://wallpaperaccess.com/full/1559285.jpg',
                            loadingBuilder: (context, child, progress) {
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
                            color: Colors.transparent,
                            child: new InkWell(
                              splashColor: _randomColor.randomColor(
                                  colorBrightness: ColorBrightness.light),
                              onTap: () => {
                                Future.delayed(
                                    const Duration(milliseconds: 200), () {
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
                        Icons.favorite_border,
                        size: 25,
                        color: Colors.white,
                      ),
                    ),
                  ],
                )),
            Container(
                margin: EdgeInsets.all(3.0),
                child: new Stack(
                  children: <Widget>[
                    new Positioned(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10.0),
                        child: Container(
                          decoration: BoxDecoration(
                            color: _randomColor.randomColor(
                                colorBrightness: ColorBrightness.light),
                          ),
                          child: Image.network(
                            'https://wallpaperaccess.com/full/1559285.jpg',
                            loadingBuilder: (context, child, progress) {
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
                            color: Colors.transparent,
                            child: new InkWell(
                              splashColor: _randomColor.randomColor(
                                  colorBrightness: ColorBrightness.light),
                              onTap: () => {
                                Future.delayed(
                                    const Duration(milliseconds: 200), () {
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
                        Icons.favorite_border,
                        size: 25,
                        color: Colors.white,
                      ),
                    ),
                  ],
                )),
          ],
        ),
      ),
    );
  }
}
