//dart 기본 패키지
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

//dart firebase
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:flutterfire_ui/auth.dart';
import 'package:email_auth/email_auth.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:work_inout/user_database.dart';
import 'package:email_validator/email_validator.dart';

import 'branch_database.dart';

class SignupPage extends StatefulWidget{
  const SignupPage({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => new _SignupPageState();
}

class _SignupPageState extends State<SignupPage>{
  late var _emailValidated = false;
  late TextEditingController _emailController = TextEditingController();
  late TextEditingController _companyCodeController = TextEditingController();
  late TextEditingController _passwordTextController = TextEditingController();
  late TextEditingController _passwordTextController2 = TextEditingController();

  late List<TextEditingController> _branchEditControls = [];
  ScrollController _scrollController = ScrollController();

  void initState(){
    _branchEditControls.add(TextEditingController());
    FirebaseAuth.instance
        .authStateChanges()
        .listen((User? user) {
      if (user == null) {
        print('User is currently signed out!');
      } else {
        print('User is signed in!');
      }
    });
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
              Text('S',style: TextStyle(fontSize: 30, color: Colors.teal[200], fontWeight: FontWeight.bold),),
              Padding(padding: EdgeInsets.fromLTRB(0, 0, 0, 2),
                child: Text('ign Up', style: TextStyle(fontSize: 20, color: Colors.teal[200],),),)
            ],
          ),
        ),
        body: Padding(
          padding: EdgeInsets.all(10),
          child: getBranchList(),
        ),
    );
  }


  Widget getBranchList(){
    return ListView.builder(itemCount: _branchEditControls.length + 3,
        shrinkWrap: true,
        controller: _scrollController,
        itemBuilder: (BuildContext context, int index){
          if(index == 0){
            return ListView(
              shrinkWrap: true,
              physics: ClampingScrollPhysics(),
              children: [
                Container(
                  padding: EdgeInsets.all(10),
                  child: TextFormField(
                    style: TextStyle(color: Colors.white70),
                    controller: _emailController,
                    decoration: InputDecoration(
                        fillColor: Colors.white10,
                        filled: true,
                        labelStyle: TextStyle(color: Colors.teal[200], ),
                        labelText: 'Email'
                    ),
                    onChanged: (value) {

                    },
                  ),
                ),
                Container(
                  padding: EdgeInsets.all(10),
                  child:  TextFormField(
                    style: TextStyle(color: Colors.white70),
                    controller: _passwordTextController,
                    decoration: InputDecoration(
                      fillColor: Colors.white10,
                      filled: true,
                      labelStyle: TextStyle(color: Colors.teal[200], ),
                      labelText: 'Password',
                    ),
                    onChanged: (value) {

                    },
                    obscureText: true,
                  ),
                ),
                Container(
                  padding: EdgeInsets.all(10),
                  child: TextFormField(
                    style: TextStyle(color: Colors.white70),
                    controller: _passwordTextController2,
                    decoration: InputDecoration(
                      fillColor: Colors.white10,
                      filled: true,
                      labelStyle: TextStyle(color: Colors.teal[200], ),
                      labelText: 'Confirm Password',
                    ),
                    onChanged: (value) {

                    },
                    obscureText: true,
                  ),
                ),
                Container(
                  padding: EdgeInsets.all(10),
                  child: TextFormField(
                    style: TextStyle(color: Colors.white70),
                    controller: _companyCodeController,
                    decoration: InputDecoration(

                      fillColor: Colors.white10,
                      filled: true,
                      labelStyle: TextStyle(color: Colors.teal[200], ),
                      labelText: 'Company Code (숫자 + 영문 6자이상)',
                    ),
                    onChanged: (value) {

                    },
                    inputFormatters: <TextInputFormatter>[
                      FilteringTextInputFormatter.allow(RegExp('[a-z A-Z 0-9]'))
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.only(left: 10),
                  alignment: Alignment.centerLeft,
                  child: Text('* 직원들에게 공유할 회사 고유 Company Code를 입력하세요. \n* 대소문자 구분 없음.  예시) samsung11', style: TextStyle(color: Colors.white70, fontSize: 12,),),
                ),
                Divider(height: 50,thickness: 1, color: Colors.white30,),
                Padding(
                    padding: EdgeInsets.only(
                        left: 10, top: 0, bottom: 15),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Icon(Icons.account_tree_outlined, color: Colors.teal[200],
                              size: 22,),
                            Text(' 사업장 리스트',
                              style: TextStyle(
                                fontSize: 17, color: Colors.teal[200],),
                              textAlign: TextAlign.center,),
                          ],
                        ),
                        TextButton(
                            onPressed: (){
                              setState(() {
                                _branchEditControls.add(TextEditingController());
                                _scrollController.animateTo(
                                  _scrollController.position.maxScrollExtent + 100,
                                  duration: const Duration(seconds: 1),
                                  curve: Curves.fastOutSlowIn,
                                );
                              });
                            },
                            child: Container(
                                padding: EdgeInsets.only(left: 10),
                                alignment: Alignment.centerLeft,
                                child: Row(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      Text('사업장 추가 ',style: TextStyle(color: Colors.white70,fontSize: 16),),
                                      Icon(Icons.add, color: Colors.white,),
                                    ]
                                )
                            )
                        )

                      ],
                    )
                ),
              ],
            );

          }
          else if(index == _branchEditControls.length + 1){
            return SizedBox(height: 20,);
          }
          else if(index == _branchEditControls.length + 2){
            return Container(
              padding: EdgeInsets.all(10),
              child: ElevatedButton(
                style: ButtonStyle(
                  backgroundColor: MaterialStatePropertyAll<Color>(Colors.blueAccent[200]!),

                ),
                child: Text('Submit'),
                onPressed: () async{
                  bool companyExist = false;
                  bool passAll = true;
                  String companyCode = _companyCodeController.text.toLowerCase();
                  try{
                    await BranchDatabase.getCompanyListCollection().get().then((QuerySnapshot querySnapshot) async{
                      querySnapshot.docs.forEach((doc) {
                        //CompanyList[doc.id]
                        if(doc.id == companyCode){
                          companyExist = true;
                        }
                      });

                      if(passAll && !EmailValidator.validate(_emailController.text)){
                        passAll = false;
                        Fluttertoast.showToast(msg: '유효하지 않은 Email입니다!', timeInSecForIosWeb: 3, backgroundColor: Colors.redAccent);
                      }

                      if(passAll && _passwordTextController.text.length < 8){
                        passAll = false;
                        Fluttertoast.showToast(msg: 'Password가 너무 짧습니다.\n8자 이상으로 변경해주세요!', timeInSecForIosWeb: 3, backgroundColor: Colors.redAccent);
                      }

                      if(passAll && _passwordTextController.text != _passwordTextController2.text){
                        passAll = false;
                        Fluttertoast.showToast(msg: 'Password가 일치하지 않습니다!', timeInSecForIosWeb: 3, backgroundColor: Colors.redAccent);
                      }

                      if(passAll && companyCode.length < 6){
                        passAll = false;
                        Fluttertoast.showToast(msg: 'Company Code는 6자 이상으로 입력해주세요!', timeInSecForIosWeb: 3, backgroundColor: Colors.redAccent);
                      }

                      if(passAll && (companyExist == true || companyCode == 'list')){
                        passAll = false;
                        Fluttertoast.showToast(msg: '이미 사용중인 Company Code 입니다!', timeInSecForIosWeb: 3, backgroundColor: Colors.redAccent);
                      }


                      if(passAll && _branchEditControls.length == 0 ){
                        passAll = false;
                        Fluttertoast.showToast(msg: '사업장을 추가해주세요!', timeInSecForIosWeb: 3, backgroundColor: Colors.redAccent);
                      }

                      if(passAll && _branchEditControls.length > 0){
                        for(var branch in _branchEditControls){
                          if(branch.text.length == 0){
                            passAll = false;
                            Fluttertoast.showToast(msg: '모든 사업장의 이름을 입력해주세요!', timeInSecForIosWeb: 3, backgroundColor: Colors.redAccent);
                            break;
                          }
                        }
                      }

                      if(passAll){
                        try {
                          UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
                              email: _emailController.text,
                              password: _passwordTextController.text
                          );

                          await UserDatabase.addAdminUserItem(companyId: companyCode, userUid: 'Administrator', key: 'password', value: _passwordTextController.text);
                          await UserDatabase.addAdminUserItem(companyId: companyCode, userUid: 'Administrator', key: 'email', value: _emailController.text);
                          await UserDatabase.addAdminUserItem(companyId: companyCode, userUid: 'Administrator', key: 'minute_interval', value: '30');
                          await BranchDatabase.addCompanyListItem(companyId: companyCode, key: 'name', value: companyCode);
                          for(var element in _branchEditControls){
                            await BranchDatabase.addItem(companyId: companyCode, branch: element.text.trim(), key: 'name', value: element.text.trim());
                          }
                          Navigator.pop(context);
                        } on FirebaseAuthException catch (e) {
                          if (e.code == 'weak-password') {
                            passAll = false;
                            print('The password provided is too weak.');
                            Fluttertoast.showToast(msg: 'The password provided is too weak!', timeInSecForIosWeb: 3, backgroundColor: Colors.redAccent);
                          } else if (e.code == 'email-already-in-use') {
                            passAll = false;
                            print('The account already exists for that email.');
                            Fluttertoast.showToast(msg: '이미 사용중인 Email 입니다!', timeInSecForIosWeb: 3, backgroundColor: Colors.redAccent);
                          }
                        } catch (e) {
                          print(e);
                        }
                      }
                    });
                  }
                  catch(e){
                    print(e);
                  }
                },
              ),
            ) ;
          }
          else{
            int brIdx = index - 1;
            brIdx = max(brIdx, 0);
            return
              Container(
                  margin: const EdgeInsets.all(10),
                  padding: const EdgeInsets.only(left: 10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.all(Radius.circular(5)),
                    border: Border.all(
                        color: Colors.white70
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child:  TextFormField(
                          decoration: InputDecoration(
                            enabledBorder: UnderlineInputBorder(
                              borderSide: BorderSide(
                                  color: Colors.transparent),
                            ),
                            focusedBorder: UnderlineInputBorder(
                              borderSide: BorderSide(
                                  color: Colors.transparent),
                            ),
                            labelText: index.toString() + ' 사업장 이름을 입력하세요.',
                            labelStyle: TextStyle(color: Colors.grey)
                          ),
                          style: TextStyle(color: Colors.white70),
                          controller: _branchEditControls[brIdx],
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close_rounded, size: 18, color: Colors.white70,),
                        onPressed: (){
                          setState(() {
                            _branchEditControls.removeAt(brIdx);
                          });
                        },
                      ),
                    ],
                  )
              );
          }
        }
    );
  }



}



class AccountPage extends StatelessWidget {
  const AccountPage({Key? key}) : super(key: key);

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