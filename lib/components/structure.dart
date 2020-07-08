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

  _launchURL(String url) async {
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
        height: 50.0,
        items: <Widget>[
          Container(
            child: Icon(
              Icons.view_carousel,
              size: 35.0,
              color: Colors.green,
            ),
          ),
          Container(
            child: Icon(
              Icons.view_day,
              size: 35.0,
              color: Colors.deepOrange,
            ),
          ),
          Container(
            child: Icon(
              Icons.favorite,
              size: 35.0,
              color: Colors.pink,
            ),
          ),
          Container(
            child: Icon(
              Icons.face,
              size: 35.0,
              color: Colors.purple,
            ),
          ),
          Container(
            child: Icon(
              Icons.info,
              size: 35.0,
              color: Colors.blue,
            ),
          ),
        ],
        // color: Colors.grey[300],
        // color: Colors.white,
        buttonBackgroundColor: Colors.white.withOpacity(1),
        backgroundColor: _page == 0
            ? Color.fromRGBO(129, 212, 250, 1)
            : _page == 1
                ? Color.fromRGBO(197, 225, 165, 1)
                : _page == 2
                    ? Color.fromRGBO(206, 147, 216, 1)
                    : _page == 3
                        ? Color.fromRGBO(255, 204, 128, 1)
                        : Color.fromRGBO(247, 202, 201, 1),
        animationCurve: Curves.linear,
        animationDuration: Duration(milliseconds: 300),
        onTap: (index) {
          // Future.delayed(const Duration(milliseconds: 200), () {
          setState(() {
            _page = index;
          });
          // });
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
        backgroundColor: _page == 0
            ? Color.fromRGBO(129, 212, 250, 1)
            : _page == 1
                ? Color.fromRGBO(197, 225, 165, 1)
                : _page == 2
                    ? Color.fromRGBO(206, 147, 216, 1)
                    : _page == 3
                        ? Color.fromRGBO(255, 204, 128, 1)
                        : Color.fromRGBO(247, 202, 201, 1),
        actions: <Widget>[
          InkWell(
            onTap: () =>
                _launchURL("https://meyash.xyz/"), // handle your onTap here
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
            onTap: () => _launchURL(
                "https://github.com/meyash"), // handle your onTap here
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
