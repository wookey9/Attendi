import 'dart:async';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:pattern_formatter/numeric_formatter.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:work_inout/userScreen.dart';
import 'package:work_inout/user_database.dart';
import 'adminTimelineTab.dart';
import 'branch_database.dart';
import 'package:syncfusion_flutter_xlsio/xlsio.dart' as xlsio;
import 'package:loading_indicator/loading_indicator.dart';
import 'timelineScreen.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'checklist.dart';
import 'myDownload.dart';
import 'package:fl_chart/fl_chart.dart';


class AdminPage extends StatefulWidget{
  const AdminPage({required this.companyName, required this.adminPassword, required this.email });

  final String companyName;
  final String adminPassword;
  final String email;
  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> with TickerProviderStateMixin{
  late String _companyName ='';
  late String _adminPassword = '';
  late String _passwordNew = "";
  late String _passwordOld = "";
  late List<String> _branchList = [];
  late List<String> _branchListOrg = [];
  late List<Tab> _branchTabBar = [];
  late List<Widget> _branchUserTabView = [];
  late Map<String, List<workerData>> _totalWorkers = {};
  late bool _initDone = false;
  late int _selectedTabIdx = 0;
  FToast fToast = FToast();
  late List<StreamController<int>> _listStreamController = [];
  late List<TextEditingController> _listNoticeEditController = [];
  late List<TextEditingController> _listDiaryFormatEditController = [];
  late List<StreamController<int>> _listBottomStreamCon = [];

  late List<String> _listNoticeBranch = [];
  late List<String> _listDiaryFormatBranch = [];

  late Map<String, List<CheckListItem>> _listCheckListBranch = {};
  List<CheckListItem> curCheckList = [];

  List<TextEditingController> checkListCon = [];
  List<DateTime> checkListWritetime = [];

  late ScrollController _ckListScrollCon = ScrollController();

  late var _noticeToAll = false;
  late var _diaryFormatToAll = false;
  late var _checklistToAll = false;

  final double _lowestPay = 9160;
  late int _selectedBottomIndex = 0;
  late ScrollController _timelieScrollCon = ScrollController();

  var _tabController;
  var _bottomTabController;
  UserCredential? _userCredential;

  @override
  void initState(){
    _companyName = widget.companyName;
    _adminPassword = widget.adminPassword;
    fToast.init(context);

    try{
      createBranchTabs();
    }
    catch(e){
      print(e);
    }

    try {
      FirebaseAuth.instance.signInWithEmailAndPassword(
          email: widget.email,
          password: widget.adminPassword
      ).then((value) => _userCredential);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        print('No user found for that email.');
      } else if (e.code == 'wrong-password') {
        print('Wrong password provided for that user.');
      }
    }
  }

