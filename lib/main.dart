import 'package:flutter/material.dart';

import './components/structure.dart';

void main(){
  runApp(App());
}

class App extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(home: Structure());
  }
}
