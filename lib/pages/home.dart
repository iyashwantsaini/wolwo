import 'package:flutter/material.dart';

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey[200],
      width: double.infinity,
      child: GridView.count(
        crossAxisCount: 2,
        children: <Widget>[
          Container(
            child: Card(
                color: Colors.blue,
                child: Image.network(
                  'https://flutter.github.io/assets-for-api-docs/assets/widgets/owl-2.jpg',
                  loadingBuilder: (context, child, progress) {
                    return progress == null ? child : LinearProgressIndicator();
                  },
                )),
          ),
          Container(
            child: Card(
                color: Colors.blue,
                child: Image.network(
                  'https://flutter.github.io/assets-for-api-docs/assets/widgets/owl-2.jpg',
                  loadingBuilder: (context, child, progress) {
                    return progress == null ? child : LinearProgressIndicator();
                  },
                )),
          ),
          Container(
            child: Card(
                color: Colors.blue,
                child: Image.network(
                  'https://flutter.github.io/assets-for-api-docs/assets/widgets/owl-2.jpg',
                  loadingBuilder: (context, child, progress) {
                    return progress == null ? child : LinearProgressIndicator();
                  },
                )),
          ),
          Container(
            child: Card(
                color: Colors.blue,
                child: Image.network(
                  'https://flutter.github.io/assets-for-api-docs/assets/widgets/owl-2.jpg',
                  loadingBuilder: (context, child, progress) {
                    return progress == null ? child : LinearProgressIndicator();
                  },
                )),
          ),
          Container(
            child: Card(
                color: Colors.blue,
                child: Image.network(
                  'https://flutter.github.io/assets-for-api-docs/assets/widgets/owl-2.jpg',
                  loadingBuilder: (context, child, progress) {
                    return progress == null ? child : LinearProgressIndicator();
                  },
                )),
          ),
          Container(
            child: Card(
                color: Colors.blue,
                child: Image.network(
                  'https://flutter.github.io/assets-for-api-docs/assets/widgets/owl-2.jpg',
                  loadingBuilder: (context, child, progress) {
                    return progress == null ? child : LinearProgressIndicator();
                  },
                )),
          ),
          Container(
            child: Card(
                color: Colors.blue,
                child: Image.network(
                  'https://flutter.github.io/assets-for-api-docs/assets/widgets/owl-2.jpg',
                  loadingBuilder: (context, child, progress) {
                    return progress == null ? child : LinearProgressIndicator();
                  },
                )),
          ),
          Container(
            child: Card(
                color: Colors.blue,
                child: Image.network(
                  'https://flutter.github.io/assets-for-api-docs/assets/widgets/owl-2.jpg',
                  loadingBuilder: (context, child, progress) {
                    return progress == null ? child : LinearProgressIndicator();
                  },
                )),
          ),
          Container(
            child: Card(
                color: Colors.blue,
                child: Image.network(
                  'https://flutter.github.io/assets-for-api-docs/assets/widgets/owl-2.jpg',
                  loadingBuilder: (context, child, progress) {
                    return progress == null ? child : LinearProgressIndicator();
                  },
                )),
          ),
          Container(
            child: Card(
                color: Colors.blue,
                child: Image.network(
                  'https://flutter.github.io/assets-for-api-docs/assets/widgets/owl-2.jpg',
                  loadingBuilder: (context, child, progress) {
                    return progress == null ? child : LinearProgressIndicator();
                  },
                )),
          ),
          Container(
            child: Card(
                color: Colors.blue,
                child: Image.network(
                  'https://flutter.github.io/assets-for-api-docs/assets/widgets/owl-2.jpg',
                  loadingBuilder: (context, child, progress) {
                    return progress == null ? child : LinearProgressIndicator();
                  },
                )),
          ),
          Container(
            child: Card(
                color: Colors.blue,
                child: Image.network(
                  'https://flutter.github.io/assets-for-api-docs/assets/widgets/owl-2.jpg',
                  loadingBuilder: (context, child, progress) {
                    return progress == null ? child : LinearProgressIndicator();
                  },
                )),
          ),
          Container(
            child: Card(
                color: Colors.blue,
                child: Image.network(
                  'https://flutter.github.io/assets-for-api-docs/assets/widgets/owl-2.jpg',
                  loadingBuilder: (context, child, progress) {
                    return progress == null ? child : LinearProgressIndicator();
                  },
                )),
          ),
          Container(
            child: Card(
                color: Colors.blue,
                child: Image.network(
                  'https://flutter.github.io/assets-for-api-docs/assets/widgets/owl-2.jpg',
                  loadingBuilder: (context, child, progress) {
                    return progress == null ? child : LinearProgressIndicator();
                  },
                )),
          ),
        ],
      ),
    );
  }
}
