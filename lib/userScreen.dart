import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:loading_indicator/loading_indicator.dart';
import 'user_database.dart';
import 'branch_database.dart';
import 'administratorScreen.dart';
import 'timelineScreen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'myShare.dart';

class UserLoginPage extends StatefulWidget {
  const UserLoginPage({Key? key, required this.companyId, required this.title}) : super(key: key);
  final String title;
  final String companyId;
  @override
  State<StatefulWidget> createState() => new _UserLoginPageState();
}

class _UserLoginPageState extends State<UserLoginPage> {
  TextEditingController nameController = TextEditingController();
  String? _selectedBranch;
  final List<String> _branchList = [];

  Map<String, String> _userPasswordRef = {};
  String _userPasswordInput = "";
  String _passwordInput = "";
  String _passwordNew = "";
  String _passwordRef = "admin123";
  String valueText = "";
  String valueText2 = "";
  bool initDone = false;
  TextEditingController _textFieldController = TextEditingController();

  @override
  void initState(){
    try{
      BranchDatabase.getBranchCollection(companyId: widget.companyId).get().then((QuerySnapshot querySnapshot){
        setState(() {
          for(int i = 0; i < querySnapshot.docs.length; i++){
            _branchList.add(querySnapshot.docs[i].id);
          }
          SharedPreferences.getInstance().then((prefs) {
            final String? username = prefs.getString('username');
            final String? branch = prefs.getString('branch');
            if(username != null && username.length > 0){
              setState((){
                nameController.text = username;
              });
            }
            if(branch != null && branch.length > 0){
              if(_branchList.contains(branch)){
                setState((){
                  _selectedBranch = branch;
                });
              }

            }
          });
          initDone = true;
        });
      });
    }
    catch(e){
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    if(initDone == false){
      return const Scaffold(
        backgroundColor: Color(0xFF333A47),
        body: Center(
            child: SizedBox(
                height: 100,
                width: 100,
                child: LoadingIndicator(
                  colors: [Colors.blueAccent],
                  indicatorType: Indicator.ballRotateChase, /// Required, The loading type of the widget
                  //colors: const [Colors.blue],       /// Optional, The color collections
                  strokeWidth: 2,                     /// Optional, The stroke of the line, only applicable to widget which contains line
                )

            )
        )
      );
    }
    else{
      if(_branchList.length == 1){
        setState((){
          _selectedBranch = _branchList[0];
        });
      }

      return WillPopScope(
        // 여기에 동작을 추가해주면 된다.
        onWillPop: () async {
          SystemNavigator.pop();
          return false;
        },
        child: Scaffold(
            backgroundColor: Color(0xFF333A47),
            appBar: AppBar(
              title: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('A',style: TextStyle(fontSize: 30, color: Colors.teal[200], fontWeight: FontWeight.bold),),
                  Padding(padding: EdgeInsets.fromLTRB(0, 0, 0, 2),
                    child: Text('ttendi #${widget.companyId}', style: TextStyle(fontSize: 20, color: Colors.teal[200],),),)
                ],
              ),
              backgroundColor: Color(0xFF333A47),
              automaticallyImplyLeading: false,
              actions: [
                Container(
                  child:
                  Row(children: [
                    IconButton(
                      icon: Icon(Icons.share),
                      onPressed: () async {
                        var data = {
                          "title" : "Attendi",
                          "text" : "근무시간",
                          "url" : "https://work-inout.web.app/#/" + widget.companyId
                        };
                        await share(data);
                      },
                    ),
                    IconButton(
                      icon: Icon(Icons.exit_to_app),
                      onPressed: () async {
                        Navigator.pop(context);
                      },
                    ),
                  ],),
                ),
              ],
            ),
            body: Padding(
                padding: EdgeInsets.all(10),
                child: ListView(
                  children: <Widget>[
                    Container(
                      padding: EdgeInsets.all(10),
                      child: TextFormField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(borderSide: BorderSide(color: Colors.white70)),
                          enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white70)),
                          labelText: '이름을 입력하세요.',
                          labelStyle: TextStyle(color: Colors.white70),
                        ),
                        style: TextStyle(color : Colors.white70),
                        autofillHints: [AutofillHints.name],
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.all(15),
                      child: DropdownButton<String>(
                        value: _selectedBranch,
                        hint: Text("근무지를 선택하세요.", style: TextStyle(color : Colors.white70), ),
                        onChanged: (String? newValue) {
                          setState(() {
                            _selectedBranch = newValue??'';
                          });
                        },
                        dropdownColor: Color(0xFF333A47),
                        items: _branchList.map((String value) {
                          return DropdownMenuItem(
                            value: value,
                            child: Text(value, style: TextStyle(color : Colors.white70),),
                          );
                        }).toList(),
                      ),
                    ),
                    Container(
                        height: 50,
                        padding: EdgeInsets.fromLTRB(10, 0, 10, 0),
                        child: ElevatedButton(
                          child: Text('Login',style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),),
                          onPressed: () async {
                            if(nameController.text.isNotEmpty && _selectedBranch != null) {
                              var _userId = nameController.text.replaceAll('-', '').trim() + " - [" + _selectedBranch! + "]";

                              QuerySnapshot querySnapshot = await UserDatabase.getUserCollection(companyId: widget.companyId).get();
                              querySnapshot.docs.forEach((doc) {
                                if(doc.id == _userId){
                                  var userInfo = doc.data()! as Map<String, dynamic>;
                                  if(userInfo != null){
                                    userInfo.forEach((key, value) {
                                      if(key == 'password'){
                                        if(value != null){
                                          _userPasswordRef[doc.id] = value;
                                        }
                                      }
                                    });
                                  }
                                }
                              });


                              if(_userPasswordRef[_userId] != null && _userPasswordRef[_userId]!.length > 0){
                                showDialog<String>(
                                  context: context,
                                  builder: (BuildContext context) => AlertDialog(
                                    backgroundColor: Color(0xFF333A47),
                                    title: const Text('비밀번호를 입력하세요.', style: TextStyle(color: Colors.white)),
                                    content: Container(
                                      height: 60,
                                      child:  Column(
                                        children: [
                                          TextFormField(
                                            style: TextStyle(color: Colors.white70),
                                            obscureText: true,
                                            decoration: const InputDecoration(
                                              border: OutlineInputBorder(borderSide: BorderSide(color: Colors.white70)),
                                              enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white70)),
                                              labelText: 'Password',
                                              labelStyle: TextStyle(color: Colors.white70),
                                            ),
                                            onChanged: ((value) => {
                                              setState(() {
                                                _userPasswordInput = value;
                                              })
                                            }),
                                          ),
                                        ],
                                      ),
                                    ),
                                    actions: <Widget>[
                                      TextButton(
                                        onPressed: () => {
                                          setState((){
                                            if(_userPasswordInput == _userPasswordRef[_userId]){
                                              SharedPreferences.getInstance().then((prefs) {
                                                prefs.setString('username', nameController.text);
                                                prefs.setString('branch', _selectedBranch!);
                                              });

                                              Navigator.pop(context, 'Ok');
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(builder: (context) =>
                                                    TimeLinePage(
                                                        title: "My Working time",companyId: widget.companyId, user: nameController.text, workplace: _selectedBranch!)),
                                              );
                                            }
                                            else{
                                              Fluttertoast.showToast(msg: '비밀번호가 틀렸습니다.\n 비밀번호 분실시 관리자에게 잠금 해제 요청하세요', timeInSecForIosWeb: 5);
                                            }
                                          })
                                        },
                                        child: const Text('Ok'),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          Navigator.pop(context, 'Cancel');
                                          _userPasswordInput = "";
                                        },
                                        child: const Text('Cancel'),
                                      ),
                                    ],
                                  ),);
                              }
                              else{
                                SharedPreferences.getInstance().then((prefs) {
                                  prefs.setString('username', nameController.text);
                                  prefs.setString('branch', _selectedBranch!);
                                });
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) =>
                                      TimeLinePage(
                                          title: "My Working time",companyId: widget.companyId, user: nameController.text, workplace: _selectedBranch!)),
                                );
                              }
                            }
                          },
                        )),

                    Container(
                      margin: EdgeInsets.all(10),
                      alignment: Alignment.bottomRight,
                      child: TextButton(
                        child: Text('Administrator mode', style: TextStyle(color: Colors.teal[200]),),
                        onPressed: (){
                          _inputAdminPasswordDialog(context).then((value) {
                            if(_passwordRef.isNotEmpty){
                              if(_passwordRef == _passwordInput){
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) =>
                                      AdminPage(
                                        companyName : widget.companyId, adminPassword: _passwordRef, )),);
                              }
                              else{
                                Fluttertoast.showToast(msg: '비밀번호가 틀렸습니다.', timeInSecForIosWeb: 2);
                              }
                              _passwordInput = "";
                            }
                            else{
                              Fluttertoast.showToast(msg: '회원가입을 해주세요.');
                            }
                          });
                        },
                      ),
                    ),


                  ],
                )
            )
        ),
      );
    }

  }

  Future<void> _inputAdminPasswordDialog(BuildContext context) {
    UserDatabase.updateAdminPasswordDb(widget.companyId,_passwordRef).then((value) {
      _passwordRef = value;
    });

    return showDialog(
        context: context,
        builder: (context) {
          return _getAdminPasswordWidget();
        });
  }

  Widget _getAdminPasswordWidget() {
    return AlertDialog(
      backgroundColor: Color(0xFF333A47),
      title: Text('Input password', style: TextStyle(color: Colors.white70),),
      content: TextFormField(
        onChanged: (value) {
          setState(() {
            valueText = value;
          });
        },
        obscureText: true,
        controller: _textFieldController,
        decoration: InputDecoration(
          border: OutlineInputBorder(),
          enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white70)),
          //hintText: "Password",
          labelText: 'Password',
          labelStyle: TextStyle(color: Colors.white70),
        ),
          style: TextStyle(color : Colors.white70)
      ),
      actions: <Widget>[
        TextButton(
          child: Text('OK'),
          onPressed: () {
            setState(() {
              _passwordInput = valueText;
              Navigator.pop(context);
            });
          },
        ),
      ],
    );
  }
}
