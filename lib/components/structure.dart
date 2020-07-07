import 'package:flutter/material.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:random_color/random_color.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:async';

import '../transition/slidetransition.dart';

import '../pages/subpages/colorwall.dart';

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


_launchURL( String url) async {
  if (await canLaunch(url)) {
    await launch(url);
  } else {
    throw 'Could not launch $url';
  }
}

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
        color: Colors.grey[300],
        buttonBackgroundColor: Colors.white.withOpacity(1),
        backgroundColor: Colors.grey[200],
        animationCurve: Curves.fastOutSlowIn,
        animationDuration: Duration(milliseconds: 250),
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
                      ? 'favourites'
                      : _page == 3 ? 'user' : _page == 4 ? 'about' : null,
          style: GoogleFonts.hammersmithOne(
            textStyle: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 25,
          ),
          ),
        ),
        backgroundColor: Colors.white,
        actions: <Widget>[
          InkWell(
            onTap: () => _launchURL("https://meyash.xyz/"),  // handle your onTap here
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
            onTap: () => _launchURL("https://github.com/meyash"), // handle your onTap here
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
              onPressed: () => {
                    Future.delayed(const Duration(milliseconds: 200), () {
                      Navigator.push(
                          context, SlideLeftRoute(page: ColorWall()));
                    }),
                  },
              child: Icon(Icons.color_lens),
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
