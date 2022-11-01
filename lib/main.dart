import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:work_inout/signupScreen.dart';
import 'branch_database.dart';
import 'firebase_options.dart';
import 'administratorScreen.dart';
import 'user_database.dart';
import 'userScreen.dart';
import 'package:app_links/app_links.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  //setPathUrlStrategy();
  initializeDateFormatting('ko_KR', null);

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  if(kIsWeb){


    Map<String, Widget Function(BuildContext)> RoutingPages = {};
    RoutingPages['/'] = (context) => CompanyLoginPage();
    //RoutingPages['/'] = (context) => accountPage();
    //html.window.open(Uri.base.toString() + 'adview.html',"Attendi");

    runApp(MaterialApp(
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.blue,
        brightness: Brightness.light,


      ),
      darkTheme: ThemeData.dark(),
      themeMode: ThemeMode.system,
      initialRoute: '/',
      onUnknownRoute: (settings) {
        String companyId = (settings.name??'').replaceFirst('/', '');
        if(companyId.isNotEmpty){
          SharedPreferences.getInstance().then((prefs) {
            prefs.setString('companycode', companyId);
          });

          return MaterialPageRoute(
              settings: RouteSettings(name: '/'+ companyId),
              builder: (context) => UserLoginPage(companyId: companyId, title: 'Attendi'));
        }
      },
      onGenerateRoute: (settings) {
        String companyId = (settings.name??'').replaceFirst('/', '');
        if(companyId.isNotEmpty){
          SharedPreferences.getInstance().then((prefs) {
            prefs.setString('companycode', companyId);
          });

          return MaterialPageRoute(
              settings: RouteSettings(name: '/'+ companyId),
              builder: (context) => UserLoginPage(companyId: companyId, title: 'Attendi'));
        }
      },
      routes: RoutingPages,
    ));
  }
  else{
    runApp(MaterialApp(
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.blue,
        brightness: Brightness.light,
      ),


      darkTheme: ThemeData.dark(),
      themeMode: ThemeMode.system,
      home: CompanyLoginPage(),
    ));


  }

}

