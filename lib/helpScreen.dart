import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:webviewx/webviewx.dart';


class HelpScreen extends StatefulWidget {
  @override
  HelpScreenState createState() {
    return HelpScreenState();
  }
}

class HelpScreenState extends State<HelpScreen> {
  WebViewXController? webviewController;
  Size get screenSize => MediaQuery.of(context).size;

  @override
  void initState() {
    // TODO: implement initState

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF333A47),
      appBar: AppBar(
        backgroundColor: Color(0xFF333A47),
        title: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text('H',style: TextStyle(fontSize: 30, color: Colors.teal[200], fontWeight: FontWeight.bold),),
            Padding(padding: EdgeInsets.fromLTRB(0, 0, 0, 2),
              child: Text('elp', style: TextStyle(fontSize: 20, color: Colors.teal[200],),),)
          ],
        ),
      ),
      body:  ListView(
        children: [
          Image(image: AssetImage('assets/Attendi-intro-img/Attendi-intro-img3.001.jpeg'),),
          Divider(thickness: 5, height: 5, color: Colors.white30,),
          Image(image: AssetImage('assets/Attendi-intro-img/Attendi-intro-img3.002.jpeg'),),
          Image(image: AssetImage('assets/Attendi-intro-img/Attendi-intro-img3.003.jpeg'),),
          Divider(thickness: 5, height: 5, color: Colors.white30,),
          Image(image: AssetImage('assets/Attendi-intro-img/Attendi-intro-img3.004.jpeg'),),
          Divider(thickness: 5, height: 5, color: Colors.white30,),
          Image(image: AssetImage('assets/Attendi-intro-img/Attendi-intro-img3.005.jpeg'),),
          Image(image: AssetImage('assets/Attendi-intro-img/Attendi-intro-img3.006.jpeg'),),
        ],
      ),
    );
  }
}