  Future<void> createBranchTabs() async{
    QuerySnapshot querySnapshot = await BranchDatabase.getBranchCollection(companyId: _companyName).get();
    for(int i = 0; i < querySnapshot.docs.length; i++) {
      String branchName = querySnapshot.docs[i].id;
      String notice = "";
      String diaryFormat = "";

      var data = querySnapshot.docs[i].data()! as Map<String, dynamic>;
      data.forEach((key, value) {
        if (key == 'notice') {
          if (value != null && value.length > 0) {
            notice = value;
          }
        }
        else if (key == 'diaryFormat') {
          if (value != null && value.length > 0) {
            diaryFormat = value;
          }
        }
      });
      _listNoticeBranch.add(notice);
      _listDiaryFormatBranch.add(diaryFormat);
      _listNoticeEditController.add(TextEditingController());
      _listDiaryFormatEditController.add(TextEditingController());
      _branchList.add(branchName);
      _branchListOrg.add(branchName);

      _listCheckListBranch[branchName] = [];



      BranchDatabase.getBranchCheckListCollection(companyId: _companyName, branch: branchName).get().then((QuerySnapshot querySnapshot2){
        for(int i = 0; i < querySnapshot2.docs.length; i++) {
          var data = querySnapshot2.docs[i].data()! as Map<String, dynamic>;
          String title = "";
          DateTime writetime = DateTime.now();
          Map<DateTime, String> checked = {};

          data.forEach((key, value) {
            if(key == 'name'){
              if(value != null && value.length > 0){
                title = value;
              }
            }
            else if(key == 'writetime'){
              if(value != null && value.length > 0){
                writetime = DateFormat('yyyy-MM-dd').parse(value);
              }
            }
            else{
              if(value != null){
                DateTime date = DateFormat('yyyy-MM-dd').parse(key);
                if(date != null && date.isBefore(DateTime.now()))
                  checked[date] = value;
              }
            }
          });

          setState((){
            _listCheckListBranch[branchName]!.add(CheckListItem(name: title, writetime: writetime, checked: checked));
          });

        }
      });

    }

    /*
    var stcon = StreamController<int>();
    _listStreamController.add(stcon);
    _branchTabBar.add(Tab( child:
    Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(Icons.home_filled, size: 18),
        Text('타임라인'),
      ],
    ),));
    _branchUserTabView.add(BranchTimelinePage(companyName: _companyName, branchList: _branchList, scrollController: _timelieScrollCon,));

     */

    _branchList.forEach((branchName) {
      var stcon = StreamController<int>();
      var bottomStCon = StreamController<int>();
      _listStreamController.add(stcon);
      _listBottomStreamCon.add(bottomStCon);
      _branchTabBar.add(Tab(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(Icons.place_outlined, size: 18,),
          Text(' ' + branchName,),
        ],
      )
        ,));
      _branchUserTabView.add(BranchPage(company: _companyName, branch: branchName, stream: stcon.stream, lowestPay: _lowestPay, bottomStream: bottomStCon.stream,));
    });
    var stcon2 = StreamController<int>();
    _listStreamController.add(stcon2);
    _branchTabBar.add(Tab(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(Icons.settings,),
            Text(' 설정', ),
          ],
        )
    ));
    _branchUserTabView.add(BranchEditPage(company: _companyName, branchList: _branchList, stream: stcon2.stream, adminPassword: widget.adminPassword, userCredential: _userCredential, email: widget.email, lowestPay: _lowestPay,));

    _tabController = TabController(
        length: _branchTabBar.length,
        vsync: this,
    );

    _tabController.addListener(_setActiveTabIndex);

    setState((){
      _initDone = true;
    });

  }
  // within your initState() method


  void _setActiveTabIndex() {
    setState((){
      _selectedTabIdx = _tabController.index;
    });

  }


  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    if(_initDone ==false){
      return const Scaffold(
        backgroundColor: Color(0xFF333A47),
        body: Center(
            child: SizedBox(
                height: 100,
                width: 100,
                child: LoadingIndicator(
                  colors: [Colors.blueAccent],
                  indicatorType: Indicator.ballRotateChase, /// Required, The loading type of the widget
                  //colors: [Colors.teal[100]],       /// Optional, The color collections
                  strokeWidth: 2,                     /// Optional, The stroke of the line, only applicable to widget which contains line
                )
            )
        ),
      );

    }
    else{
      return DefaultTabController(length: _branchTabBar.length,
          child: Scaffold(
            backgroundColor: Color(0xFF333A47),
            appBar: AppBar(
              leadingWidth: 30,
              backgroundColor: Color(0xFF333A47),
              // Here we take the value from the MyHomePage object that was created by
              // the App.build method, and use it to set our appbar title.
              title: TabBar(
                controller: _tabController,
                isScrollable: true,
                unselectedLabelColor: Colors.white24,
                unselectedLabelStyle: TextStyle(fontSize: 14),
                labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                labelColor: Colors.redAccent[100],
                indicatorColor: Colors.redAccent[100],
                tabs: _branchTabBar,
              ),
              //automaticallyImplyLeading: false,
              ),
            body : TabBarView(
              controller: _tabController,
              children: _branchUserTabView,
            ),
            floatingActionButton: _buildFloatingActionButton(),
            /*bottomNavigationBar: BottomNavigationBar(
              backgroundColor: Color(0xFF333A47),
              items: const <BottomNavigationBarItem>[
                BottomNavigationBarItem(
                  icon: Icon(Icons.people),
                  label: '직원현황',
                  backgroundColor: Color(0xFF333A47),
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.access_time_outlined),
                  label: '타임라인',
                  backgroundColor: Color(0xFF333A47),
                ),
              ],
              currentIndex: _selectedBottomIndex,
              selectedItemColor: Colors.redAccent[100],
              onTap: _onBottomItemTapped,
              unselectedItemColor: Colors.white30,
            ),

             */
            bottomNavigationBar: (_selectedTabIdx == _branchList.length) ? null : BottomAppBar(
              child: Container(
                color: Color(0xFF333A47),
                child: TabBar(
                  indicator: BoxDecoration(color: Colors.black38),
                  tabs: <Widget>[
                    Tab(
                      child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.people,color: _getBottomSelectedColor(0),),
                        Text(" 직원현황", style: TextStyle(color: _getBottomSelectedColor(0)))
                      ],
                    ),
                    ),
                    Tab(child:
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.access_time_outlined,color: _getBottomSelectedColor(1),),
                        Text(" 타임라인", style: TextStyle(color: _getBottomSelectedColor(1)))
                      ],) ),
                  ],
                  controller: _bottomTabController,
                  onTap: (index){
                    _onBottomItemTapped(index);
                  },
                ),
              ),
            ),

          )
      );
    }
  }

  Color? _getBottomSelectedColor(int index){
    return _selectedBottomIndex == index ? Colors.redAccent[100] : Colors.white30;
  }

  void _onBottomItemTapped(int index) {
    setState(() {
      _selectedBottomIndex = index;
      for(var stcon in _listBottomStreamCon){
        stcon.add(index);
      }
    });
  }

  Widget? _buildFloatingActionButton(){
    /*
    if(_selectedTabIdx == 0){
        return FloatingActionButton(
            backgroundColor: Colors.blueAccent[200],
            child: Icon(Icons.arrow_upward_rounded, color: Colors.white,),
            onPressed: (){
              _listStreamController[_selectedTabIdx].add(0);
              double offset = 0;

              if (offset > _timelieScrollCon.position.maxScrollExtent) {
                offset = _timelieScrollCon.position.maxScrollExtent;
              }
              _timelieScrollCon.animateTo(offset,
                  duration: Duration(milliseconds: 500), curve: Curves.easeInOut);
            });
    }

     */
    if(_selectedTabIdx == _branchList.length){
      return FloatingActionButton(
        backgroundColor: Colors.redAccent[100],
        child: Icon(Icons.save, color: Colors.white,),
        onPressed: (){
          _listStreamController[_selectedTabIdx].add(0);
      });
    }
    else{
     return  SpeedDial(
       overlayOpacity: 0,

       backgroundColor: Colors.teal[200],
       icon: Icons.menu,
       iconTheme: IconThemeData(color: Colors.white),
       activeIcon: Icons.close,
       spacing: 3,
       childPadding: const EdgeInsets.all(5),
       spaceBetweenChildren: 4,
       direction: SpeedDialDirection.up,
       children: [
         SpeedDialChild(
           labelShadow: [BoxShadow(color: Colors.black12), BoxShadow(color: Colors.black12)],
           foregroundColor: Colors.white,
           backgroundColor: Colors.redAccent[100],
           labelBackgroundColor: Colors.blueGrey,
           child: Icon(Icons.download, color: Colors.white),
           label: '엑셀 다운로드',
           labelStyle: TextStyle(color: Colors.white),
           onTap: () {
             _listStreamController[_selectedTabIdx].add(0);
           }
         ),
         SpeedDialChild(
           child: Icon(Icons.notification_important_outlined, color: Colors.white,),
           backgroundColor: Colors.redAccent[100],
           labelBackgroundColor: Colors.blueGrey,
           labelShadow: [BoxShadow(color: Colors.black12), BoxShadow(color: Colors.black12)],
           label : '공지사항',
           labelStyle: TextStyle(color: Colors.white),
           onTap: (){
             _listNoticeEditController[_selectedTabIdx].text = _listNoticeBranch[_selectedTabIdx];
             showDialog<String>(
               context: context,
               builder: (BuildContext context) => StatefulBuilder(builder: (BuildContext context, StateSetter setState){
                 return AlertDialog(
                   insetPadding: EdgeInsets.all(10),
                   backgroundColor: Color(0xFF333A47),
                   title: Row(
                     mainAxisAlignment: MainAxisAlignment.spaceBetween,

                     children: [
                       Text('공지사항', style: TextStyle(color: Colors.teal[200], fontSize: 17),),
                       Row(
                         children: [
                           Text('전 사업장', style: TextStyle(color: Colors.white70, fontSize: 14),),
                           Switch(value: _noticeToAll, onChanged: (value){
                             setState((){
                               _noticeToAll = value;
                             });
                           },
                           ),
                         ],
                       )
                     ],
                   ),
                   content: Container(
                     width: MediaQuery.of(context).size.width - 100,
                     child: SingleChildScrollView(
                       scrollDirection: Axis.vertical,
                       child: TextFormField(
                         controller: _listNoticeEditController[_selectedTabIdx],
                         style: TextStyle(color: Colors.white70),
                         keyboardType: TextInputType.multiline,
                         maxLines: null,
                         minLines: 5,
                         autofocus: false,
                         decoration: InputDecoration(
                           border: OutlineInputBorder(borderSide: BorderSide(color: Colors.white70)),
                           enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white70)),
                         ),
                         onChanged: (value){

                         },
                       ),
                     ),
                   ),
                   actions: <Widget>[
                     Row(
                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
                       children: [
                         TextButton(
                           onPressed: () {
                             _listNoticeEditController[_selectedTabIdx - 1].text = "";
                           },
                           child: Text('Clear', style: TextStyle(color: Colors.redAccent[100]),),
                         ),
                         Container(
                           child: Row(
                             mainAxisAlignment: MainAxisAlignment.end,
                             children: [
                               TextButton(
                                 onPressed: () {
                                   Navigator.pop(context, 'Save');
                                   if(_noticeToAll == false){
                                     _listNoticeBranch[_selectedTabIdx] = _listNoticeEditController[_selectedTabIdx].text;
                                     BranchDatabase.addItem(companyId: _companyName, branch: _branchList[_selectedTabIdx], key: 'notice', value: _listNoticeEditController[_selectedTabIdx].text);
                                     _listStreamController[_selectedTabIdx].add(1);
                                   }
                                   else{
                                     for(int i = 0; i < _branchList.length; i++){
                                       _listNoticeBranch[i] = _listNoticeEditController[_selectedTabIdx].text;
                                       BranchDatabase.addItem(companyId: _companyName, branch: _branchList[i], key: 'notice', value: _listNoticeEditController[_selectedTabIdx].text);
                                       _listStreamController[i].add(1);
                                     }
                                     _noticeToAll = false;
                                   }
                                 },
                                 child: Text('Save', style: TextStyle(color: Colors.teal[200]),),
                               ),
                               TextButton(
                                 onPressed: () => Navigator.pop(context, 'Cancel'),
                                 child: Text('Cancel', style: TextStyle(color: Colors.teal[200]),),
                               ),
                             ],
                           ),
                         )
                       ],
                     )



                   ],
                 );
               }),);}
         ),
         SpeedDialChild(
           child: Icon(Icons.checklist, color: Colors.white,),
           backgroundColor: Colors.redAccent[100],
           labelBackgroundColor: Colors.blueGrey,
           labelShadow: [BoxShadow(color: Colors.black12), BoxShadow(color: Colors.black12)],
           label: '체크리스트',
           labelStyle: TextStyle(color: Colors.white),
           onTap: (){
             String branch = _branchList[_selectedTabIdx];

             setState((){
               curCheckList = [];
               checkListCon = [];
               checkListWritetime = [];
               if(_listCheckListBranch[branch] != null){
                 _listCheckListBranch[branch]!.forEach((element) {
                   curCheckList.add(element);
                 });
                 curCheckList.forEach((element) {
                   var editCon = TextEditingController();
                   editCon.text = element.name;
                   checkListCon.add(editCon);
                 });
               }
             });

             showDialog(context: context,
                 builder: (BuildContext context) => StatefulBuilder(builder: (BuildContext context, StateSetter setState){
                    return AlertDialog(
                      title:Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('체크리스트', style: TextStyle(color: Colors.teal[200], fontSize: 17),),
                          Row(
                            children: [
                              Text('전 사업장', style: TextStyle(color: Colors.white70, fontSize: 14),),
                              Switch(value: _checklistToAll, onChanged: (value){
                                setState((){
                                  _checklistToAll = value;
                                });
                              },
                              ),
                            ],
                          )
                        ],
                      ),
                      insetPadding: EdgeInsets.all(10),
                      backgroundColor: Color(0xFF333A47),
                      content: Container(
                        height: MediaQuery.of(context).size.height - 300,
                        width: MediaQuery.of(context).size.width - 100,
                        child:   ListView.builder(itemCount: curCheckList.length + 1,
                            shrinkWrap: true,
                            controller: _ckListScrollCon,
                            itemBuilder: (BuildContext context, int index){
                              if(index == curCheckList.length){
                                return TextButton(
                                  onPressed: (){
                                    setState(() {
                                      curCheckList.add(CheckListItem(name: "", writetime: DateTime.now(), checked: {}));
                                      checkListCon.add(TextEditingController());
                                      _ckListScrollCon.animateTo(
                                        _ckListScrollCon.position.maxScrollExtent + 100,
                                        duration: const Duration(seconds: 1),
                                        curve: Curves.fastOutSlowIn,
                                      );
                                    });
                                  },
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      Text('항목 추가 ',style: TextStyle(color: Colors.white70,fontSize: 16),),
                                      Icon(Icons.add, color: Colors.white,),
                                    ]
                                  )
                                );
                              }
                              else{
                                return
                                  Container(
                                      padding: const EdgeInsets.only(left: 0, top: 5,bottom: 5),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child:  TextFormField(
                                              keyboardType: TextInputType.multiline,
                                              maxLines: null,
                                              decoration: InputDecoration(
                                                border: OutlineInputBorder(
                                                  borderRadius: BorderRadius.all(Radius.circular(5)),
                                                  borderSide: BorderSide(color: Colors.white70)
                                                ),
                                                enabledBorder: OutlineInputBorder(
                                                    borderRadius: BorderRadius.all(Radius.circular(5)),
                                                    borderSide: BorderSide(color: Colors.white70)
                                                ),
                                              ),
                                              style: TextStyle(color: Colors.white70),
                                              controller: checkListCon[index],
                                              onChanged: ((value){
                                                setState(() {
                                                  if(value.length > 0){
                                                    curCheckList[index].name = value;
                                                    curCheckList[index].writetime = DateTime.now();
                                                  }
                                                });
                                              }),
                                            ),
                                          ),
                                          IconButton(
                                            padding: EdgeInsets.zero,
                                            splashRadius: 12,
                                            icon: Icon(Icons.close_rounded, size: 18, color: Colors.white70),
                                            onPressed: (){
                                              setState(() {
                                                curCheckList.removeAt(index);
                                                checkListCon.removeAt(index);
                                              });
                                            },
                                          ),
                                        ],
                                      )
                                  );
                              }
                            }

                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => {
                            setState((){
                              if(_listCheckListBranch[branch]!=null){
                                for(int i = 0; i < curCheckList.length;){
                                  if(curCheckList[i].name.length == 0){
                                    curCheckList.removeAt(i);
                                    checkListCon.removeAt(i);
                                  }
                                  else{
                                    i++;
                                  }
                                }

                                _updateBranchChecklistDatabase(branch, false);

                                if(_checklistToAll){
                                  _branchList.forEach((br) {
                                    if(br != branch){
                                      _updateBranchChecklistDatabase(br, true);
                                    }
                                  });
                                }
                              }

                              Navigator.pop(context, 'Save');
                            })
                          },
                          child: Text('Save',style: TextStyle(color: Colors.teal[200])),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, 'Cancel'),
                          child: Text('Cancel', style: TextStyle(color: Colors.teal[200])),
                        ),
                      ],
                    );
                 }
             ));
           }
         ),
         SpeedDialChild(
           child: Icon(Icons.event_note_sharp, color: Colors.white,),
           backgroundColor: Colors.redAccent[100],
           labelBackgroundColor: Colors.blueGrey,
           labelShadow: [BoxShadow(color: Colors.black12), BoxShadow(color: Colors.black12)],
           label: '업무일지 양식',
           labelStyle: TextStyle(color: Colors.white),
           onTap: (){
             _listDiaryFormatEditController[_selectedTabIdx].text = _listDiaryFormatBranch[_selectedTabIdx];
             showDialog<String>(
               context: context,
               builder: (BuildContext context) => StatefulBuilder(builder: (BuildContext context, StateSetter setState){
                 return AlertDialog(
                   insetPadding: EdgeInsets.all(10),
                   backgroundColor: Color(0xFF333A47),
                   clipBehavior: Clip.antiAliasWithSaveLayer,
                   title: Row(
                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
                     children: [
                       Text('업무일지 양식', style: TextStyle(color: Colors.teal[200], fontSize: 17),),
                       Row(
                         children: [
                           Text('전 사업장', style: TextStyle(color: Colors.white70, fontSize: 14),),
                           Switch(value: _diaryFormatToAll, onChanged: (value){
                             setState((){
                               _diaryFormatToAll = value;
                             });
                           },
                           ),
                         ],
                       )
                     ],
                   ),

                   content: Container(
                     width: MediaQuery.of(context).size.width - 100,
                     child: SingleChildScrollView(
                       scrollDirection: Axis.vertical,
                       child: TextFormField(
                         controller: _listDiaryFormatEditController[_selectedTabIdx],
                         style: TextStyle(color: Colors.white70),
                         keyboardType: TextInputType.multiline,
                         maxLines: null,
                         minLines: 5,
                         autofocus: false,
                         decoration: InputDecoration(
                           border: OutlineInputBorder(borderSide: BorderSide(color: Colors.white70)),
                           enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white70)),
                         ),
                         onChanged: (value){

                         },
                       ),
                     ),
                   ),
                   actions: <Widget>[
                     Row(
                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
                       children: [
                         TextButton(
                           onPressed: () {
                             _listDiaryFormatEditController[_selectedTabIdx].text = "";
                           },
                           child: Text('Clear', style: TextStyle(color: Colors.redAccent[100]),),
                         ),
                         Container(
                           child: Row(
                             mainAxisAlignment: MainAxisAlignment.end,
                             children: [
                               TextButton(
                                 onPressed: () {
                                   Navigator.pop(context, 'Save');
                                   if(_diaryFormatToAll == false){
                                     _listDiaryFormatBranch[_selectedTabIdx] = _listDiaryFormatEditController[_selectedTabIdx].text;
                                     BranchDatabase.addItem(companyId: _companyName, branch: _branchList[_selectedTabIdx], key: 'diaryFormat', value: _listDiaryFormatEditController[_selectedTabIdx].text);
                                   }
                                   else{
                                     for(int i = 0; i < _branchList.length; i++){
                                       _listDiaryFormatBranch[i] = _listDiaryFormatEditController[_selectedTabIdx].text;
                                       BranchDatabase.addItem(companyId: _companyName, branch: _branchList[i], key: 'diaryFormat', value: _listDiaryFormatEditController[_selectedTabIdx].text);
                                     }
                                     _diaryFormatToAll = false;
                                   }
                                 },
                                 child: Text('Save', style: TextStyle(color: Colors.teal[200]),),
                               ),
                               TextButton(
                                 onPressed: () => Navigator.pop(context, 'Cancel'),
                                 child: Text('Cancel', style: TextStyle(color: Colors.teal[200]),),
                               ),
                             ],
                           ),
                         )
                       ],
                     )
                   ],
                 );
               }),);}
         )
       ],
     );
    }
  }
  _updateBranchChecklistDatabase(String br, bool copyToAll){
    for(int i = 0; i < (_listCheckListBranch[br]!).length; i++){
      BranchDatabase.deleteCheckListItem(companyId: _companyName, branch: br, checkId: i);
    }

    for(int i = 0; i < curCheckList.length; i++){
      BranchDatabase.addCheckItem(companyId: _companyName, branch: br, checkId: i, key: 'name', value: curCheckList[i].name);
      BranchDatabase.addCheckItem(companyId: _companyName, branch: br, checkId: i, key: 'writetime', value: DateFormat('yyyy-MM-dd').format(curCheckList[i].writetime));
      if(!copyToAll){
        curCheckList[i].checked.forEach((key, value) {
          BranchDatabase.addCheckItem(companyId: _companyName, branch: br, checkId: i, key: DateFormat('yyyy-MM-dd').format(key), value: value);
        });

      }
    }

    _listCheckListBranch[br] = curCheckList;
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

class BranchEditPage extends StatefulWidget{
  BranchEditPage({required this.company, required this.branchList, required this.stream, required this.adminPassword, required this.userCredential, required this.email, required this.lowestPay});

  final String company;
  final List<String> branchList;
  final Stream stream;
  final String adminPassword;
  final UserCredential? userCredential;
  final String? email;
  final double lowestPay;
  @override
  State<BranchEditPage> createState() => _BranchEditPageState();
}

class _BranchEditPageState extends State<BranchEditPage> with AutomaticKeepAliveClientMixin{
  late List<String> _branchList = [];
  late List<String> _branchListOrg = [];
  late List<String> _removeBranchList = [];
  late List<TextEditingController> _branchEditControls = [];
  late String _companyName;
  ScrollController _scrollController = ScrollController();
  late String _passwordNew = "";
  late String _passwordOld = "";
  late int _minuteInterval = 30;
  late int _minuteIntervalOrg = 30;
  late List<bool> _isSelectedMinInterval = [false,true,false];
  late List<int> _listMinInterval = [15,30,60];
  late bool _passwordFixFold = true;

  @override
  bool get wantKeepAlive => true;

  @override
  initState(){
    super.initState();
    _branchList = widget.branchList;

    _companyName = widget.company;
    UserDatabase.getMinuteIntervalDb(_companyName).then((value) {
      setState((){
        _minuteInterval = value;
        if(_listMinInterval.contains(_minuteInterval)){
          for(int i = 0; i < _listMinInterval.length; i++){
            var inter = _listMinInterval[i];
            if(_minuteInterval == inter){
              _isSelectedMinInterval[i] = true;
            }
            else{
              _isSelectedMinInterval[i] = false;
            }
          }
        }
        else{
          _minuteInterval = 30;
          _isSelectedMinInterval[1] = true;
        }
        _minuteIntervalOrg = _minuteInterval;
      });
    });
    _branchList.forEach((element) {
      TextEditingController newEditor = TextEditingController();
      newEditor.text = element;
      _branchEditControls.add(newEditor);
      _branchListOrg.add(element);
    });

    widget.stream.listen((event) {
      bool returnTohome = false;
      if(event is int){
        if(event == 0){
          returnTohome = _saveBranchList();
          print('interval save : $_minuteInterval');
          if(_minuteInterval > 0 && _minuteInterval <= 60){
            if(_minuteIntervalOrg != _minuteInterval){
              UserDatabase.addAdminUserItem(companyId: _companyName, userUid: 'Administrator', key: 'minute_interval', value: _minuteInterval.toString());
              Fluttertoast.showToast(msg: '근무시간 단위가 변경되었습니다.', timeInSecForIosWeb: 5);
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      settings: RouteSettings(name: '/'+ _companyName),
                      builder: (context) => UserLoginPage(companyId: _companyName, title: 'Attendi'))
              );
            }
          }
          if(_passwordOld.length > 0 && _passwordNew.length > 0){
            setState((){
              if(widget.adminPassword == _passwordOld){
                if(FirebaseAuth.instance.currentUser != null){
                  if(_passwordNew.length >= 8){
                    FirebaseAuth.instance.currentUser!.updatePassword(_passwordNew).then((value) {
                      print("Successfully changed password");

                      UserDatabase.addAdminUserItem(companyId: _companyName,userUid: 'Administrator', key: 'password', value: _passwordNew);
                      Fluttertoast.showToast(msg: '비밀번호가 변경되었습니다.', timeInSecForIosWeb: 5);
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              settings: RouteSettings(name: '/'+ _companyName),
                              builder: (context) => UserLoginPage(companyId: _companyName, title: 'Attendi'))
                      );
                      //Navigator.pop(context, 'Ok');
                    }).catchError((error){
                      Fluttertoast.showToast(msg: '비밀번호를 8자리 이상으로 설정해주세요!', timeInSecForIosWeb: 5);
                      print("Password can't be changed" + error.toString());
                      //This might happen, when the wrong password is in, the user isn't found, or if the user hasn't logged in recently.
                    });
                  }
                  else{
                    Fluttertoast.showToast(msg: '비밀번호를 8자리 이상으로 설정해주세요!', timeInSecForIosWeb: 5);
                  }

                }
                else{
                  UserDatabase.addAdminUserItem(companyId: _companyName,userUid: 'Administrator', key: 'password', value: _passwordNew);
                  Fluttertoast.showToast(msg: '비밀번호가 변경되었습니다.', timeInSecForIosWeb: 5);
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          settings: RouteSettings(name: '/'+ _companyName),
                          builder: (context) => UserLoginPage(companyId: _companyName, title: 'Attendi'))
                  );
                }
              }
              else{
                Fluttertoast.showToast(msg: '기존 비밀번호가 일치하지 않습니다!', timeInSecForIosWeb: 5);
              }
            });
          }
          else{
            if(returnTohome){
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      settings: RouteSettings(name: '/'+ _companyName),
                      builder: (context) => UserLoginPage(companyId: _companyName, title: 'Attendi'))
              );
            }
          }

        }
      }
    });
  }

  Widget build(BuildContext context){
    return branchEditTabview();
  }

  bool _saveBranchList(){
    if(!listEquals(_branchListOrg,_branchList)){
      _removeBranchList.forEach((element) {
        BranchDatabase.deleteItem(companyId: _companyName, branch: element);

        BranchDatabase.getBranchCheckListCollection(companyId: _companyName, branch: element).get().then((QuerySnapshot querySnapshot2){
          for(int i = 0; i < querySnapshot2.docs.length; i++) {
            BranchDatabase.deleteCheckListItem(companyId: _companyName, branch: element, checkId: i );
          }
        });
      });

      /*
    _branchListOrg.forEach((element) {
      BranchDatabase.deleteItem(companyId: _companyName, branch: element);
      if(_listCheckListBranch[element] != null){
        for(int i = 0; i < _listCheckListBranch[element]!.length ; i++){
          BranchDatabase.deleteCheckListItem(companyId: _companyName, branch: element, checkId: i );
        }
      }
    });

     */
      _branchList.forEach((element) {
        if(!_branchListOrg.contains(element)){
          BranchDatabase.addItem(companyId: _companyName, branch: element.trim(), key: 'name', value: element.trim());
        }
      });
      setState(() {
        _branchListOrg = _branchList;
      });
      Fluttertoast.showToast(msg: '사업장 리스트가 변경되었습니다.', timeInSecForIosWeb: 5);
      return true;
    }
    return false;
  }


  Widget branchEditTabview(){
    return GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus;
        },
        child : Column(
          children: [
            Expanded(child: getBranchList(),),
          ],
        )
    );
  }

  Widget buildDeleteAccount(){
    return Padding(
      padding: EdgeInsets.all(10),
      child:  TextButton(
          onPressed: (){
            showDialog(context: context,
                builder: (context){
                  return AlertDialog(
                    title: const Text('회원 탈퇴하시겠습니까?', style: TextStyle(color: Colors.white),),
                    backgroundColor: Color(0xFF333A47),
                    actions: [
                      ElevatedButton(
                        onPressed: () async{
                          BranchDatabase.deleteCompanyListItem(companyId: _companyName);
                          _branchList.forEach((element) {
                            BranchDatabase.getBranchCheckListCollection(companyId: _companyName, branch: element).get().then((QuerySnapshot querySnapshot2){
                              for(int i = 0; i < querySnapshot2.docs.length; i++) {
                                BranchDatabase.deleteCheckListItem(companyId: _companyName, branch: element, checkId: i );
                              }
                            });
                            BranchDatabase.deleteItem(companyId: _companyName, branch: element);
                          });

                          UserDatabase.getItemCollection(companyId: _companyName, userUid: "Administrator").snapshots().forEach((querySnapshot) {
                            for (QueryDocumentSnapshot docSnapshot in querySnapshot.docs) {
                              UserDatabase.getItemCollection(companyId: _companyName, userUid: docSnapshot.id).snapshots().forEach((querySnapshot2) {
                                for(QueryDocumentSnapshot docSnapshot2 in querySnapshot2.docs){
                                  UserDatabase.getExpenseItemCollection(companyId: _companyName, userUid: docSnapshot.id, date: docSnapshot2.id).snapshots().forEach((querySnapshot3) {
                                    for(QueryDocumentSnapshot docSnapshot3 in querySnapshot3.docs){
                                      docSnapshot3.reference.delete();
                                    }
                                  });
                                  docSnapshot2.reference.delete();
                                }
                              });
                              docSnapshot.reference.delete();
                            }
                          });

                          try {
                            await FirebaseAuth.instance.currentUser!.delete();
                          } catch (e) {
                            print('The user must reauthenticate before this operation can be executed.');
                            print(e);
                          }

                          Navigator.popUntil(context, ModalRoute.withName(Navigator.defaultRouteName));
                        },
                        child: const Text('Ok'),
                      ),
                      OutlinedButton(
                        onPressed: () {

                          Navigator.of(context).pop();
                        },
                        child: const Text('Cancel'),
                      ),
                    ],
                    content: Container(
                        padding: const EdgeInsets.all(20),
                        child: Text("탈퇴 시 회원님의 데이터는 모두 삭제되며, 복구는 불가능합니다.", style: TextStyle(color: Colors.white70),)
                    ),
                  );
                }
            );
          },
          child: Container(
            alignment: Alignment.centerLeft,
            margin: EdgeInsets.only(bottom: 30, top: 30),
            child: Text('회원 탈퇴 ',style: TextStyle(color: Colors.redAccent,fontSize: 16),),
          )
      ),
    );
  }

  Widget getBranchList(){
    return ListView.builder(itemCount: _branchList.length + 2,
        controller: _scrollController,
        itemBuilder: (BuildContext context, int index){
      if(index == 0){
        return Column(
          children: [
            SizedBox(height: 20,),
            if(widget.email != null && widget.email!.length > 0) Padding(
                padding: EdgeInsets.only(
                    left: 10, top: 0, bottom: 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.email_outlined, color: Colors.white,
                          size: 22,),
                        Text(' Email',
                          style: TextStyle(
                            fontSize: 17, color: Colors.white,),
                          textAlign: TextAlign.center,),
                      ],
                    ),
                    Padding(
                      padding: EdgeInsets.only(right: 10),
                      child: Text(widget.email??"",
                        style: TextStyle(
                          fontSize: 17, color: Colors.white54,),
                        textAlign: TextAlign.center,),
                    )
                  ],
                )
            ),
            if(widget.email != null && widget.email!.length > 0) Divider(color: Colors.white38,
                thickness: 1,
                height: 40),
            Padding(
                padding: EdgeInsets.only(
                    left: 10, top: 0, bottom: 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.attach_money, color: Colors.white,
                          size: 22,),
                        Text(' 최저시급',
                          style: TextStyle(
                            fontSize: 17, color: Colors.white,),
                          textAlign: TextAlign.center,),
                      ],
                    ),
                    Padding(
                      padding: EdgeInsets.only(right: 10),
                      child: Text(NumberFormat.currency(locale: 'ko', symbol: '₩').format(widget.lowestPay),
                        style: TextStyle(
                          fontSize: 17, color: Colors.white54,),
                        textAlign: TextAlign.center,),
                    )
                  ],
                )
            ),
            Divider(color: Colors.white38,
                thickness: 1,
                height: 40),
            Padding(
                padding: EdgeInsets.only(
                    left: 10, top: 0, bottom: 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.timelapse_outlined, color: Colors.white,
                          size: 22,),
                        Text(' 근무시간 단위',
                          style: TextStyle(
                            fontSize: 17, color: Colors.white,),
                          textAlign: TextAlign.center,),
                      ],
                    ),
                    Container(
                      padding: EdgeInsets.only(right: 10),
                      child: ToggleButtons(
                        borderColor: Colors.white70,
                        color: Colors.white,
                        selectedBorderColor: Colors.white70,
                        fillColor: Colors.teal[300],
                        selectedColor: Colors.white,
                        textStyle: TextStyle(fontSize: 15),

                        borderRadius: BorderRadius.all(Radius.circular(5)),
                        isSelected: _isSelectedMinInterval,
                        children: _listMinInterval.map((value) => Text(value.toString() + '분')).toList(),
                        onPressed: (int index){
                          if(_isSelectedMinInterval[index]){

                          }
                          else{
                            for(int i = 0; i < _isSelectedMinInterval.length; i++){
                              if(i == index){
                                setState(() {
                                  _isSelectedMinInterval[i] = true;
                                  _minuteInterval = _listMinInterval[i];
                                });
                                print('min : $_minuteInterval');
                              }
                              else{
                                setState((){
                                  _isSelectedMinInterval[i] = false;
                                });
                              }
                            }
                          }
                        },
                      ),
                    ),

                  ],
                ),
            ),
            Divider(color: Colors.white38,
                thickness: 1,
                height: 40),
            Padding(
                padding: EdgeInsets.only(
                    left: 10, top: 0,),
                child:   TextButton(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Icon(Icons.password, color: Colors.white,
                        size: 22,),
                      Text(' 비밀번호 변경 ',
                        style: TextStyle(
                          fontSize: 17, color: Colors.white,),
                        textAlign: TextAlign.center,),
                      if(_passwordFixFold) Icon(Icons.keyboard_arrow_down,color: Colors.white,
                        size: 22,),
                      if(!_passwordFixFold) Icon(Icons.keyboard_arrow_up,color: Colors.white,
                        size: 22,)
                    ],
                  ),
                  onPressed: (){
                    setState(() {
                      _passwordFixFold = !_passwordFixFold;
                    });

                  },
                ),
            ),
            AnimatedContainer(
              height: _passwordFixFold?0:180,
              duration: Duration(milliseconds: 300),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: EdgeInsets.all(10),
                    child: TextFormField(
                      style: TextStyle(color: Colors.white70),
                      obscureText: true,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(borderSide: BorderSide(color: Colors.white70)),
                        enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white70)),
                        labelText: 'Old Password',
                        labelStyle: TextStyle(color: Colors.white70),
                      ),
                      onChanged: ((value) => {
                        setState((){
                          _passwordOld = value;
                        })
                      }),
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.all(10),
                    child:
                    TextFormField(
                      style: TextStyle(color: Colors.white70),
                      obscureText: true,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(borderSide: BorderSide(color: Colors.white70)),
                        enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white70)),
                        labelText: 'New Password',
                        labelStyle: TextStyle(color: Colors.white70),
                      ),
                      onChanged: ((value) => {
                        setState(() {
                          _passwordNew = value;
                        })
                      }),
                    ),
                  ),

                ],
              ),
            ),
            Divider(color: Colors.white38,
                thickness: 1,
                height: 40),
            Padding(
                padding: EdgeInsets.only(
                    left: 10, top: 0, bottom: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Icon(Icons.account_tree_outlined, color: Colors.white,
                          size: 22,),
                        Text(' 사업장 리스트',
                          style: TextStyle(
                            fontSize: 17, color: Colors.white,),
                          textAlign: TextAlign.center,),
                      ],
                    ),
                    TextButton(
                        onPressed: (){
                          setState(() {
                            _branchList.add('');
                            _branchEditControls.add(TextEditingController());
                            _scrollController.animateTo(
                              _scrollController.position.maxScrollExtent + 100,
                              duration: const Duration(seconds: 1),
                              curve: Curves.fastOutSlowIn,
                            );
                          });
                        },
                        child: Container(
                            child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
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
      else if(index == _branchList.length + 1){
        return buildDeleteAccount();
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
                        ),
                        style: TextStyle(color: Colors.white70),
                        controller: _branchEditControls[brIdx],
                        onChanged: ((value){
                          setState(() {
                            if(_branchListOrg.contains(_branchList[brIdx])){
                              _removeBranchList.add(_branchList[brIdx]);
                            }
                            _branchList[brIdx] = value;
                          });
                        }),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close_rounded, size: 18, color: Colors.white70,),
                      onPressed: (){
                        setState(() {
                          _removeBranchList.add(_branchList[brIdx]);
                          _branchList.removeAt(brIdx);
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


class BranchPage extends StatefulWidget{
  BranchPage({required this.company, required this.branch, required this.stream, required this.lowestPay, required this.bottomStream });
  final String company;
  final String branch;
  final Stream<int> stream;
  final double lowestPay;
  final Stream<int> bottomStream;

  exportData(BuildContext context) {
    _BranchPageState? state = context.findAncestorStateOfType<_BranchPageState>();
    state!.exportData();
  }

  @override
  State<BranchPage> createState() => _BranchPageState();
}


class _BranchPageState extends State<BranchPage> with AutomaticKeepAliveClientMixin{
  late String _companyName;
  late String _payPerHourInput = '';
  late List<workerData> workerList = [];
  late bool _initDone = false;
  late List<ExpenseInfo> listExpenseInfo = [];
  late int _bottomTabIndex = 0;

  TextEditingController _payEditingController = TextEditingController();
  String get _currency => NumberFormat.currency(locale: 'ko', symbol: '₩').currencySymbol;

  late bool initDone = false;
  late int initDone2ndCnt = 0;
  late int initUserCnt = 0;
  late int userCnt = 0;
  late ScrollController _scrollController = ScrollController();
  late Map<DateTime, DiaryContent> _listDiaryContent = {};
  late DateTime _currentDate = DateTime.now().subtract(Duration(days: 30));

  late Map<DateTime, GlobalKey> globalKeys = {};
  late var sortedKeys;
  late List<DateTime> days = [];
  late List<String> userIdList = [];
  late Map<String, bool> filterBranch = {};
  late Map<String, bool> filterType = {};
  late bool filterTypeAll = true;

  late Map<String, bool> filterTypeView = {};
  late bool filterTypeAllView = true;
  late Map<DateTime, int> nothingToShow = {};
  late Map<int, DateTime> scrollToDate = {};
  late double prevScrollOffset = 0;
  late double prevScrollMax = 0;

  final ItemScrollController itemScrollController = ItemScrollController();
  final ItemPositionsListener itemPositionsListener = ItemPositionsListener.create();
  final List<String> diaryType = ['근무현황','지출현황','체크리스트','업무일지'];

  @override
  bool get wantKeepAlive => true;

  @override
  initState() {
    super.initState();
    _companyName = widget.company;

    for (int i = 0; i < 10; i++) {
      days.add(DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day).subtract(Duration(days: i)));
    }

    diaryType.forEach((element) {
      filterTypeView[element] = true;
    });
    //workerList.clear();
    getWorkerList(widget.branch);
    /*
    getWorkerList(widget.branch).then((list) {
      for (int i = 0; i < list.length; i++) {
        if (list[i].totalDuration[0] + list[i].totalDuration[1] > 0) {
          setState((){
            workerList.add(list[i]);
          });
        }
      }
      _initDone = true;

    });

     */

    widget.stream.listen((event) {
      if(event is int){
        int a = event;
        if(event == 0){
          exportData();
        }
        else if(event == 1){
          workerList.forEach((element) {
            UserDatabase.addUserItem(companyId: _companyName,userUid: element.getUserId(), key: 'noticeShow', value: 'true');
          });
        }
      }
    });

    widget.bottomStream.listen((index){
      if(index < 3){
        setState((){
          _bottomTabIndex = index;
        });
      }
    });


    _scrollController.addListener(() {
      double scrollOffset = _scrollController.offset;
      if(scrollOffset < 0){
        scrollOffset = 0;
      }
      if(scrollToDate[scrollOffset ~/ 10] != _currentDate && scrollToDate[scrollOffset ~/ 10] != null){
        setState((){
          //print(_scrollController.offset ~/ 10);
          _currentDate = scrollToDate[scrollOffset ~/ 10]!;
          prevScrollOffset = scrollOffset;
        });
      }

      if(_scrollController.position.pixels == _scrollController.position.maxScrollExtent && days.length < 100){
        DateTime lastdate = days[days.length - 1];
        for (int i = 1; i <= 10; i++) {
          setState((){
            DateTime addDate = lastdate.subtract(Duration(days: i));
            days.add(addDate);
            //getDiaryInfo(addDate);
          });
        }
      }
    });


    itemPositionsListener.itemPositions.addListener(() {
      var positions = itemPositionsListener.itemPositions.value;
      var maxScroll = _scrollController.position.maxScrollExtent;
      if (initDone && positions.isNotEmpty) {
        if(prevScrollMax != maxScroll){
          setState(() {
            prevScrollMax = maxScroll;
            int curIdx = 0;
            double height = 0;
            scrollToDate.clear();
            for(double h = 0; h < maxScroll; h += 10){
              if(curIdx < days.length){
                if(days[curIdx] != null){
                  var date = days[curIdx];
                  //print('date ' + date.toString());
                  if(globalKeys[date] != null && globalKeys[date]!.currentContext != null) {
                    RenderBox? box = globalKeys[date]!.currentContext!
                        .findRenderObject() as RenderBox;
                    if (box != null) {
                      if(height == 0){
                        height = box.size.height;
                        //print(height);
                      }

                      if(h < height - 50){
                        scrollToDate[h ~/ 10] = days[curIdx];
                        //print(h.toString() + ' / ' + days[curIdx].toString());
                      }
                      else{
                        curIdx++;
                        if(curIdx < days.length){
                          var nextDate = days[curIdx];
                          if(globalKeys[nextDate] != null && globalKeys[nextDate]!.currentContext != null) {
                            RenderBox? nextbox = globalKeys[nextDate]!.currentContext!
                                .findRenderObject() as RenderBox;
                            if(nextbox != null){
                              height += nextbox.size.height + 1;
                            }
                          }
                        }
                      }
                    }
                    else{
                      curIdx++;
                    }
                  }
                  else{
                    curIdx++;
                    if(curIdx < days.length){
                      var nextDate = days[curIdx];
                      if(globalKeys[nextDate] != null && globalKeys[nextDate]!.currentContext != null) {
                        RenderBox? nextbox = globalKeys[nextDate]!.currentContext!
                            .findRenderObject() as RenderBox;
                        if(nextbox != null){
                          height += nextbox.size.height + 1;
                        }
                      }
                    }
                  }
                }
              }
            }

            if(_currentDate != scrollToDate[_scrollController.offset ~/ 10] && scrollToDate[_scrollController.offset ~/ 10] != null){
              setState(() {
                _currentDate = scrollToDate[_scrollController.offset ~/ 10]!;
              });
            }
          });
/*
          days.forEach((date) {
            if(globalKeys[date] != null && globalKeys[date]!.currentContext != null) {
              RenderBox? box = globalKeys[date]!.currentContext!
                  .findRenderObject() as RenderBox;
              if (box != null) {
                print(date.toString() + ' : ' + box!.size.height.toString());
              }
            }
          });

 */
/*
          scrollToDate.forEach((key, value) {
            print('scroll : $key , date : $value');
          });

 */
        }
      }
    });
  }


  Widget build(BuildContext context) {
    if(_bottomTabIndex == 0){
      return getUserList();
    }
    else if(_bottomTabIndex == 1){
      return buildBranchTimeline();
    }
    else{
      return Container();
    }
  }


  getWorkerList(String branch){
    final double _lowestPay = widget.lowestPay;
    double payHour = _lowestPay;
    BranchDatabase.getBranchCheckListCollection(
        companyId: _companyName, branch: branch).get().then((
        QuerySnapshot querySnapshot2) {
      List<CheckListItem> checkList = [];
      for (int i = 0; i < querySnapshot2.docs.length; i++) {
        var data = querySnapshot2.docs[i].data()! as Map<String, dynamic>;
        String title = "";
        DateTime writetime = DateTime.now();
        Map<DateTime, String> checked = {};
        data.forEach((key, value) {
          if (key == 'name') {
            if (value != null && value.length > 0) {
              title = value;
            }
          }
          else if (key == 'writetime') {
            if (value != null && value.length > 0) {
              writetime = DateFormat('yyyy-MM-dd').parse(value);
            }
          }
          else {
            if (value != null) {
              DateTime date = DateFormat('yyyy-MM-dd').parse(key);
              if (date != null && date.isBefore(DateTime.now()))
                checked[date] = value;
            }
          }
        });
        setState(() {
          checkList.add(CheckListItem(
              name: title, writetime: writetime, checked: checked));
        });
      }

      checkList.forEach((element) {
        element.checked.forEach((key2, value2) {
          setState(() {
            if(_listDiaryContent[key2] == null){
              _listDiaryContent[key2] = DiaryContent();
            }

            if(_listDiaryContent[key2]!.mapBranchCheckListDone[widget.branch] == null){
              _listDiaryContent[key2]!.mapBranchCheckListDone[widget.branch] = {};
            }

            _listDiaryContent[key2]!.mapBranchCheckListDone[widget.branch]![element.name] = value2;
          });
        });
      });
      setState(() {
        initDone2ndCnt++;
      });
    });

    UserDatabase.getItemCollection(companyId: _companyName, userUid: 'Administrator').get().then((QuerySnapshot querySnapshot) {
      for(int i = 0; i < querySnapshot.docs.length; i++){
        var doc = querySnapshot.docs[i];
        if (doc.id != 'Administrator') {
          if (branch != null) {
            if (doc['workPlace'] == "[" + branch + "]") {
              try {
                if (doc['pay'] != null) {
                  payHour = double.parse((doc['pay']));
                  if(payHour < _lowestPay){
                    UserDatabase.addAdminUserItem(companyId: _companyName,
                        userUid: doc.id,
                        key: 'pay',
                        value: _lowestPay.toString());
                  }
                }
              }
              catch (e) {
                UserDatabase.addAdminUserItem(companyId: _companyName,
                    userUid: doc.id,
                    key: 'pay',
                    value: _lowestPay.toString());
                print(e);
              }

              setState((){
                workerData worker = workerData(name: doc['name'], payHour: payHour, company: _companyName, workPlace: branch,
                onComplete: (element){
                    setState((){
                      workerList.sort((a,b) => b.totalDuration[1].compareTo(a.totalDuration[1]));
                      workerList.sort((a,b) => b.totalDuration[0].compareTo(a.totalDuration[0]));
                      element.startMap.forEach((date, start) {
                        if(globalKeys[date] == null){
                          setState((){
                            globalKeys[date] = GlobalKey();
                            sortedKeys = globalKeys.keys.toList()..sort();
                          });
                        }
                        var end = element.endMap[date]??'';
                        var duration =(element.durationMap[date]??0).toString();
                        if (start != null && start.length > 0 &&
                            date.isBefore(DateTime.now())) {
                          if (end == start) {
                            end = '';
                          }
                          var dur = '0';
                          if (duration != null && duration.length > 0) {
                            dur = duration;
                          }

                          setState(() {
                            if (_listDiaryContent[date] == null)
                              _listDiaryContent[date] = DiaryContent();
                            if (_listDiaryContent[date]!.mapBranchUserTime[branch] == null) {
                              _listDiaryContent[date]!.mapBranchUserTime[branch] = {};
                            }
                            _listDiaryContent[date]!.mapBranchUserTime[branch]![element.name] = ('근무 ' + dur + '시간/' + start + ' ~ ' + end);
                          });

                          if(_currentDate == null){
                            setState((){
                              _currentDate = date;
                            });
                          }
                          else{
                            if(_currentDate.isBefore(date)){
                              setState((){
                                _currentDate = date;
                              });
                            }
                          }
                        }

                        element.textMap.forEach((date, text) {
                          if ( text.length > 0) {
                            setState(() {
                              if (_listDiaryContent[date] == null)
                                _listDiaryContent[date] = DiaryContent();
                              if (_listDiaryContent[date]!.mapBranchUserDiary[branch] ==
                                  null) {
                                _listDiaryContent[date]!.mapBranchUserDiary[branch] = {};
                              }
                              _listDiaryContent[date]!.mapBranchUserDiary[branch]![element.name] =
                                  text;
                            });
                            if(_currentDate == null){
                              setState((){
                                _currentDate = date;
                              });
                            }
                            else{
                              if(_currentDate.isBefore(date)){
                                setState((){
                                  _currentDate = date;
                                });
                              }
                            }
                          }
                        });
                      });
                  });
                },
                onExpenseReadComplete: (worker, date, exItems){
                  exItems.forEach((exItem) {
                    var exInfo = ExpenseInfo();
                    exInfo.type = exItem.type;
                    exInfo.money = exItem.money;
                    exInfo.detail = exItem.detail;
                    exInfo.user = worker.name;
                    exInfo.date = date;
                    setState((){
                      listExpenseInfo.add(exInfo);
                      listExpenseInfo.sort((a,b) => a.user!.compareTo(b.user!));
                      listExpenseInfo.sort((a,b) => a.date!.compareTo(b.date!));
                    });
                  });


                  setState(() {
                    if (_listDiaryContent[date] == null)
                      _listDiaryContent[date] = DiaryContent();
                    if (_listDiaryContent[date]!.mapBranchUserExpense[branch] ==
                        null) {
                      _listDiaryContent[date]!.mapBranchUserExpense[branch] = {};
                    }
                    if (_listDiaryContent[date]!
                        .mapBranchUserExpense[branch]![worker.name] == null) {
                      if(exItems != null && exItems.length > 0){
                        _listDiaryContent[date]!.mapBranchUserExpense[branch]![worker.name] = exItems;
                      }
                    }

                  });

                  if(_currentDate == null){
                    setState((){
                      _currentDate = date;
                    });
                  }
                  else{
                    if(_currentDate.isBefore(date)){
                      setState((){
                        _currentDate = date;
                      });
                    }
                  }
                  setState(() {
                    initDone = true;
                  });
                }
                );

                worker.getWorkInfo();
                workerList.add(worker);

              });
            }
          }
        }
      }
    });
  }

  Widget getUserList(){
    return Container(
      color: Colors.black38,
      child:  ListView.separated(itemCount: workerList.length + 2,
          separatorBuilder: (BuildContext context, int index) {
            return Divider(height: 5.0,
                color: Colors.black38,
                thickness: 5);
          },
          itemBuilder: (BuildContext context, int index){
            if(index == workerList.length + 1){
              return ListTile(

              );
            }
            else if(index == 0){
              return totalPayLatest();
            }
            else{
              return getWorkerTile(index - 1);
            }
          })
    );
  }

  Widget totalPayLatest(){
    return ListTile(
      tileColor: Colors.black38,
      title: SizedBox(
        height: 30,
        child: Container(
          alignment: Alignment.centerLeft,
          child: Text(widget.branch + ' 합계',style: TextStyle(color: Colors.indigo[300], fontWeight: FontWeight.bold, fontSize: 15), textAlign: TextAlign.left),
        )
      ),
      subtitle: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            constraints: BoxConstraints(minWidth: 140),
            padding: EdgeInsets.all(3),
            margin: EdgeInsets.all(3),
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: Colors.indigo
            ),
            child: Column(
              children: [
                Text(getMonthPrint(false),style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('급여 : ' + NumberFormat.currency(locale: "ko_KR", symbol: "").format(sumTotalPayOfBranch(0)) + '원', style: TextStyle(color: Colors.white)),
                    Text('지출 : ' + NumberFormat.currency(locale: "ko_KR", symbol: "").format(getMonthlySumExpense(DateTime.now().month)) + '원', style: TextStyle(color: Colors.white))
                  ],
                )
              ],
            ),
          ),
          SizedBox(width: 5,),
          Container(
            constraints: BoxConstraints(minWidth: 140),
            padding: EdgeInsets.all(3),
            margin: EdgeInsets.all(3),
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: Colors.white12
            ),
            child:  Column(
              children: [
                Text(getMonthPrint(true),style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('급여 : ' + NumberFormat.currency(locale: "ko_KR", symbol: "").format(sumTotalPayOfBranch(1)) + '원', style: TextStyle(color: Colors.white70)),
                    Text('지출 : ' + NumberFormat.currency(locale: "ko_KR", symbol: "").format(getMonthlySumExpense(((DateTime.now().month - 1) == 0) ? 12 : (DateTime.now().month - 1))) + '원', style: TextStyle(color: Colors.white70))
                  ],
                )
              ],
            ),
          ),
        ],
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: EdgeInsets.fromLTRB(15, 10, 0, 0),
          child: Text('${DateTime.now().month}월 급여 ' + NumberFormat.currency(locale: "ko_KR", symbol: "￦").format(sumTotalPayOfBranch(0)) +
            ' / 지출 ' + NumberFormat.currency(locale: "ko_KR", symbol: "￦").format(getMonthlySumExpense(DateTime.now().month))
            ,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.blueAccent[100]),
          ),
        ),
        Container(
          margin: EdgeInsets.fromLTRB(15, 2, 0, 10),
          child: Text('${((DateTime.now().month - 1) == 0) ? 12 : (DateTime.now().month - 1)}월 급여 ' + NumberFormat.currency(locale: "ko_KR", symbol: "￦").format(sumTotalPayOfBranch(1)) +
              ' / 지출 ' + NumberFormat.currency(locale: "ko_KR", symbol: "￦").format(getMonthlySumExpense(((DateTime.now().month - 1) == 0) ? 12 : (DateTime.now().month - 1)))
            ,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.grey),
          ),
        )
      ],
    );
  }

  double getMonthlySumExpense(int month){
    double sumExpense = 0;

    listExpenseInfo.forEach((element) {
      if(element.date != null && element.money != null){
        if(element.date!.month == month){
          double m = double.parse(element.money!.replaceAll(',', ''));
          if(m != null){
            sumExpense += m;
          }
        }
      }
    });
    return sumExpense;
  }

  Widget getWorkerTile(int index){
    return  ListTile(
        //dense: true,
        isThreeLine: true,
        title:
        Container(
          alignment: Alignment.centerLeft,
          child: SizedBox(
            height: 30,
            child: TextButton(
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                alignment: Alignment.centerLeft
              ),
              child:Text(workerList[index].name,style: TextStyle(color: Colors.teal[200], fontWeight: FontWeight.bold, fontSize: 15), textAlign: TextAlign.left),
              onPressed: (){
                _payEditingController.text = NumberFormat.currency(locale: 'ko' ,symbol: '').format(workerList[index].payHour);
                showDialog<String>(
                  context: context,
                  builder: (BuildContext context) => AlertDialog(
                    backgroundColor: Color(0xFF333A47),
                    title: Row(
                      children: [
                        const Expanded(
                          child: Text('직원 정보', style: TextStyle(color: Colors.white70),),
                        ),
                        Container(
                          child:IconButton(icon: Icon(Icons.calendar_today_outlined),
                              color: Colors.white70,
                              onPressed: (){
                                Navigator.pop(context, 'Calendar');
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) =>
                                      TimeLinePage(
                                          title: "My Working time", companyId: _companyName, user: workerList[index].name.trim(), workplace: workerList[index].workPlace)),
                                );
                              }),
                        ),
                      ],
                    ),

                    content: Container(
                      height: 170,
                      child: Column(children: [
                        Container(alignment: Alignment.centerLeft, margin: const EdgeInsets.all(10),
                          child: Text('이름 : ' + workerList[index].name ,style: TextStyle(color: Colors.white70),),),
                        Container(alignment: Alignment.centerLeft, margin: const EdgeInsets.all(10),
                          child: Text('소속 : ' + workerList[index].workPlace ,style: TextStyle(color: Colors.white70),),),
                        Container(
                          margin: const EdgeInsets.all(10),
                          child:TextFormField(
                            style: TextStyle(fontSize: 15, color: Colors.white70),
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(borderSide: BorderSide(color: Colors.white70)),
                              enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white70)),
                              labelText: '시급',
                              labelStyle: TextStyle(color: Colors.white70),
                              prefixText: _currency,
                              prefixStyle: TextStyle(color: Colors.white70),
                            ),
                            controller: _payEditingController,
                            inputFormatters: [
                              ThousandsFormatter(allowFraction: true)
                            ],
                          ) ,),

                      ],) ,
                    ),

                    actions: <Widget>[

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            child: TextButton(
                              onPressed: (){
                                showDialog<String>(
                                  context: context,
                                  builder: (BuildContext context) => AlertDialog(
                                    backgroundColor: Color(0xFF333A47),
                                    title: const Text('Delete User', style: TextStyle(color: Colors.white70),),
                                    content: Text(workerList[index].getUserId(), style: TextStyle(color: Colors.white70)),
                                    actions: <Widget>[
                                      deleteWorkerButton(index),
                                      TextButton(
                                        onPressed: () => Navigator.pop(context, 'Cancel'),
                                        child: const Text('Cancel', style: TextStyle(color: Colors.white70),),
                                      ),
                                    ],
                                  ),);
                              },
                              child: const Text('Delete', style: TextStyle(color: Colors.redAccent)),
                            ),
                          ),
                          Container(
                            child: Row(
                              children: [
                                TextButton(
                                  onPressed: (){
                                    setState(() {
                                      _payPerHourInput = _payEditingController.text.replaceAll(',', '');
                                      if(double.parse(_payPerHourInput) < widget.lowestPay){
                                        _payPerHourInput = widget.lowestPay.toString();
                                        Fluttertoast.showToast(msg: '최저시급(${NumberFormat.currency(locale: 'ko' ,symbol: '').format(widget.lowestPay)}원)보다 낮게 설정할 수 없습니다.');
                                        UserDatabase.addAdminUserItem(companyId: _companyName, userUid: workerList[index].getUserId() , key: 'pay', value: widget.lowestPay.toString());
                                      }
                                      workerList[index].updatePay(double.parse(_payPerHourInput));
                                      UserDatabase.addAdminUserItem(companyId: _companyName, userUid: workerList[index].getUserId() , key: 'pay', value: _payPerHourInput);
                                    });
                                    Navigator.pop(context, 'Ok');
                                  },
                                  child: Text('Ok', style: TextStyle(color: Colors.teal[200])),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(context, 'Close'),
                                  child: Text('Close', style: TextStyle(color: Colors.teal[200]),),
                                ),
                              ],
                            ),
                          )

                        ],
                      )
                    ],
                  ),);
              },
            ),
          ),
        ),

        subtitle : Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              constraints: BoxConstraints(minWidth: 140),
              padding: EdgeInsets.all(3),
              margin: EdgeInsets.all(3),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: Colors.white12
              ),
              child: Column(
                children: [
                  Text(getMonthPrint(false),style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('근무 : ' + workerList[index].totalDuration[0].toString() + '시간', style: TextStyle(color: Colors.white70)),
                      Text('급여 : ' + NumberFormat.currency(locale: "ko_KR", symbol: "").format(workerList[index].latestPayMonth[0]) + '원', style: TextStyle(color: Colors.white70))
                    ],
                  )
                ],
              ),
            ),
            SizedBox(width: 5,),
            Container(
              constraints: BoxConstraints(minWidth: 140),
              padding: EdgeInsets.all(3),
              margin: EdgeInsets.all(3),
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: Colors.white12
              ),
              child:  Column(
                children: [
                  Text(getMonthPrint(true),style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('근무 : ' + workerList[index].totalDuration[1].toString() + '시간', style: TextStyle(color: Colors.white70)),
                      Text('급여 : ' + NumberFormat.currency(locale: "ko_KR", symbol: "").format(workerList[index].latestPayMonth[1]) + '원', style: TextStyle(color: Colors.white70))
                    ],
                  )
                ],
              ),
            ),
          ],
        ) ,
    );
  }

  double sumTotalPayOfBranch(int index) {
    double total = 0;
    workerList.forEach((element) {
      if(element.latestPayMonth.length > 0){
        total += element.latestPayMonth[index];
      }
    });
    return total;
  }

  void deleteWorker(int workerIndex) async{
    String userId = workerList[workerIndex].getUserId();

    await UserDatabase.deleteUser(companyId: _companyName, userUid: userId);

    UserDatabase.getItemCollection(companyId: _companyName, userUid: userId).get().then((QuerySnapshot querySnapshot) {
      querySnapshot.docs.forEach((doc) {
        UserDatabase.deleteDoc(companyId: _companyName, userUid: userId, date: doc.id);
      });
    });

    setState(() {
      workerList.removeAt(workerIndex);
      //getWorkerList(adminSnapShot);
    });
  }

  Widget deleteWorkerButton(int workerIndex){
    return TextButton(
      onPressed: (() => {
        Navigator.pop(context, 'OK'),
        deleteWorker(workerIndex)
      }),
      child: const Text('OK', style: TextStyle(color: Colors.white70)),
    );
  }


  exportData() async{
    final xlsio.Workbook workbook = xlsio.Workbook();
    String currentTime = DateFormat('yyyy-MM-dd').format(DateTime.now());
    String fileName = (widget.branch) + '_' + currentTime + '.xlsx';
    List<String> sheetNameList = [];
    String user = '';
    int userCnt = 0;
    int year,month,day = 0;
    String sheetName = '';
    bool firstSheet = true;

    int yearMonth = 0;
    int minYearMonth = 999999;
    int maxYearMonth = 0;

    final gridRowOffset = 2;
    if(workerList!=null){
      workerList.forEach((key) {
        key.durationMap.forEach((key, value) {
          year = key.year;
          month = key.month;
          yearMonth = year * 12 + (month - 1);
          if(yearMonth < minYearMonth)
            minYearMonth = yearMonth;

          if(yearMonth > maxYearMonth)
            maxYearMonth = yearMonth;
        });
      });

      if(minYearMonth < maxYearMonth - 3){
        minYearMonth = maxYearMonth - 3;
      }
      if(minYearMonth < 0) minYearMonth = 0;

      xlsio.Style globalStyle = workbook.styles.add('style');
      globalStyle.borders.all.lineStyle = xlsio.LineStyle.thin;

      xlsio.Style weekendStyle = workbook.styles.add('weekendstyle');
      weekendStyle.fontColor = '#FF0000';
      weekendStyle.borders.all.lineStyle = xlsio.LineStyle.thin;

      for(int a = maxYearMonth; a>=minYearMonth; a--){
        xlsio.Worksheet sheet;
        sheetName = (a~/12).toString() + "년" + (a % 12 + 1).toString() + "월";
        sheetNameList.add(sheetName);
        if(firstSheet){
          sheet = workbook.worksheets[0];
          sheet.name = sheetName;
          firstSheet = false;
        }
        else{
          sheet = workbook.worksheets.addWithName(sheetName);
        }


        var cell = sheet.getRangeByIndex(gridRowOffset - 1, 1);
        cell.setText((a % 12 + 1).toString() + '월 출석부');

        double d = 1;
        for(int i = gridRowOffset; i < gridRowOffset + 31; i++) {
          var cell = sheet.getRangeByIndex(i + 1, 1);
          cell.setNumber(d);
          if((DateTime(a~/12,(a%12 + 1),d.toInt()).weekday == 6) || (DateTime(a~/12,(a%12 + 1),d.toInt()).weekday == 7)){
            cell.cellStyle = weekendStyle;
          }
          else{
            cell.cellStyle = globalStyle;
          }
          d += 1;
        }

        userCnt =0;
        workerList.forEach((key) {
          userCnt++;
          user = key.name;
          var userNameRow = sheet.getRangeByIndex(gridRowOffset,userCnt + 1);
          userNameRow.setText(user);

          cell = sheet.getRangeByIndex(32 + gridRowOffset, 1);
          cell.setText("합계");
          cell.cellStyle = globalStyle;

          cell = sheet.getRangeByIndex(33 + gridRowOffset, 1);
          cell.setText("시급");
          cell.cellStyle = globalStyle;

          cell = sheet.getRangeByIndex(34 + gridRowOffset, 1);
          cell.setText("주휴수당");
          cell.cellStyle = globalStyle;

          cell = sheet.getRangeByIndex(35 + gridRowOffset, 1);
          cell.setText("급여");
          cell.cellStyle = globalStyle;

          cell = sheet.getRangeByIndex(36 + gridRowOffset, 1);
          cell.setText("급여 3.3%");
          cell.cellStyle = globalStyle;

          cell = sheet.getRangeByIndex(37 + gridRowOffset, 1);
          cell.setText("총급여");
          cell.cellStyle = globalStyle;

          cell = sheet.getRangeByIndex(38 + gridRowOffset, 1);
          cell.setText("총급여 3.3%");
          cell.cellStyle = globalStyle;

          String sumStartCell = sheet.getRangeByIndex(1 + gridRowOffset, userCnt + 1).addressLocal;
          String sumEndCell = sheet.getRangeByIndex(31 + gridRowOffset, userCnt + 1).addressLocal;

          cell = sheet.getRangeByIndex(32 + gridRowOffset, userCnt + 1);
          String sumFormula = '=SUM(' + sumStartCell + ':' + sumEndCell + ')';
          cell.setFormula(sumFormula);
          //cell2.setFormula('=SUM(B2:B32)');

          cell = sheet.getRangeByIndex(33 + gridRowOffset, userCnt + 1);
          cell.setNumber(key.payHour);

          cell = sheet.getRangeByIndex(35 + gridRowOffset, userCnt + 1);
          sumFormula = '=SUM(PRODUCT(' + sheet.getRangeByIndex(32 + gridRowOffset, userCnt + 1).addressLocal + ',' + sheet.getRangeByIndex(33 + gridRowOffset, userCnt + 1).addressLocal + '),' + sheet.getRangeByIndex(34 + gridRowOffset, userCnt + 1).addressLocal + ')';
          cell.setFormula(sumFormula);
          cell.numberFormat = '(\$#,##0.00)';

          cell = sheet.getRangeByIndex(36 + gridRowOffset, userCnt + 1);
          sumFormula = '=PRODUCT(' + sheet.getRangeByIndex(35 + gridRowOffset, userCnt + 1).addressLocal + ',96.7) / 100';
          cell.setFormula(sumFormula);


        });
        sheet.getRangeByIndex(gridRowOffset,2,36 + gridRowOffset, userCnt + 1).cellStyle = globalStyle;

        String sumStartCell = sheet.getRangeByIndex(35 + gridRowOffset, 2).addressLocal;
        String sumEndCell = sheet.getRangeByIndex(35 + gridRowOffset, userCnt + 1).addressLocal;
        cell = sheet.getRangeByIndex(37 + gridRowOffset, 2);
        String sumFormula = '=SUM(' + sumStartCell + ':' + sumEndCell + ')';
        cell.setFormula(sumFormula);
        cell.cellStyle = globalStyle;

        sumStartCell = sheet.getRangeByIndex(36 + gridRowOffset, 2).addressLocal;
        sumEndCell = sheet.getRangeByIndex(36 + gridRowOffset, userCnt + 1).addressLocal;
        cell = sheet.getRangeByIndex(38 + gridRowOffset, 2);
        sumFormula = '=SUM(' + sumStartCell + ':' + sumEndCell + ')';
        cell.setFormula(sumFormula);
        cell.cellStyle = globalStyle;

        cell = sheet.getRangeByIndex(40 + gridRowOffset, 1);
        cell.setText("지출현황");
        cell.cellStyle = globalStyle;

        for(int i = 0; i < expenseType.length; i++) {
          cell = sheet.getRangeByIndex(41 + gridRowOffset, 1 + i);
          cell.setText(expenseType[i]);
          cell.cellStyle = globalStyle;
        }
        cell = sheet.getRangeByIndex(41 + gridRowOffset, 1 + expenseType.length);
        cell.setText('합계');
        cell.cellStyle = globalStyle;

        cell = sheet.getRangeByIndex(42 + gridRowOffset, 1 + expenseType.length);
        sumStartCell = sheet.getRangeByIndex(42 + gridRowOffset, 1).addressLocal;
        sumEndCell = sheet.getRangeByIndex(42 + gridRowOffset, expenseType.length).addressLocal;
        sumFormula = '=SUM(' + sumStartCell + ':' + sumEndCell + ')';
        cell.setFormula(sumFormula);
        cell.cellStyle = globalStyle;

        cell = sheet.getRangeByIndex(44 + gridRowOffset, 1);
        cell.setText("지출내역");
        cell.cellStyle = globalStyle;

        cell = sheet.getRangeByIndex(45 + gridRowOffset, 1);
        cell.setText("일자");
        cell.cellStyle = globalStyle;

        cell = sheet.getRangeByIndex(45 + gridRowOffset, 2);
        cell.setText("담당자");
        cell.cellStyle = globalStyle;

        cell = sheet.getRangeByIndex(45 + gridRowOffset, 3);
        cell.setText("지출유형");
        cell.cellStyle = globalStyle;

        cell = sheet.getRangeByIndex(45 + gridRowOffset, 4);
        cell.setText("금액");
        cell.cellStyle = globalStyle;

        cell = sheet.getRangeByIndex(45 + gridRowOffset, 5);
        cell.setText("상세내역");
        cell.cellStyle = globalStyle;
      }


      Map<String ,Map<String, double>> totalExpense = {};
      userCnt=0;
      workerList.forEach((key) {
        userCnt++;
        key.durationMap.forEach((key, value) {
          year = key.year;
          month = key.month;
          day = key.day;
          xlsio.Worksheet sheet;

          sheetName = year.toString() + "년" + month.toString() + "월";
          if(sheetNameList.contains(sheetName)){
            sheet = workbook.worksheets[sheetName];

            var cell = sheet.getRangeByIndex(day + gridRowOffset , userCnt + 1);
            if(value > 0)
              cell.setNumber(value);
          }
        });

        Map<String, double> weekendPay = {};
        key.weekDurationMap.forEach((key2, value2) {
          year = key2.year;
          month = key2.month;
          day = key2.day;

          if(value2 >= 15){
            sheetName = year.toString() + "년" + month.toString() + "월";
            if(sheetNameList.contains(sheetName)){
              if(weekendPay[sheetName] == null){
                weekendPay[sheetName] = 0;
              }
              var thisweekPay = value2 * 8 / 40 * key.payHour;
              weekendPay[sheetName] = weekendPay[sheetName]! + thisweekPay;
            }
          }
        });

        weekendPay.forEach((sname, pay) {
          xlsio.Worksheet sheet;
          if(sheetNameList.contains(sname)){
            sheet = workbook.worksheets[sname];
            var cell = sheet.getRangeByIndex(34 + gridRowOffset , userCnt + 1);
            if(pay > 0){
              cell.setNumber(pay);
            }
          }
        });
      });

      if(listExpenseInfo.length > 0){
        int exIdx = 0;
        int preMon = listExpenseInfo[0].date!.month;

        for(int i = 0; i < listExpenseInfo.length; i++){
          var exInfo = listExpenseInfo[i];

          year = exInfo.date!.year;
          month = exInfo.date!.month;
          day = exInfo.date!.day;
          xlsio.Worksheet sheet;

          if(preMon != month){
            exIdx = 0;
          }
          preMon = month;

          sheetName = year.toString() + "년" + month.toString() + "월";
          if(sheetNameList.contains(sheetName)){
            xlsio.Worksheet sheet;
            sheet = workbook.worksheets[sheetName];
            var cell = sheet.getRangeByIndex(46 + exIdx + gridRowOffset, 1);
            cell.setNumber(exInfo.date!.day.toDouble());
            cell.cellStyle = globalStyle;

            cell = sheet.getRangeByIndex(46 + exIdx + gridRowOffset, 2);
            cell.setText(exInfo.user);
            cell.cellStyle = globalStyle;

            cell = sheet.getRangeByIndex(46 + exIdx + gridRowOffset, 3);
            cell.setText(exInfo.type);
            cell.cellStyle = globalStyle;

            if(exInfo.money!= null && exInfo.money!.length > 0){
              double m = double.parse(exInfo.money!.replaceAll(',', ''));
              if(m != null){
                cell = sheet.getRangeByIndex(46 + exIdx + gridRowOffset, 4);
                cell.setNumber(m);
                if(exInfo.type == null){
                  exInfo.type = '기타';
                }

                if(exInfo.type != null){
                  if(totalExpense[sheetName] == null) totalExpense[sheetName] = {};
                  if(totalExpense[sheetName]![exInfo.type!] == null) totalExpense[sheetName]![exInfo.type!] = 0;
                  totalExpense[sheetName]![exInfo.type!] = totalExpense[sheetName]![exInfo.type!]! + m;
                }
              }
            }
            cell = sheet.getRangeByIndex(46 + exIdx + gridRowOffset, 4);
            cell.cellStyle = globalStyle;

            cell = sheet.getRangeByIndex(46 + exIdx + gridRowOffset, 5);
            cell.setText(exInfo.detail);
            cell.cellStyle = globalStyle;

            exIdx++;
          }
        }

        totalExpense.forEach((key, value) {
          xlsio.Worksheet sheet;
          sheet = workbook.worksheets[key];
          Map<String, double> mapTotal = value;

          for(int i = 0; i < expenseType.length; i++){
            var type = expenseType[i];
            var cell = sheet.getRangeByIndex(42 + gridRowOffset, 1 + i);
            cell.setNumber(mapTotal[type]);
            cell.cellStyle = globalStyle;
          }
        });
      }

      final List<int> bytes = workbook.saveAsStream();

      download(fileName, bytes);
      workbook.dispose();
    }
  }

  Widget buildBranchTimeline(){
    return Container(
        color: Colors.black38,
        child: Stack(
          children: [
            SingleChildScrollView(
              controller: _scrollController,
              child: ScrollablePositionedList.separated(
                itemScrollController: itemScrollController,
                itemPositionsListener: itemPositionsListener,
                shrinkWrap: true,
                physics: const ClampingScrollPhysics(),
                itemCount: days.length,
                itemBuilder: (BuildContext context, int index) {
                  //DateTime date = sortedKeys.elementAt(index);
                  return buildDiaryContent(days[index]);
                },

                separatorBuilder: (BuildContext context, int index) {
                  if (IsSomethingShow(days[index]) && _listDiaryContent[days[index]] != null) {
                    return Divider(height: 1,
                        color: Colors.black38,
                        thickness: 1);
                  }
                  else{
                    return Container();
                  }

                },
              ),
            ),
            Container(
                color: Colors.black38,
                child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        alignment: Alignment.center,
                        padding: EdgeInsets.fromLTRB(10, 0, 0, 0),
                        height: 30,
                        color: Colors.black.withOpacity(0.5),
                        child: Stack(
                          children: [
                            Container(
                              alignment: Alignment.centerLeft,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Text('  ' + DateFormat('yyyy-MM-dd').format(_currentDate) + ' ',
                                    style: TextStyle(
                                        color: Colors.indigo[300],
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  Text(DateFormat('E', 'ko_KR').format(_currentDate),
                                    style: TextStyle(
                                        color: DateFormat('E', 'ko_KR')
                                            .format(_currentDate) == '토' ||
                                            DateFormat('E', 'ko_KR').format(
                                                _currentDate) == '일' ? Colors
                                            .redAccent[100] : Colors.indigo[300],
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              alignment: Alignment.centerRight,
                              child: IconButton(
                                onPressed: (){
                                  setState((){
                                    filterTypeAll = filterTypeAllView;
                                    filterType = {};
                                    filterTypeView.forEach((key, value) {
                                      filterType[key] = value;
                                    });
                                  });
                                  showDialog<String>(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return StatefulBuilder(builder: (context, _setState){
                                        return AlertDialog(
                                          backgroundColor: Color(0xFF333A47),
                                          title: Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text('필터', style: TextStyle(color: Colors.white)),
                                              Row(
                                                children: [
                                                  Text('전체', style: TextStyle(color: Colors.white70, fontSize: 14),),
                                                  Switch(value: filterTypeAll, onChanged: (value){
                                                    _setState((){
                                                      filterTypeAll = value;
                                                      filterType.forEach((key, value) {
                                                        filterType[key] = filterTypeAll;
                                                      });
                                                    });
                                                  })
                                                ],
                                              )
                                            ],
                                          ),
                                          content:
                                          Container(
                                              height: 160,
                                              width: MediaQuery.of(context).size.width - 100,
                                              child:
                                              ListView.builder(
                                                shrinkWrap: true,
                                                physics: const ClampingScrollPhysics(),
                                                itemCount: diaryType.length,
                                                itemBuilder: (BuildContext context, index){
                                                  return Theme(
                                                      data: ThemeData(unselectedWidgetColor: Colors.white70, scrollbarTheme: ScrollbarThemeData(isAlwaysShown: true )),
                                                      child: SizedBox(
                                                        height: 40,
                                                        child: CheckboxListTile(
                                                            value: filterType[diaryType[index]],
                                                            activeColor: Colors.transparent,
                                                            checkColor: Colors.white,
                                                            controlAffinity: ListTileControlAffinity.leading,
                                                            checkboxShape: RoundedRectangleBorder(
                                                              borderRadius: BorderRadius.circular(3),
                                                              side: BorderSide(color: Colors.white70),
                                                            ),
                                                            title: Text(diaryType[index], style: TextStyle(color: Colors.white70)),
                                                            onChanged: (value){
                                                              _setState((){
                                                                filterType[diaryType[index]] = value!;
                                                                if(value == false){
                                                                  filterTypeAll = value;
                                                                }
                                                              });
                                                            }),
                                                      )
                                                  );
                                                },
                                              )
                                          ),
                                          actions: <Widget>[
                                            TextButton(
                                              onPressed:
                                              (() {
                                                _setState((){
                                                  filterTypeAllView = filterTypeAll;
                                                  filterType.forEach((key, value) {
                                                    if(value == false){
                                                      filterTypeAllView = false;
                                                    }
                                                    filterTypeView[key] = value;
                                                  });


                                                  _currentDate = days[days.length - 1];
                                                  _listDiaryContent.forEach((date, value) {
                                                    if(filterTypeView['근무현황'] != null && filterTypeView['근무현황']!) {
                                                      value.mapBranchUserTime.keys.forEach((element) {
                                                        if (_currentDate == null) {
                                                          setState(() {
                                                            _currentDate = date;
                                                          });
                                                        }
                                                        else {
                                                          if (_currentDate.isBefore(date)) {
                                                            setState(() {
                                                              _currentDate = date;
                                                            });
                                                          }
                                                        }
                                                      });
                                                    }
                                                    if(filterTypeView['지출현황'] != null && filterTypeView['지출현황']!) {
                                                      value.mapBranchUserExpense.keys.forEach((element) {
                                                        if (_currentDate == null) {
                                                          setState(() {
                                                            _currentDate = date;
                                                          });
                                                        }
                                                        else {
                                                          if (_currentDate.isBefore(date)) {
                                                            setState(() {
                                                              _currentDate = date;
                                                            });
                                                          }
                                                        }
                                                      });
                                                    }
                                                    if(filterTypeView['체크리스트'] != null && filterTypeView['체크리스트']!) {
                                                      value.mapBranchUserExpense.keys.forEach((element) {
                                                        if (_currentDate == null) {
                                                          setState(() {
                                                            _currentDate = date;
                                                          });
                                                        }
                                                        else {
                                                          if (_currentDate.isBefore(date)) {
                                                            setState(() {
                                                              _currentDate = date;
                                                            });
                                                          }
                                                        }
                                                      });
                                                    }
                                                    if(filterTypeView['업무일지'] != null && filterTypeView['업무일지']!) {
                                                      value.mapBranchUserExpense.keys.forEach((element) {
                                                        if (_currentDate == null) {
                                                          setState(() {
                                                            _currentDate = date;
                                                          });
                                                        }
                                                        else {
                                                          if (_currentDate.isBefore(date)) {
                                                            setState(() {
                                                              _currentDate = date;
                                                            });
                                                          }
                                                        }
                                                      });
                                                    }
                                                  });

                                                });
                                                Navigator.pop(context, 'Ok');
                                              }),
                                              child: const Text('Ok'),
                                            ),
                                            TextButton(
                                              onPressed: (){
                                                Navigator.pop(context, 'Cancel');
                                              },
                                              child: const Text('Cancel'),
                                            ),
                                          ],
                                        );
                                      });

                                    },);
                                },
                                color: Colors.white,
                                icon: (filterTypeAllView) ? Icon(Icons.filter_alt, size: 16,) : Icon(Icons.filter_alt_outlined, size: 16,),
                              ),
                            )

                          ],
                        ),
                      ),
                    ]
                )
            ),
          ],
        )
    );
  }

  Widget buildDiaryHeader(IconData iconData, String tag, Color? color) {
    return Container(
      margin: EdgeInsets.only(left : 10, bottom: 5),
      child:
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            alignment: Alignment.centerLeft,
            padding: EdgeInsets.only(left: 5, right: 5),

            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(iconData, size: 18, color: color,),
                Text(tag,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: 15),),

              ],
            ),
          ),
        ],
      ),

    );
  }

  bool IsSomethingShow(DateTime date){
    bool ret = false;

    if(_listDiaryContent[date] != null){
      if(filterTypeView['근무현황'] != null && filterTypeView['근무현황']!){
        _listDiaryContent[date]!.mapBranchUserTime.keys.forEach((element) {
          ret = true;
        });
      }

      if(filterTypeView['지출현황'] != null && filterTypeView['지출현황']!) {
        _listDiaryContent[date]!.mapBranchUserExpense.keys.forEach((element) {
          if(element.length > 0){
            ret = true;
          }
        });
      }

      if(filterTypeView['체크리스트'] != null && filterTypeView['체크리스트']!) {
        _listDiaryContent[date]!.mapBranchCheckListDone.keys.forEach((element) {
          ret = true;
        });
      }

      if(filterTypeView['업무일지'] != null && filterTypeView['업무일지']!) {
        _listDiaryContent[date]!.mapBranchUserDiary.keys.forEach((element) {
          ret = true;
        });
      }
    }
    return ret;
  }
  Widget buildDiaryContent(DateTime date) {
    if (_listDiaryContent[date] != null) {
      return Container(
          key: globalKeys[date],
          child: (!IsSomethingShow(date)) ? Container() : Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.black38
                ),
                height: 30,
                padding: EdgeInsets.fromLTRB(10, 0, 0, 0),
                margin: EdgeInsets.only(bottom: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text('  ' +
                        DateFormat('yyyy-MM-dd').format(date) +
                        ' ',
                      style: TextStyle(
                          color: Colors.white70,
                          fontSize: 15,
                          fontWeight: FontWeight.bold)
                      ,),
                    Text(DateFormat('E', 'ko_KR').format(date),
                      style: TextStyle(
                          color: DateFormat('E', 'ko_KR')
                              .format(date) == '토' ||
                              DateFormat('E', 'ko_KR').format(
                                  date) == '일' ? Colors
                              .redAccent[100] : Colors.white70,
                          fontSize: 15,
                          fontWeight: FontWeight.bold
                      )
                      ,),
                  ],
                ),
              ),
              if(filterTypeView['체크리스트']! &&  _listDiaryContent[date]!.mapBranchCheckListDone != null &&
                  (_listDiaryContent[date]!.mapBranchCheckListDone.length > 0) && _listDiaryContent[date]!.mapBranchCheckListDone[widget.branch] != null && _listDiaryContent[date]!.mapBranchCheckListDone[widget.branch]!.length > 0)
                Column(
                  children: [
                    buildDiaryHeader(
                        Icons.check, ' 체크리스트', Colors.white70),
                    Container(
                      child: ListView.builder(
                          shrinkWrap: true,
                          padding: EdgeInsets.fromLTRB(5, 0, 0, 5),
                          physics: const ClampingScrollPhysics(),
                          itemCount: _listDiaryContent[date]!.mapBranchCheckListDone[widget.branch]!.keys.length,
                          itemBuilder:(BuildContext context, int index){
                            String checkName = _listDiaryContent[date]!.mapBranchCheckListDone[widget.branch]!.keys.toList().elementAt(index);
                            bool checked = _listDiaryContent[date]!.mapBranchCheckListDone[widget.branch]![checkName]! != 'false';
                            String checkedBy = '';
                            if(checked){
                              checkedBy = _listDiaryContent[date]!.mapBranchCheckListDone[widget.branch]![checkName]!;
                            }
                            if(checkedBy == 'true'){
                              checkedBy = '';
                            }


                            return Container(
                              padding: EdgeInsets.fromLTRB(15, 0, 0, 3),
                              child:   Text((checked?'[v] ':'[ ] ') + checkName + ((checked && checkedBy.length > 0)? (' [' + checkedBy + ']') : ''),style: TextStyle( color: checked?Colors.green[200]:Colors.white30),),
                            );
                          }
                      ),
                    ),
                    SizedBox(height: 10,)
                  ],
                ),
              if(filterTypeView['근무현황']! &&  _listDiaryContent[date]!.mapBranchUserTime != null &&
                  _listDiaryContent[date]!.mapBranchUserTime.length > 0  && _listDiaryContent[date]!.mapBranchUserTime[widget.branch] != null && _listDiaryContent[date]!.mapBranchUserTime[widget.branch]!.length > 0)
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    buildDiaryHeader(
                        Icons.access_time, ' 근무현황', Colors.teal[200]),
                    Container(
                      child: ListView.builder(
                          shrinkWrap: true,
                          padding: EdgeInsets.fromLTRB(5, 0, 0, 5),
                          physics: const ClampingScrollPhysics(),
                          itemCount: _listDiaryContent[date]!.mapBranchUserTime[widget.branch]!.keys.length,
                          itemBuilder:(BuildContext context, int index){
                            String user = _listDiaryContent[date]!.mapBranchUserTime[widget.branch]!.keys.toList().elementAt(index);
                            String timeStr = _listDiaryContent[date]!.mapBranchUserTime[widget.branch]![user]!;

                            return Container(
                              padding: EdgeInsets.fromLTRB(15, 0, 0, 3),
                              child:   Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    alignment: Alignment.centerLeft,
                                    width: 90,
                                    child: Text(user,style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white70),),
                                  ),
                                  Container(
                                    alignment: Alignment.centerLeft,
                                    width: 100,
                                    child: Text(timeStr.split('/')[0], style: TextStyle(color: Colors.white70)),
                                  ),
                                  Container(
                                    alignment: Alignment.centerLeft,
                                    child: Text(timeStr.split('/')[1], style: TextStyle(color: Colors.white70)),
                                  ),
                                ],
                              ),
                            );
                          }
                      ),
                    ),
                    SizedBox(height: 10,)
                  ],
                ),
              if(filterTypeView['지출현황']! && _listDiaryContent[date]!.mapBranchUserExpense != null &&
                  _listDiaryContent[date]!.mapBranchUserExpense.length > 0  && _listDiaryContent[date]!.mapBranchUserExpense[widget.branch] != null && _listDiaryContent[date]!.mapBranchUserExpense[widget.branch]!.length > 0)
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    buildDiaryHeader(Icons.attach_money, ' 지출현황', Colors.yellow[200]),
                    Container(
                      child:  ListView.builder(
                          shrinkWrap: true,
                          padding: EdgeInsets.fromLTRB(5, 0, 0, 5),
                          physics: const ClampingScrollPhysics(),
                          itemCount: _listDiaryContent[date]!.mapBranchUserExpense[widget.branch]!.length,
                          itemBuilder:(BuildContext context, int index){
                            String user = _listDiaryContent[date]!.mapBranchUserExpense[widget.branch]!.keys.toList().elementAt(index);
                            List<ExpenseItem> listExpense = _listDiaryContent[date]!.mapBranchUserExpense[widget.branch]![user]!;
                            return ListView.builder(
                              padding: EdgeInsets.fromLTRB(0, 0, 0, 3),
                              shrinkWrap: true,
                              physics: const ClampingScrollPhysics(),
                              itemCount: listExpense.length,
                              itemBuilder: (BuildContext context, int index){
                                ExpenseItem ex = listExpense[index];
                                return Container(
                                    padding: EdgeInsets.fromLTRB(15, 0, 0, 5),
                                    child : Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Container(
                                              alignment: Alignment.centerLeft,
                                              width: 90,
                                              child: Text(user,style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white70),),
                                            ),
                                            Container(
                                              alignment: Alignment.centerLeft,
                                              width: 90,
                                              child: Text(ex.type??'기타',style: TextStyle(color: Colors.white70),),
                                            ),
                                            Container(
                                              padding: EdgeInsets.only(right: 10),
                                              alignment: Alignment.centerLeft,
                                              child: Text((ex.money??'0') + '원', style: TextStyle(color: Colors.white70)),
                                            ),

                                          ],
                                        ),
                                        if(ex.detail != null) Container(
                                            child: Text(ex.detail!, style: TextStyle(color: Colors.white54, fontSize: 13))
                                        )
                                      ],
                                    )
                                );
                              },
                            );
                          }
                      ),
                    ),
                  ],
                ),
              if(filterTypeView['업무일지']! &&  _listDiaryContent[date]!.mapBranchUserDiary != null &&
                  _listDiaryContent[date]!.mapBranchUserDiary.length > 0  && _listDiaryContent[date]!.mapBranchUserDiary[widget.branch] != null && _listDiaryContent[date]!.mapBranchUserDiary[widget.branch]!.length > 0)
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    buildDiaryHeader(
                        Icons.event_note, ' 업무일지', Colors.blueAccent[100]),
                    Container(
                      child: ListView.builder(
                          shrinkWrap: true,
                          padding: EdgeInsets.fromLTRB(5, 0, 0, 5),
                          physics: const ClampingScrollPhysics(),
                          itemCount: _listDiaryContent[date]!.mapBranchUserDiary[widget.branch]!.keys.length,
                          itemBuilder:(BuildContext context, int index){
                            String user = _listDiaryContent[date]!.mapBranchUserDiary[widget.branch]!.keys.toList().elementAt(index);
                            String diaryText = _listDiaryContent[date]!.mapBranchUserDiary[widget.branch]![user]!;

                            return Container(
                              padding: EdgeInsets.fromLTRB(15, 0, 0, 3),
                              child:   Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    alignment: Alignment.centerLeft,
                                    child: Text(user,style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white70),),
                                  ),
                                  Container(
                                    alignment: Alignment.centerLeft,
                                    child: Text(diaryText, style: TextStyle(color: Colors.white70)),
                                  ),
                                  SizedBox(height: 5,)
                                ],
                              ),
                            );
                          }
                      ),
                    )
                  ],
                ),
                SizedBox(height: 5,)
            ],
          )
      );
    }
    else {
      return Container();
    }
  }


  String getMonthPrint(bool prev){
    DateTime latestMon = DateTime(DateTime.now().year, DateTime.now().month);
    DateTime previousMon;
    String latestMonPrint = latestMon.month.toString() + '월';
    String prevMonPrint = '';

    if(prev){
      if(DateTime.now().month == 1){
        previousMon = DateTime(DateTime.now().year - 1, 12);
        prevMonPrint = previousMon.year.toString() + "년 " + previousMon.month.toString() + '월';
      }
      else{
        previousMon = DateTime(DateTime.now().year, DateTime.now().month - 1);
        prevMonPrint = previousMon.month.toString() + '월';
      }
      return prevMonPrint;
    }
    else{
      return latestMonPrint;
    }
  }
}

