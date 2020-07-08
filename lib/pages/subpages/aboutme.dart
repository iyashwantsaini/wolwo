import 'package:flutter/material.dart';
import 'package:slimy_card/slimy_card.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutMe extends StatefulWidget {
  @override
  _AboutMeState createState() => _AboutMeState();
}

class _AboutMeState extends State<AboutMe> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        backgroundColor: Color.fromRGBO(247, 202, 201, 1),
        appBar: AppBar(
          elevation: 0.0,
          title: Text(
            '',
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 25,
            ),
          ),
          backgroundColor: Color.fromRGBO(247, 202, 201, 1),
          actions: <Widget>[
            InkWell(
              onTap: () => Navigator.pop(context), // handle your onTap here
              child: Container(
                padding: EdgeInsets.all(10.0),
                child: Icon(
                  Icons.cancel,
                  color:  Colors.white,
                  size: 30.0,
                ),
              ),
            ),
          ],
        ),
        body: Container(
            color: Color.fromRGBO(247, 202, 201, 1),
            child: StreamBuilder(
              // This streamBuilder reads the real-time status of SlimyCard.
              initialData: false,
              stream: slimyCard.stream, //Stream of SlimyCard
              builder: ((BuildContext context, AsyncSnapshot snapshot) {
                return Container(
                  child: ListView(
                    padding: EdgeInsets.zero,
                    children: <Widget>[
                      SizedBox(height: 120),

                      // SlimyCard is being called here.
                      SlimyCard(
                        color: Colors.amber[200],
                        // width: 200,
                        // topCardHeight: 400,
                        bottomCardHeight: 100,
                        borderRadius: 30,
                        slimeEnabled: true,
                        // In topCardWidget below, imagePath changes according to the
                        // status of the SlimyCard(snapshot.data).
                        topCardWidget: topCardWidget(),
                        bottomCardWidget: bottomCardWidget(),
                      ),
                    ],
                  ),
                );
              }),
            )),
      ),
    );
  }
}

// This widget will be passed as Top Card's Widget.
Widget topCardWidget() {
  return Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: <Widget>[
      Container(
        height: 120,
        width: 120,
        decoration: BoxDecoration(
          // color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          image: DecorationImage(image: AssetImage('assets/images/meyash.png')),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              spreadRadius: 1,
            ),
          ],
        ),
      ),
      SizedBox(height: 10),
      Text(
        'meyash',
        style: TextStyle(color: Colors.black, fontSize: 20),
      ),
      SizedBox(height: 10),
      RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: 'Made with ',
              style: TextStyle(
                  color: Colors.black.withOpacity(1),
                  fontSize: 15,
                  fontWeight: FontWeight.bold),
            ),
            WidgetSpan(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(0, 5, 0, 0),
                child: Icon(
                  Icons.favorite,
                  color: Colors.pink[300],
                ),
              ),
            ),
            TextSpan(
              text: '\nby Yashwant',
              style: TextStyle(
                  color: Colors.black.withOpacity(1),
                  fontSize: 15,
                  fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
      SizedBox(height: 15),
    ],
  );
}

// This widget will be passed as Bottom Card's Widget.
Widget bottomCardWidget() {
  _launchURL(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  return Container(
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        InkWell(
            onTap: () => _launchURL(
                "https://github.com/meyash"), // handle your onTap here
            child: Container(
                width: 30,
                child: Image.asset(
                  'assets/images/logo.png',
                  // color: Colors.black,
                ))),
        InkWell(
            onTap: () => _launchURL(
                "mailto:yashsn2127@gmail.com"), // handle your onTap here
            child: Container(
                width: 30,
                child: Image.asset(
                  'assets/images/mail.png',
                  // color: Colors.red,
                ))),
        InkWell(
            onTap: () =>
                _launchURL("https://meyash.xyz/"), // handle your onTap here
            child: Container(
                width: 30,
                child: Image.asset(
                  'assets/images/internet.png',
                  // color: Colors.black,
                ))),
        InkWell(
            onTap: () => _launchURL(
                "https://www.linkedin.com/in/meyash21/"), // handle your onTap here
            child: Container(
                width: 30,
                child: Image.asset(
                  'assets/images/linkedin.png',
                  // color: Colors.blueGrey,
                ))),
        InkWell(
            onTap: () => _launchURL(
                "https://api.whatsapp.com/send?phone=918397950022"), // handle your onTap here
            child: Container(
                width: 30,
                child: Image.asset(
                  'assets/images/phone.png',
                  // color: Colors.green,
                ))),
      ],
    ),
  );
}
