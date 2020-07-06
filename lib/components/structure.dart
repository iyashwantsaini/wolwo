import 'package:flutter/material.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:wolwo/pages/collections.dart';

import 'package:wolwo/pages/home.dart';
import 'package:wolwo/pages/about.dart';
import 'package:wolwo/pages/favourites.dart';
import 'package:wolwo/pages/user.dart';

class Structure extends StatefulWidget {
  @override
  _StructureState createState() => _StructureState();
}

class _StructureState extends State<Structure> {
  int _page = 0;
  GlobalKey _StructureigationKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: CurvedNavigationBar(
        key: _StructureigationKey,
        // start app by this index
        index: 0,
        height: 55.0,
        items: <Widget>[
          Container(
            child: Icon(
              Icons.view_carousel,
              size: 32.0,
              color: Colors.green,
            ),
          ),
          Container(
            child: Icon(
              Icons.view_day,
              size: 32.0,
              color: Colors.deepOrange,
            ),
          ),
          Container(
            child: Icon(
              Icons.favorite,
              size: 32.0,
              color: Colors.pink,
            ),
          ),
          Container(
            child: Icon(
              Icons.face,
              size: 32.0,
              color: Colors.purple,
            ),
          ),
          Container(
            child: Icon(
              Icons.info,
              size: 32.0,
              color: Colors.blue,
            ),
          ),
        ],
        color: Colors.grey[200],
        buttonBackgroundColor: Colors.white.withOpacity(1),
        backgroundColor: Colors.grey[200].withOpacity(0),
        animationCurve: Curves.linear,
        animationDuration: Duration(milliseconds: 500),
        onTap: (index) {
          setState(() {
            _page = index;
          });
        },
      ),
      appBar: AppBar(
        elevation: 0.0,
        title: Text(
          _page == 0
              ? 'wolwo'
              : _page == 1
                  ? 'collections'
                  : _page == 2
                      ? 'favs'
                      : _page == 3 ? 'user' : _page == 4 ? 'about' : null,
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 25,
            // fontFamily: 'SF Pro Display'
          ),
        ),
        backgroundColor: Colors.white,
        actions: <Widget>[
          InkWell(
            onTap: () => print("Container pressed"), // handle your onTap here
            child: Container(
              padding: EdgeInsets.all(6.0),
              child: Icon(
                Icons.favorite,
                color: Colors.pink,
                size: 24.0,
              ),
            ),
          ),
          InkWell(
            onTap: () => print("Container pressed"), // handle your onTap here
            child: Container(
              padding: EdgeInsets.all(10.0),
              child: Icon(
                Icons.code,
                color: Colors.blue,
                size: 35.0,
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: _page == 0
          ? FloatingActionButton(
              onPressed: () {
                // Add your onPressed code here!
              },
              child: Icon(Icons.format_paint),
              backgroundColor: Colors.pink[600])
          : null,
      body: _page == 0
          ? Home()
          : _page == 1
              ? Collections()
              : _page == 2
                  ? Favourites()
                  : _page == 3 ? User() : _page == 4 ? About() : null,
    );
  }
}