class ExpenseInfo{
  String? type;
  String? money;
  String? detail;
  String? user;
  DateTime? date;

}

class workerData{
  late String name;
  late double payHour;
  late String company;
  late String workPlace;
  late Map<DateTime, double> durationMap = {};
  late Map<DateTime, double> weekDurationMap = {};
  late Map<DateTime, String> startMap = {};
  late Map<DateTime, String> endMap = {};
  late Map<DateTime, String> textMap = {};
  late Map<DateTime, List<ExpenseItem>?> expenseListMap = {};
  late List<double> latestPayMonth = [0,0];
  late List<double> totalDuration = [0,0];
  late QuerySnapshot? workerDbQuerySnapshot;
  late QuerySnapshot? workerExpQuerySnapshot;
  int dateCnt = 0;
  int expDateCnt = 0;
  final void Function(workerData)? onComplete;
  final void Function(workerData, DateTime, List<ExpenseItem>)? onExpenseReadComplete;


  workerData({required this.name,required this.payHour,required this.company, required this.workPlace, required this.onComplete, required this.onExpenseReadComplete}){
  }

  Future<void> getWorkInfo() async{
    DateTime latestMon = DateTime(DateTime.now().year, DateTime.now().month, );
    DateTime previousMon;

    if(DateTime.now().month == 1){

      previousMon = DateTime(DateTime.now().year - 1, 12);
    }
    else{
      previousMon = DateTime(DateTime.now().year, DateTime.now().month - 1);
    }
    //QuerySnapshot querySnapshot = await UserDatabase.getItemCollection(companyId: company, userUid: getUserId()).get();
    UserDatabase.getItemCollection(companyId: company, userUid: getUserId()).get().then((QuerySnapshot querySnapshot) async{
      workerDbQuerySnapshot = querySnapshot;
      for(int i = 0; i < querySnapshot.docs.length; i++){
        var doc = querySnapshot.docs[i];
        DateTime date = DateFormat('yyyy-MM-dd').parse(doc.id);
        if(date != null){

          if(date.isBefore(DateTime.now().subtract(Duration(days:365)))){
            //print('Data deleted! user : ${getUserId()} , date : $date');
            UserDatabase.deleteDoc(companyId: company, userUid: getUserId(), date: doc.id).then((value) => print('Data deleted! user : ${getUserId()} , date : $date'));
          }
          else{
            dateCnt++;
            var dateInfo = doc.data()! as Map<String,dynamic>;
            if(doc.id == DateFormat('yyyy-MM-dd').format(latestMon)){
              if(dateInfo['total'] != null){
                totalDuration[0] = double.parse(dateInfo['total']??'0');
                latestPayMonth[0] = (totalDuration[0] * payHour);
              }
            }

            else if(doc.id == DateFormat('yyyy-MM-dd').format(previousMon)){
              if(dateInfo['total'] != null){
                totalDuration[1] = double.parse(dateInfo['total']??'0');
                latestPayMonth[1] = (totalDuration[1] * payHour);
              }
            }

            startMap[date] = dateInfo['start']??'';
            endMap[date] = dateInfo['end']??'';
            textMap[date] = dateInfo['text']??'';
            double duration = double.parse(dateInfo['duration']??'0');

            if(duration > 0){
              durationMap[date] = duration;
              int sunleft = 7 - date.weekday;
              DateTime sunday = date.add(Duration(days: sunleft));
              if(weekDurationMap[sunday] == null){
                weekDurationMap[sunday] = 0;
              }
              weekDurationMap[sunday] = weekDurationMap[sunday]! + duration;
            }


            getListExpenseUser(date).then((value) {
              expDateCnt++;
              expenseListMap[date] = value;
              onExpenseReadComplete!(this, date, value);

              if(expDateCnt == dateCnt){
                onComplete!(this);
              }
            });
          }
        }
      }

      Map<int, double> weekendPay = {};
      weekDurationMap.forEach((key2, value2) {
        if(value2 >= 15){
          if((latestMon.month == key2.month) || (previousMon.month == key2.month)){
            if(weekendPay[key2.month] == null){
              weekendPay[key2.month] = 0;
            }
            var thisweekPay = value2 * 8 / 40 * payHour;
            weekendPay[key2.month] = weekendPay[key2.month]! + thisweekPay;
          }
        }
      });

      weekendPay.forEach((mon, pay) {
        if(latestMon.month == mon){
          latestPayMonth[0] += pay;
        }
        else{
          latestPayMonth[1] += pay;
        }
      });
    });
  }

