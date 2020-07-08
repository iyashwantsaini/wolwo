import 'package:flutter/material.dart';
import 'package:slimy_card/slimy_card.dart';

class About extends StatefulWidget {
  @override
  _AboutState createState() => _AboutState();
}

class _AboutState extends State<About> {
  @override
  Widget build(BuildContext context) {
    return Container(
        child: StreamBuilder(
      // This streamBuilder reads the real-time status of SlimyCard.
      initialData: false,
      stream: slimyCard.stream, //Stream of SlimyCard
      builder: ((BuildContext context, AsyncSnapshot snapshot) {
        return ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            SizedBox(height: 60),

            // SlimyCard is being called here.
            SlimyCard(
              // In topCardWidget below, imagePath changes according to the
              // status of the SlimyCard(snapshot.data).
              topCardWidget: topCardWidget(),
              bottomCardWidget: bottomCardWidget(),
            ),
          ],
        );
      }),
    ));
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
          color: Colors.white,
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
        style: TextStyle(color: Colors.white, fontSize: 20),
      ),
      SizedBox(height: 10),
      RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: 'Made with ',
              style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 15,
                  fontWeight: FontWeight.bold),
            ),
            WidgetSpan(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(0, 5, 0, 0),
                child: Icon(
                  Icons.favorite,
                  color: Colors.pink,
                ),
              ),
            ),
            TextSpan(
              text: '\nby Yashwant',
              style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
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
  return Container(
    child: Text(
      'It doesn\'t matter \nwhat your name is.',
      style: TextStyle(
        color: Colors.white,
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
      textAlign: TextAlign.center,
    ),
    
  );
}
