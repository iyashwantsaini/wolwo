import 'package:flutter/material.dart';
import 'package:random_color/random_color.dart';
import '../transition/scaletrans.dart';

import './subpages/category.dart';

RandomColor _randomColor = RandomColor();

class Collections extends StatefulWidget {
  @override
  _CollectionsState createState() => _CollectionsState();
}

class _CollectionsState extends State<Collections> {
  @override
  Widget build(BuildContext context) {
    // used to set size of each image view element
    // var size = MediaQuery.of(context).size;

    return Container(
      padding: EdgeInsets.fromLTRB(2, 6, 2, 2),
      color: Colors.grey[200],
      width: double.infinity,
      child: GlowingOverscrollIndicator(
        axisDirection: AxisDirection.down,
        color: Colors.white,
        child: ListView(
          shrinkWrap: true,
          children: <Widget>[
            Container(
                // height: 196,
                width: double.infinity,
                margin: EdgeInsets.all(3.0),
                child: new Stack(
                  children: <Widget>[
                    new Positioned(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10.0),
                        child: Container(
                          width: double.infinity,
                          height: 196,
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
                                  Navigator.push(context,
                                      ScaleRoute(page: SelectedCategory()));
                                }),
                              },
                            ))),
                  ],
                )),
            Container(
                // height: 196,
                width: double.infinity,
                margin: EdgeInsets.all(3.0),
                child: new Stack(
                  children: <Widget>[
                    new Positioned(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10.0),
                        child: Container(
                          width: double.infinity,
                          height: 196,
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
                                  Navigator.push(context,
                                      ScaleRoute(page: SelectedCategory()));
                                }),
                              },
                            ))),
                  ],
                )),
            Container(
                // height: 196,
                width: double.infinity,
                margin: EdgeInsets.all(3.0),
                child: new Stack(
                  children: <Widget>[
                    new Positioned(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10.0),
                        child: Container(
                          width: double.infinity,
                          height: 196,
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
                                  Navigator.push(context,
                                      ScaleRoute(page: SelectedCategory()));
                                }),
                              },
                            ))),
                  ],
                )),
            Container(
                // height: 196,
                width: double.infinity,
                margin: EdgeInsets.all(3.0),
                child: new Stack(
                  children: <Widget>[
                    new Positioned(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10.0),
                        child: Container(
                          width: double.infinity,
                          height: 196,
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
                                  Navigator.push(context,
                                      ScaleRoute(page: SelectedCategory()));
                                }),
                              },
                            ))),
                  ],
                )),
          ],
        ),
      ),
    );
  }
}
