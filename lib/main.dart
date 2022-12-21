import 'dart:async';
import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:webviewx/webviewx.dart';
import 'package:work_inout/helpScreen.dart';
import 'package:work_inout/signupScreen.dart';
import 'branch_database.dart';
import 'firebase_options.dart';
import 'administratorScreen.dart';
import 'myAdBanner.dart';
import 'user_database.dart';
import 'userScreen.dart';
import 'package:app_links/app_links.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io' show Platform;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  //setPathUrlStrategy();
  initializeDateFormatting('ko_KR', null);

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  if(kIsWeb){


    Map<String, Widget Function(BuildContext)> RoutingPages = {};
    RoutingPages['/'] = (context) => CompanyLoginPage();
    RoutingPages['/help'] = (context) => HelpScreen();
    //RoutingPages['/'] = (context) => accountPage();
    //html.window.open(Uri.base.toString() + 'adview.html',"Attendi");

    runApp(MaterialApp(
      scrollBehavior: MyCustomScrollBehavior(),
      debugShowCheckedModeBanner: false,
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
      onUnknownRoute: (settings) {
        String companyId = (settings.name??'').replaceFirst('/', '').toLowerCase();
        if(companyId.isNotEmpty){
          return MaterialPageRoute(
              settings: RouteSettings(name: '/'+ companyId),
              builder: (context) => UserLoginPage(companyId: companyId, title: 'Attendi'));
        }
      },
      onGenerateRoute: (settings) {
        String companyId = (settings.name??'').replaceFirst('/', '').toLowerCase();
        if(companyId.isNotEmpty){

          return MaterialPageRoute(
              settings: RouteSettings(name: '/'+ companyId),
              builder: (context) => UserLoginPage(companyId: companyId, title: 'Attendi'));
        }
      },
      routes: RoutingPages,
    ));
  }
  else{
    if(defaultTargetPlatform == TargetPlatform.iOS){
      await MobileAds.instance.initialize();
    }

    runApp(MaterialApp(
      debugShowCheckedModeBanner: false,
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
class MyCustomScrollBehavior extends MaterialScrollBehavior {
  // Override behavior methods and getters like dragDevices
  @override
  Set<PointerDeviceKind> get dragDevices => {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
    // etc.
  };
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
    print('url : ' + Uri.base.toString());

    if(!kIsWeb){
      SharedPreferences.getInstance().then((prefs) {
        String? value = prefs.getString('companycode');
        if(value != null && value.length > 0){
          value = value.toLowerCase();
          getAdminPassword(value).then((password){
            if(password.length > 0){
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      settings: RouteSettings(name: '/'+ value!),
                      builder: (context) => UserLoginPage(companyId: value!, title: 'Attendi'))
              );
            }
          });
        }
      });

      if(defaultTargetPlatform == TargetPlatform.iOS){
        MobileAds.instance.updateRequestConfiguration(RequestConfiguration(
            testDeviceIds: ['A7793781E9E54FD8A830CF098828710F']
        ));
      }
    }

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
        body: Padding(
            padding: EdgeInsets.all(10),
            child: ListView(
              children: <Widget>[
                SizedBox(height: 30,),
                Container(
                  padding: EdgeInsets.all(10),
                  child:  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('A',style: TextStyle(fontSize: 70, color: Colors.redAccent[100], fontWeight: FontWeight.bold),),
                      Padding(padding: EdgeInsets.fromLTRB(0, 0, 0, 2),
                        child: Text('ttendi', style: TextStyle(fontSize: 50, color: Colors.teal[200],),),)
                    ],
                  ),
                ),
                SizedBox(height: 10,),
                Text(
                  "     회사 전용 Company Code를 입력하세요!",
                  style: TextStyle(color: Colors.teal[200], ),
                  textAlign: TextAlign.left,
                ),
                SizedBox(height: 10,),
                Container(
                  padding: EdgeInsets.all(10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Expanded(
                        child: TextFormField(
                          style: TextStyle(color: Colors.white70, fontSize: 20),
                          controller: nameController,
                          decoration: InputDecoration(
                            fillColor: Colors.transparent,
                            filled: true,
                            labelStyle: TextStyle(color: Colors.redAccent[100],),
                            labelText: 'Company Code',
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                  color: Colors.teal[200]!),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                  color: Colors.teal[200]!),
                            ),
                            suffixIcon: IconButton(
                                alignment: Alignment.center,
                                onPressed: () async{
                                  try{
                                    String codeInput = nameController.text.toLowerCase();
                                    getAdminPassword(codeInput).then((value){
                                      if(value.length > 0){
                                        Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                                settings: RouteSettings(name: '/'+ codeInput),
                                                builder: (context) => UserLoginPage(companyId: codeInput, title: 'Attendi'))
                                        );
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
                                icon: Icon(Icons.arrow_forward, color: Colors.redAccent[100],size: 25,)
                            ),
                          ),
                        ),
                      ),

                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.only(top: 10),
                  alignment: Alignment.center,
                  child: TextButton(
                    child: Text('신규 Company Code 생성', style: TextStyle(color: Colors.blueAccent[100])),
                    onPressed: (){
                      Navigator.push(context, MaterialPageRoute(builder: (context) => SignupPage()));

                    },
                  ),
                ),
              ],
            )
        ),
        floatingActionButton: FloatingActionButton(
          child: Icon(Icons.question_mark),
          backgroundColor: Colors.teal[200],
          onPressed: (){
            Navigator.push(context, MaterialPageRoute(  settings: RouteSettings(name: '/'+ 'help'),builder: (context) => HelpScreen()));
          },
        ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
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