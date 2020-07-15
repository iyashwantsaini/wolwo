import 'package:flutter/material.dart';
import 'package:device_info/device_info.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import '../transition/slidetransition.dart';
import '../pages/subpages/aboutme.dart';
import '../pages/subpages/licenses.dart';

class Settings extends StatefulWidget {
  @override
  _SettingsState createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  DeviceInfoPlugin deviceInfo =
      DeviceInfoPlugin(); // instantiate device info plugin
  AndroidDeviceInfo androidDeviceInfo;
  String board = '',
      brand = '',
      device = '',
      hardware = '',
      host = '',
      id = '',
      manufacture = '',
      model = '',
      product = '',
      type = '',
      androidid = '';
  bool isphysicaldevice;
  @override
  void initState() {
    super.initState();
    getDeviceinfo();
  }

  void getDeviceinfo() async {
    androidDeviceInfo = await deviceInfo
        .androidInfo; // instantiate Android Device Infoformation
    setState(() {
      board = androidDeviceInfo.board.toString();
      brand = androidDeviceInfo.brand;
      device = androidDeviceInfo.device;
      hardware = androidDeviceInfo.hardware;
      host = androidDeviceInfo.host;
      id = androidDeviceInfo.id;
      manufacture = androidDeviceInfo.manufacturer;
      model = androidDeviceInfo.model;
      product = androidDeviceInfo.product;
      type = androidDeviceInfo.type;
      isphysicaldevice = androidDeviceInfo.isPhysicalDevice;
      androidid = androidDeviceInfo.androidId;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
        color: Color.fromRGBO(255, 204, 128, 1),
        width: double.infinity,
        // margin: EdgeInsets.all(10),
        child: ListView(
          padding: const EdgeInsets.all(8),
          children: <Widget>[
            Container(
              height: 50,
              color: Colors.amber[700],
              padding: EdgeInsets.fromLTRB(20, 0, 30, 0),
              child: Row(
                children: <Widget>[
                  Text(
                    'OPTION1',
                    style: GoogleFonts.hammersmithOne(
                      textStyle: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              height: 50,
              color: Colors.amber[600],
              padding: EdgeInsets.fromLTRB(20, 0, 30, 0),
              child: Row(
                children: <Widget>[
                  Text(
                    'OPTION2',
                    style: GoogleFonts.hammersmithOne(
                      textStyle: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              // height: 150,
              color: Colors.amber[500],
              padding: EdgeInsets.fromLTRB(20, 10, 30, 10),
              child: Container(
                child: Column(
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Text(
                          'Device\n',
                          style: GoogleFonts.hammersmithOne(
                            textStyle: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: <Widget>[
                        Text(
                          'Board : ' + board,
                          style: GoogleFonts.hammersmithOne(
                            textStyle: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: <Widget>[
                        Text(
                          'Brand : ' + brand,
                          style: GoogleFonts.hammersmithOne(
                            textStyle: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: <Widget>[
                        Text(
                          'Device : ' + device,
                          style: GoogleFonts.hammersmithOne(
                            textStyle: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: <Widget>[
                        Text(
                          'Hardware : ' + hardware,
                          style: GoogleFonts.hammersmithOne(
                            textStyle: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: <Widget>[
                        Text(
                          'Host : ' + host,
                          style: GoogleFonts.hammersmithOne(
                            textStyle: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: <Widget>[
                        Text(
                          'ID : ' + id,
                          style: GoogleFonts.hammersmithOne(
                            textStyle: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: <Widget>[
                        Text(
                          'Manufature : ' + manufacture,
                          style: GoogleFonts.hammersmithOne(
                            textStyle: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: <Widget>[
                        Text(
                          'Model : ' + model,
                          style: GoogleFonts.hammersmithOne(
                            textStyle: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: <Widget>[
                        Text(
                          'Product : ' + product,
                          style: GoogleFonts.hammersmithOne(
                            textStyle: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: <Widget>[
                        Text(
                          'Type : ' + type,
                          style: GoogleFonts.hammersmithOne(
                            textStyle: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: <Widget>[
                        Text(
                          'IsPhysical : ' +
                              (isphysicaldevice == 0 ? 'No' : 'Yes'),
                          style: GoogleFonts.hammersmithOne(
                            textStyle: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: <Widget>[
                        Text(
                          'AndroidID : ' + androidid,
                          style: GoogleFonts.hammersmithOne(
                            textStyle: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Container(
              height: 50,
              color: Colors.amber[400],
              padding: EdgeInsets.fromLTRB(20, 15, 30, 0),
              child: new Stack(
                children: <Widget>[
                  Text(
                    'Developer Info',
                    style: GoogleFonts.hammersmithOne(
                      textStyle: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  new Positioned(
                    right: 10.0,
                    bottom: 13.0,
                    child: new Icon(
                      Icons.arrow_forward,
                      size: 25,
                      color: Colors.blue,
                    ),
                  ),
                  new Positioned.fill(
                      child: new Material(
                          color: Colors.transparent,
                          child: new InkWell(
                            splashColor: Colors.amber[400],
                            focusColor: Colors.amber[400],
                            hoverColor: Colors.amber[400],
                            highlightColor: Colors.amber[400],
                            onTap: () => {
                              Future.delayed(const Duration(milliseconds: 200),
                                  () {
                                Navigator.push(
                                    context, SlideLeftRoute(page: AboutMe()));
                              }),
                            },
                          ))),
                ],
              ),
            ),
            Container(
              height: 50,
              color: Colors.amber[400],
              padding: EdgeInsets.fromLTRB(20, 15, 30, 0),
              child: new Stack(
                children: <Widget>[
                  Text(
                    'Licenses',
                    style: GoogleFonts.hammersmithOne(
                      textStyle: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  new Positioned(
                    right: 10.0,
                    bottom: 13.0,
                    child: new Icon(
                      Icons.arrow_forward,
                      size: 25,
                      color: Colors.blue,
                    ),
                  ),
                  new Positioned.fill(
                      child: new Material(
                          color: Colors.transparent,
                          child: new InkWell(
                            splashColor: Colors.amber[400],
                            focusColor: Colors.amber[400],
                            hoverColor: Colors.amber[400],
                            highlightColor: Colors.amber[400],
                            onTap: () => {
                              Future.delayed(const Duration(milliseconds: 200),
                                  () {
                                Navigator.push(
                                    context, SlideLeftRoute(page: Licenses()));
                              }),
                            },
                          ))),
                ],
              ),
            ),
          ],
        ));
  }
}
