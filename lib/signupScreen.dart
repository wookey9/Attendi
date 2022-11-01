//dart 기본 패키지
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

//dart firebase
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutterfire_ui/auth.dart';

class accountPage extends StatelessWidget {
  const accountPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
        child: StreamBuilder(
          stream: FirebaseAuth.instance.authStateChanges(),
          builder: (context, snapshot){
            if(!snapshot.hasData){
              return SignInScreen(
                providerConfigs: [
                EmailProviderConfiguration()
              ]);
            }
            return ListView(
              children: [
                TextButton(onPressed: (){
                  FirebaseAuth.instance.signOut();
                }, child: Text('로그아웃'),),
              ],
            );
          },
        )
    );
  }
}

class settingPage extends StatelessWidget {
  const settingPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container();
  }
}