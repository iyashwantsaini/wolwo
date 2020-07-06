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
          Icon(
            Icons.home,
            size: 30.0,
            color: Colors.green,
          ),
          Icon(
            Icons.favorite,
            size: 30.0,
            color: Colors.pink,
          ),
          Icon(
            Icons.person,
            size: 30.0,
            color: Colors.purple,
          ),
          Icon(
            Icons.info,
            size: 30.0,
            color: Colors.blue,
          ),
        ],
        color: Colors.white,
        // buttonBackgroundColor: Colors.white,
        backgroundColor: Colors.grey[200],
        // animationCurve: Curves.easeInCirc,
        // animationDuration: Duration(milliseconds: 1000),
        onTap: (index) {
          setState(() {
            _page = index;
          });
        },
      ),
      appBar: AppBar(
        title: Text(
          _page == 0
              ? 'wolwo'
              : _page == 1
                  ? 'favs'
                  : _page == 2 ? 'about' : _page == 3 ? 'user' : null,
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 25,
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
              padding: EdgeInsets.all(6.0),
              child: Icon(
                Icons.code,
                color: Colors.pink,
                size: 27.0,
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
                size: 24.0,
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
              child: Icon(Icons.edit),
              backgroundColor: Colors.blueGrey,
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
