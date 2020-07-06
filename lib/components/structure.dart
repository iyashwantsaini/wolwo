import 'package:flutter/material.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';

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
        height: 50.0,
        items: <Widget>[
          Icon(Icons.home, size: 35.0, color: Colors.green),
          Icon(
            Icons.favorite,
            size: 35.0,
            color: Colors.pink,
          ),
          Icon(
            Icons.person,
            size: 35.0,
            color: Colors.purple,
          ),
          Icon(
            Icons.info,
            size: 35.0,
            color: Colors.blue,
          ),
        ],
        color: Colors.white,
        buttonBackgroundColor: Colors.white,
        // backgroundColor: Colors.black,
        animationCurve: Curves.easeInCirc,
        animationDuration: Duration(milliseconds: 300),
        onTap: (index) {
          setState(() {
            _page = index;
          });
        },
      ),
      appBar: AppBar(
        title: Text(_page == 0
            ? 'wolwo'
            : _page == 1
                ? 'favs'
                : _page == 2 ? 'about' : _page == 3 ? 'user' : null),
        // backgroundColor: Colors.black,
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
              padding: EdgeInsets.all(6.0),
              child: Icon(
                Icons.code,
                color: Colors.pink,
                size: 25.0,
              ),
            ),
          ),
          InkWell(
            onTap: () => print("Container pressed"), // handle your onTap here
            child: Container(
              padding: EdgeInsets.all(6.0),
              child: Icon(
                Icons.comment,
                color: Colors.green,
                size: 30.0,
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
              child: Icon(Icons.cached),
              backgroundColor: Colors.cyan,
            )
          : null,
      body: _page == 0
          ? Home()
          : _page == 1
              ? Favourites()
              : _page == 2 ? About() : _page == 3 ? User() : null,
    );
  }
}