class CompanyLoginPage extends StatefulWidget {
  const CompanyLoginPage({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => new _CompanyLoginPageState();
}

class _CompanyLoginPageState extends State<CompanyLoginPage> {
  TextEditingController nameController = TextEditingController();
  TextEditingController pwController = TextEditingController();

  String valueText = "";
  String valueText2 = "";

  late String _companyName ='';
  late String _adminPassword = '';
  late String _adminPasswordInput = '';
  late String _adminPasswordInputCnf = '';
  FToast fToast = FToast();
  late AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSubscription;
  final _navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState(){
    fToast.init(context);
    initDeepLinks();
    SharedPreferences.getInstance().then((prefs) {
      final String? value = prefs.getString('companycode');
      if(value != null && value.length > 0){
        Navigator.push(
            context,
            MaterialPageRoute(
                settings: RouteSettings(name: '/'+ value),
                builder: (context) => UserLoginPage(companyId: value, title: 'Attendi'))
        );
      }
    });
  }

  Future<void> initDeepLinks() async {
    _appLinks = AppLinks();

    // Check initial link if app was in cold state (terminated)
    final appLink = await _appLinks.getInitialAppLink();
    if (appLink != null) {
      print('getInitialAppLink: $appLink');
      openAppLink(appLink);
    }

    // Handle link when app is in warm state (front or background)
    _linkSubscription = _appLinks.uriLinkStream.listen((uri) {
      print('onAppLink: $uri');
      openAppLink(uri);
    });
  }

  void openAppLink(Uri uri) {
    _navigatorKey.currentState?.pushNamed(uri.fragment);
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
              Text('A',style: TextStyle(fontSize: 30, color: Colors.teal[200], fontWeight: FontWeight.bold),),
              Padding(padding: EdgeInsets.fromLTRB(0, 0, 0, 2),
                child: Text('ttendi', style: TextStyle(fontSize: 20, color: Colors.teal[200],),),)
            ],
          ),
          automaticallyImplyLeading: false,
        ),
        body: Padding(
            padding: EdgeInsets.all(10),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                SizedBox(height: 20,),
                Text(
                  "사장님께서 공유한 Company Code를 등록하세요!",
                  style: TextStyle(color: Colors.teal[200], ),
                  textAlign: TextAlign.left,
                ),
                SizedBox(height: 20,),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Expanded(
                      child: TextFormField(
                        style: TextStyle(color: Colors.white70, ),
                        controller: nameController,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(borderSide: BorderSide(color: Colors.teal)),
                          enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.teal)),
                          labelText: 'Company Code',
                          labelStyle: TextStyle(color: Colors.teal[200], ),
                        ),
                      ),
                    ),
                    IconButton(
                        onPressed: () async{
                          try{
                            getAdminPassword(nameController.text).then((value){
                              if(value.length > 0){
                                SharedPreferences.getInstance().then((prefs) {
                                  prefs.setString('companycode', nameController.text);
                                  Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          settings: RouteSettings(name: '/'+ nameController.text),
                                          builder: (context) => UserLoginPage(companyId: nameController.text, title: 'Attendi'))
                                  );
                                });
                              }
                              else{
                                Fluttertoast.showToast(msg: '가입되지 않은 Company Code 입니다.', timeInSecForIosWeb: 5);
                              }
                            });
                          }
                          catch(e){
                            print(e);
                          }
                        },
                        icon: Icon(Icons.arrow_forward, color: Colors.teal[200],)
                    )
                  ],
                ),
                Container(
                  alignment: Alignment.bottomLeft,
                  child: TextButton(
                    child: Text('회원가입', style: TextStyle(color: Colors.teal[200])),
                    onPressed: (){
                      showDialog(
                          context: context,
                          builder: (context) {
                            Fluttertoast.showToast(msg: '준비중입니다..', timeInSecForIosWeb: 5);
                            return AlertDialog();
                            return AlertDialog(
                              title: const Text('회원 가입'),
                              content: SizedBox(
                                height: 150,
                                child: Column(
                                  children: [
                                    Container(
                                      margin : const EdgeInsets.all(5),
                                      height: 40,
                                      child: TextField(
                                          controller: nameController,
                                          decoration: const InputDecoration(
                                            border:  OutlineInputBorder(),
                                            labelText: 'Company Id',
                                          ),
                                          onChanged: (value) => setState(() {
                                            _companyName = value;
                                          })
                                      ),
                                    ),
                                    Container(
                                      margin : const EdgeInsets.all(5),
                                      height: 40,
                                      child: TextField(
                                          obscureText: true,
                                          decoration: const InputDecoration(
                                            border: OutlineInputBorder(),
                                            labelText: 'Password',
                                          ),
                                          onChanged: (value) => setState(() {
                                            _adminPasswordInput = value;
                                          })
                                      ),
                                    ),
                                    Container(
                                      margin : const EdgeInsets.all(5),
                                      height: 40,
                                      child: TextField(
                                          obscureText: true,
                                          decoration: const InputDecoration(
                                            border: OutlineInputBorder(),
                                            labelText: 'Password Confirm',
                                          ),
                                          onChanged: (value) => setState(() {
                                            _adminPasswordInputCnf = value;
                                          })
                                      ),
                                    ),

                                  ],
                                ),
                              ),
                              actions: <Widget>[
                                TextButton(
                                  child: Text('Sign up'),
                                  onPressed: () async {
                                    bool companyExist = false;
                                    try{
                                      await BranchDatabase.getCompanyListCollection().get().then((QuerySnapshot querySnapshot){
                                        querySnapshot.docs.forEach((doc) {
                                          //CompanyList[doc.id]
                                          if(doc.id == _companyName){
                                            companyExist = true;
                                          }
                                        });
                                        if(_adminPasswordInput.length > 0 && _adminPasswordInput.length > 0){
                                          if(_adminPasswordInput == _adminPasswordInputCnf){
                                            if(companyExist == false && _companyName != 'list'){
                                              UserDatabase.addAdminUserItem(companyId: _companyName, userUid: 'Administrator', key: 'password', value: _adminPasswordInput).then((value){
                                                BranchDatabase.addCompanyListItem(companyId: _companyName, key: 'name', value: _companyName);
                                              });
                                              Navigator.pop(context);
                                            }
                                            else{
                                              _showToast('Company Id already exists!');
                                            }
                                          }
                                          else{
                                            _showToast('Passwords do not match!');
                                          }
                                        }
                                      });
                                    }
                                    catch(e){
                                      print(e);
                                    }
                                  },
                                ),
                              ],
                            );
                          });
                    },
                  ),
                ),
              ],
            )
        )
    );
  }

  Future<String> getAdminPassword(String companyId) async{
    String passWord = '';
    try{
      await UserDatabase.getItemCollection(companyId: companyId, userUid: 'Administrator').get().then((QuerySnapshot querySnapshot) {
        querySnapshot.docs.forEach((doc) {
          if(doc.id == 'Administrator'){
            try{
              passWord = doc['password'];
            }
            catch (e){
              print(e);
            }
          }
        });
      });
    }
    catch(e){
      print(e);
    }

    return passWord;
  }

  _showToast(String text) {
    Widget toast = Container(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25.0),
        color: Colors.red,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.announcement_outlined),
          SizedBox(
            width: 12.0,
          ),
          Text(text),
        ],
      ),
    );


    fToast.showToast(
      child: toast,
      gravity: ToastGravity.TOP,
      toastDuration: const Duration(seconds: 1),
    );

    // Custom Toast Position
    /*

    fToast.showToast(
        child: toast,
        toastDuration: Duration(seconds: 2),
        positionedToastBuilder: (context, child) {
          return Positioned(
            child: child,
            top: 16.0,
            left: 16.0,
          );
        });

     */
  }
}