  Future<List<ExpenseItem>> getListExpenseUser(DateTime date) async{
    String dateDB = DateFormat('yyyy-MM-dd').format(date);
    QuerySnapshot querySnapshot = await UserDatabase.getExpenseItemCollection(companyId: company, userUid: getUserId(), date: dateDB).get();
    List<ExpenseItem> listExpense = [];
    querySnapshot.docs.forEach((doc) {
      var expenseInfo = doc.data()! as Map<String, dynamic>;
      var expenseItem = ExpenseItem();
      expenseInfo.forEach((key, value) {
        if(key == 'type'){
          expenseItem.type = value;
        }
        else if(key == 'money'){
          expenseItem.money = value;
        }
        else if(key == 'detail'){
          expenseItem.detail = value;
        }
      });
      listExpense.add(expenseItem);
    });

    return listExpense;
  }


  String getUserId(){
    return name + ' - [' + workPlace+']';
  }

  String getUserInfoPrint(){
    DateTime latestMon = DateTime(DateTime.now().year, DateTime.now().month);
    DateTime previousMon;
    String latestMonPrint = latestMon.month.toString() + '월';
    String prevMonPrint = '';
    if(DateTime.now().month == 1){
      previousMon = DateTime(DateTime.now().year - 1, 12);
      prevMonPrint = previousMon.year.toString() + "년 " + previousMon.month.toString() + '월';
    }
    else{
      previousMon = DateTime(DateTime.now().year, DateTime.now().month - 1);
      prevMonPrint = previousMon.month.toString() + '월';
    }

    return latestMonPrint + ' 근무 : ' + (totalDuration[0].toString()) + "시간 , " + "급여 : " + NumberFormat.currency(locale: "ko_KR", symbol: "￦").format(latestPayMonth[0])
        + "\n" + prevMonPrint + ' 근무 : ' + (totalDuration[1].toString()) + "시간 , " +  "급여 : " + NumberFormat.currency(locale: "ko_KR", symbol: "￦").format(latestPayMonth[1]);
  }


  void updatePay(double newPay){
    payHour = newPay;
    latestPayMonth[0] = (totalDuration[0] * payHour);
    latestPayMonth[1] = (totalDuration[1] * payHour);
  }
}