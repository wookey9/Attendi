import 'dart:async';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:work_inout/user_database.dart';
import 'adminTimelineTab.dart';
import 'branch_database.dart';
import 'package:syncfusion_flutter_xlsio/xlsio.dart' as xlsio;
import 'package:loading_indicator/loading_indicator.dart';
import 'timelineScreen.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'checklist.dart';
import 'myDownload.dart';


class AdminPage extends StatefulWidget{
  const AdminPage({required this.companyName, required this.adminPassword });

  final String companyName;
  final String adminPassword;
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

  late ScrollController _timelieScrollCon = ScrollController();

  var _tabController;
  @override
  void initState() {
    _companyName = widget.companyName;
    _adminPassword = widget.adminPassword;
    fToast.init(context);

    try{
      createBranchTabs();
    }
    catch(e){
      print(e);
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
          Map<DateTime, bool> checked = {};

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
                  checked[date] = value == "true" ? true : false;
              }
            }
          });

          setState((){
            _listCheckListBranch[branchName]!.add(CheckListItem(name: title, writetime: writetime, checked: checked));
          });

        }
      });

    }

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

    _branchList.forEach((branchName) {
      var stcon = StreamController<int>();
      _listStreamController.add(stcon);
      _branchTabBar.add(Tab(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(Icons.place_outlined, size: 18,),
          Text(branchName),
        ],
      )
        ,));
      _branchUserTabView.add(BranchPage(company: _companyName, branch: branchName, stream: stcon.stream,));
    });
    var stcon2 = StreamController<int>();
    _listStreamController.add(stcon2);
    _branchTabBar.add(Tab(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(Icons.settings, size: 18,),
            Text('설정'),
          ],
        )
    ));
    _branchUserTabView.add(BranchEditPage(company: _companyName, branchList: _branchList, stream: stcon2.stream, adminPassword: widget.adminPassword,));

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
              backgroundColor: Color(0xFF333A47),
              // Here we take the value from the MyHomePage object that was created by
              // the App.build method, and use it to set our appbar title.
              title: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('A',style: TextStyle(fontSize: 30, color: Colors.teal[200], fontWeight: FontWeight.bold),),
                  Padding(padding: EdgeInsets.fromLTRB(0, 0, 0, 2),
                    child: Text('dministrator', style: TextStyle(fontSize: 20, color: Colors.teal[200],),),)
                ],
              ),
              bottom: TabBar(
                controller: _tabController,
                isScrollable: true,
                unselectedLabelColor: Colors.white.withOpacity(0.3),
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
            floatingActionButton: _buildFloatingActionButton()
          )
      );
    }
  }

  Widget? _buildFloatingActionButton(){
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
    else if(_selectedTabIdx == _branchList.length + 1){
      return FloatingActionButton(
        backgroundColor: Colors.redAccent[100],
        child: Icon(Icons.save, color: Colors.white,),
        onPressed: (){
          _listStreamController[_selectedTabIdx].add(0);


          Navigator.pop(context);
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
           labelBackgroundColor: Colors.black12,
           child: Icon(Icons.download, color: Colors.white),
           label: '엑셀 다운로드',
           labelStyle: TextStyle(color: Colors.white70),
           onTap: () {
             _listStreamController[_selectedTabIdx].add(0);
           }
         ),
         SpeedDialChild(
           child: Icon(Icons.notification_important_outlined, color: Colors.white,),
           backgroundColor: Colors.redAccent[100],
           labelBackgroundColor: Colors.black12,
           labelShadow: [BoxShadow(color: Colors.black12), BoxShadow(color: Colors.black12)],
           label : '공지사항',
           labelStyle: TextStyle(color: Colors.white70),
           onTap: (){
             _listNoticeEditController[_selectedTabIdx - 1].text = _listNoticeBranch[_selectedTabIdx - 1];
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
                         controller: _listNoticeEditController[_selectedTabIdx - 1],
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
                                     _listNoticeBranch[_selectedTabIdx - 1] = _listNoticeEditController[_selectedTabIdx - 1].text;
                                     BranchDatabase.addItem(companyId: _companyName, branch: _branchList[_selectedTabIdx - 1], key: 'notice', value: _listNoticeEditController[_selectedTabIdx - 1].text);
                                     _listStreamController[_selectedTabIdx].add(1);
                                   }
                                   else{
                                     for(int i = 0; i < _branchList.length; i++){
                                       _listNoticeBranch[i] = _listNoticeEditController[_selectedTabIdx - 1].text;
                                       BranchDatabase.addItem(companyId: _companyName, branch: _branchList[i], key: 'notice', value: _listNoticeEditController[_selectedTabIdx - 1].text);
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
           labelBackgroundColor: Colors.black12,
           labelShadow: [BoxShadow(color: Colors.black12), BoxShadow(color: Colors.black12)],
           label: '체크리스트',
           labelStyle: TextStyle(color: Colors.white70),
           onTap: (){
             String branch = _branchList[_selectedTabIdx - 1];

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
                                if(_checklistToAll){
                                  _branchList.forEach((br) {
                                    _updateBranchChecklistDatabase(br);
                                  });
                                }
                                else{
                                  _updateBranchChecklistDatabase(branch);
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
           labelBackgroundColor: Colors.black12,
           labelShadow: [BoxShadow(color: Colors.black12), BoxShadow(color: Colors.black12)],
           label: '업무일지 양식',
           labelStyle: TextStyle(color: Colors.white70),
           onTap: (){
             _listDiaryFormatEditController[_selectedTabIdx - 1].text = _listDiaryFormatBranch[_selectedTabIdx - 1];
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
                         controller: _listDiaryFormatEditController[_selectedTabIdx - 1],
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
                             _listDiaryFormatEditController[_selectedTabIdx - 1].text = "";
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
                                     _listDiaryFormatBranch[_selectedTabIdx - 1] = _listDiaryFormatEditController[_selectedTabIdx - 1].text;
                                     BranchDatabase.addItem(companyId: _companyName, branch: _branchList[_selectedTabIdx - 1], key: 'diaryFormat', value: _listDiaryFormatEditController[_selectedTabIdx - 1].text);
                                   }
                                   else{
                                     for(int i = 0; i < _branchList.length; i++){
                                       _listDiaryFormatBranch[i] = _listDiaryFormatEditController[_selectedTabIdx - 1].text;
                                       BranchDatabase.addItem(companyId: _companyName, branch: _branchList[i], key: 'diaryFormat', value: _listDiaryFormatEditController[_selectedTabIdx - 1].text);
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
  _updateBranchChecklistDatabase(String br, ){
    for(int i = 0; i < (_listCheckListBranch[br]!).length; i++){
      BranchDatabase.deleteCheckListItem(companyId: _companyName, branch: br, checkId: i);
    }

    for(int i = 0; i < curCheckList.length; i++){
      BranchDatabase.addCheckItem(companyId: _companyName, branch: br, checkId: i, key: 'name', value: curCheckList[i].name);
      BranchDatabase.addCheckItem(companyId: _companyName, branch: br, checkId: i, key: 'writetime', value: DateFormat('yyyy-MM-dd').format(curCheckList[i].writetime));
      curCheckList[i].checked.forEach((key, value) {
        BranchDatabase.addCheckItem(companyId: _companyName, branch: br, checkId: i, key: DateFormat('yyyy-MM-dd').format(key), value: value ? "true" : "false");
      });

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
  BranchEditPage({required this.company, required this.branchList, required this.stream, required this.adminPassword});

  final String company;
  final List<String> branchList;
  final Stream stream;
  final String adminPassword;
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

  @override
  bool get wantKeepAlive => true;

  @override
  initState(){
    super.initState();
    _branchList = widget.branchList;

    _companyName = widget.company;

    _branchList.forEach((element) {
      TextEditingController newEditor = TextEditingController();
      newEditor.text = element;
      _branchEditControls.add(newEditor);
      _branchListOrg.add(element);
    });

    widget.stream.listen((event) {
      if(event is int){
        if(event == 0){
          if(_passwordOld.length > 0 && _passwordNew.length > 0){
            setState((){
              if(widget.adminPassword == _passwordOld){
                UserDatabase.addAdminUserItem(companyId: _companyName,userUid: 'Administrator', key: 'password', value: _passwordNew);
                Fluttertoast.showToast(msg: '비밀번호가 변경되었습니다.!', timeInSecForIosWeb: 5);
                //Navigator.pop(context, 'Ok');
              }
              else{
                Fluttertoast.showToast(msg: 'Wrong old password!', timeInSecForIosWeb: 5);
              }
            });
          }
          _saveBranchList();

        }
      }
    });
  }

  Widget build(BuildContext context){
    return branchEditTabview();
  }

  _saveBranchList(){
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
    }

  }


  Widget branchEditTabview(){
    return GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus;
        },
        child : getBranchList()
    );
  }


  Widget getBranchList(){
    return ListView.builder(itemCount: _branchList.length + 2,
        controller: _scrollController,
        itemBuilder: (BuildContext context, int index){
      if(index == 0){
        return Column(
          children: [
            Padding(
                padding: EdgeInsets.only(
                    left: 10, top: 20, bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(Icons.password, color: Colors.white,
                      size: 22,),
                    Text(' 비밀번호 변경',
                      style: TextStyle(
                        fontSize: 17, color: Colors.white,),
                      textAlign: TextAlign.center,),
                  ],
                )
            ),
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


            Divider(color: Colors.white38,
                thickness: 1,
                height: 40),
            Padding(
                padding: EdgeInsets.only(
                    left: 10, top: 0, bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(Icons.account_tree_outlined, color: Colors.white,
                      size: 22,),
                    Text(' 사업장 리스트',
                      style: TextStyle(
                        fontSize: 17, color: Colors.white,),
                      textAlign: TextAlign.center,),
                  ],
                )
            ),
          ],
        );
      }
          else if(index == _branchList.length + 1){
            return TextButton(
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
                  margin: EdgeInsets.only(bottom: 30),
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
            );
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
  BranchPage({required this.company, required this.branch, required this.stream });
  final String company;
  final String branch;
  final Stream<int> stream;

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

  TextEditingController _payEditingController = TextEditingController();
  @override
  bool get wantKeepAlive => true;

  @override
  initState() {
    super.initState();
    _companyName = widget.company;
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
  }


  Widget build(BuildContext context) {
    return getUserList();
  }


  getWorkerList(String branch){
    final double _lowestPay = 9160;
    double payHour = _lowestPay;
    UserDatabase.getItemCollection(companyId: _companyName, userUid: 'Administrator').get().then((QuerySnapshot querySnapshot) {
      for(int i = 0; i < querySnapshot.docs.length; i++){
        var doc = querySnapshot.docs[i];
        if (doc.id != 'Administrator') {
          if (branch != null) {
            if (doc['workPlace'] == "[" + branch + "]") {
              try {
                if (doc['pay'] != null) {
                  payHour = double.parse((doc['pay']));
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
      color: Colors.black26,
      child:  Column(
        children: <Widget>[
          Container(
            alignment: Alignment.centerLeft,
            child: totalPayLatest(),
          ),
          Expanded(child: ListView.separated(itemCount: workerList.length + 1,
              separatorBuilder: (BuildContext context, int index) {
                return Divider(height: 10.0, color: Colors.white.withOpacity(0.24),thickness: 1,);

              },
              itemBuilder: (BuildContext context, int index){
                if(index == workerList.length){
                  return ListTile(

                  );
                }
                else{
                  return getWorkerTile(index);
                }
              })
          ),
        ],
      ),
    );
  }

  Widget totalPayLatest(){
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
        title:Text(workerList[index].name,style: TextStyle(color: Colors.teal[200], fontWeight: FontWeight.bold), textAlign: TextAlign.left),
        subtitle : Text(workerList[index].getUserInfoPrint(),style: TextStyle(color: Colors.white70),),
        trailing: IconButton(
          color: Colors.white70,
          onPressed: (){
            _payEditingController.text = (workerList[index].payHour).toString();
            showDialog<String>(
              context: context,
              builder: (BuildContext context) => AlertDialog(
                backgroundColor: Color(0xFF333A47),
                title: Row(
                  children: [
                    const Expanded(
                      child: Text('User Info', style: TextStyle(color: Colors.white70),),
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
                        inputFormatters: <TextInputFormatter>[FilteringTextInputFormatter.digitsOnly],
                        onChanged: (value) {
                          _payPerHourInput = value;
                        },

                        decoration: const InputDecoration(
                            border: OutlineInputBorder(borderSide: BorderSide(color: Colors.white70)),
                            enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white70)),
                            labelText: '시급',
                            labelStyle: TextStyle(color: Colors.white70)
                        ),
                        controller: _payEditingController,
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
          icon: Icon(Icons.more_vert),
        )
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
        for(int a = gridRowOffset; a < gridRowOffset + 31; a++) {
          var cell = sheet.getRangeByIndex(a + 1, 1);
          cell.setNumber(d);
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

          cell = sheet.getRangeByIndex(33 + gridRowOffset, 1);
          cell.setText("시급");

          cell = sheet.getRangeByIndex(34 + gridRowOffset, 1);
          cell.setText("급여");

          cell = sheet.getRangeByIndex(35 + gridRowOffset, 1);
          cell.setText("급여 3.3%");

          cell = sheet.getRangeByIndex(36 + gridRowOffset, 1);
          cell.setText("총급여");
          cell.cellStyle = globalStyle;

          cell = sheet.getRangeByIndex(37 + gridRowOffset, 1);
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

          cell = sheet.getRangeByIndex(34 + gridRowOffset, userCnt + 1);
          sumFormula = '=PRODUCT(' + sheet.getRangeByIndex(32 + gridRowOffset, userCnt + 1).addressLocal + ',' + sheet.getRangeByIndex(33 + gridRowOffset, userCnt + 1).addressLocal + ')';
          cell.setFormula(sumFormula);
          cell.numberFormat = '(\$#,##0.00)';

          cell = sheet.getRangeByIndex(35 + gridRowOffset, userCnt + 1);
          sumFormula = '=PRODUCT(' + sheet.getRangeByIndex(34 + gridRowOffset, userCnt + 1).addressLocal + ',96.7) / 100';
          cell.setFormula(sumFormula);


        });
        sheet.getRangeByIndex(gridRowOffset,1,35 + gridRowOffset, userCnt + 1).cellStyle = globalStyle;

        String sumStartCell = sheet.getRangeByIndex(34 + gridRowOffset, 2).addressLocal;
        String sumEndCell = sheet.getRangeByIndex(34 + gridRowOffset, userCnt + 1).addressLocal;
        cell = sheet.getRangeByIndex(36 + gridRowOffset, 2);
        String sumFormula = '=SUM(' + sumStartCell + ':' + sumEndCell + ')';
        cell.setFormula(sumFormula);
        cell.cellStyle = globalStyle;

        sumStartCell = sheet.getRangeByIndex(35 + gridRowOffset, 2).addressLocal;
        sumEndCell = sheet.getRangeByIndex(35 + gridRowOffset, userCnt + 1).addressLocal;
        cell = sheet.getRangeByIndex(37 + gridRowOffset, 2);
        sumFormula = '=SUM(' + sumStartCell + ':' + sumEndCell + ')';
        cell.setFormula(sumFormula);
        cell.cellStyle = globalStyle;

        cell = sheet.getRangeByIndex(39 + gridRowOffset, 1);
        cell.setText("지출현황");
        cell.cellStyle = globalStyle;

        for(int i = 0; i < expenseType.length; i++) {
          cell = sheet.getRangeByIndex(40 + gridRowOffset, 1 + i);
          cell.setText(expenseType[i]);
          cell.cellStyle = globalStyle;
        }
        cell = sheet.getRangeByIndex(40 + gridRowOffset, 1 + expenseType.length);
        cell.setText('합계');
        cell.cellStyle = globalStyle;

        cell = sheet.getRangeByIndex(41 + gridRowOffset, 1 + expenseType.length);
        sumStartCell = sheet.getRangeByIndex(41 + gridRowOffset, 1).addressLocal;
        sumEndCell = sheet.getRangeByIndex(41 + gridRowOffset, expenseType.length).addressLocal;
        sumFormula = '=SUM(' + sumStartCell + ':' + sumEndCell + ')';
        cell.setFormula(sumFormula);
        cell.cellStyle = globalStyle;

        cell = sheet.getRangeByIndex(43 + gridRowOffset, 1);
        cell.setText("지출내역");
        cell.cellStyle = globalStyle;

        cell = sheet.getRangeByIndex(44 + gridRowOffset, 1);
        cell.setText("일자");
        cell.cellStyle = globalStyle;

        cell = sheet.getRangeByIndex(44 + gridRowOffset, 2);
        cell.setText("담당자");
        cell.cellStyle = globalStyle;

        cell = sheet.getRangeByIndex(44 + gridRowOffset, 3);
        cell.setText("지출유형");
        cell.cellStyle = globalStyle;

        cell = sheet.getRangeByIndex(44 + gridRowOffset, 4);
        cell.setText("금액");
        cell.cellStyle = globalStyle;

        cell = sheet.getRangeByIndex(44 + gridRowOffset, 5);
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
            var cell = sheet.getRangeByIndex(45 + exIdx + gridRowOffset, 1);
            cell.setNumber(exInfo.date!.day.toDouble());
            cell.cellStyle = globalStyle;

            cell = sheet.getRangeByIndex(45 + exIdx + gridRowOffset, 2);
            cell.setText(exInfo.user);
            cell.cellStyle = globalStyle;

            cell = sheet.getRangeByIndex(45 + exIdx + gridRowOffset, 3);
            cell.setText(exInfo.type);
            cell.cellStyle = globalStyle;

            if(exInfo.money!= null && exInfo.money!.length > 0){
              double m = double.parse(exInfo.money!.replaceAll(',', ''));
              if(m != null){
                cell = sheet.getRangeByIndex(45 + exIdx + gridRowOffset, 4);
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
            cell = sheet.getRangeByIndex(45 + exIdx + gridRowOffset, 4);
            cell.cellStyle = globalStyle;

            cell = sheet.getRangeByIndex(45 + exIdx + gridRowOffset, 5);
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
            var cell = sheet.getRangeByIndex(41 + gridRowOffset, 1 + i);
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
  late Map<DateTime, List<ExpenseItem>?> expenseListMap = {};
  late List<double> latestPayMonth = [0,0];
  late List<double> totalDuration = [0,0];
  final void Function(workerData)? onComplete;
  final void Function(workerData, DateTime, List<ExpenseItem>)? onExpenseReadComplete;


  workerData({required this.name,required this.payHour,required this.company, required this.workPlace, required this.onComplete, required this.onExpenseReadComplete}){
  }

  Future<void> getWorkInfo() async{
    DateTime latestMon = DateTime(DateTime.now().year, DateTime.now().month);
    DateTime previousMon;
    if(DateTime.now().month == 1){
      previousMon = DateTime(DateTime.now().year - 1, 12);
    }
    else{
      previousMon = DateTime(DateTime.now().year, DateTime.now().month - 1);
    }
    //QuerySnapshot querySnapshot = await UserDatabase.getItemCollection(companyId: company, userUid: getUserId()).get();
    UserDatabase.getItemCollection(companyId: company, userUid: getUserId()).get().then((QuerySnapshot querySnapshot) {
      for(int i = 0; i < querySnapshot.docs.length; i++){
        var doc = querySnapshot.docs[i];
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

        DateTime date = DateFormat('yyyy-MM-dd').parse(doc.id);
        double duration = double.parse(dateInfo['duration']??'0');

        if(duration > 0){
          durationMap[date] = duration;
        }

        getListExpenseUser(date).then((value) {
          expenseListMap[date] = value;
          onExpenseReadComplete!(this, date, value);
        });
      }
      onComplete!(this);
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