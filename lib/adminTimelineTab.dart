import 'dart:convert';
import 'dart:developer';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:work_inout/user_database.dart';
import 'branch_database.dart';
import 'package:syncfusion_flutter_xlsio/xlsio.dart' as xlsio;
import 'package:loading_indicator/loading_indicator.dart';
import 'timelineScreen.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'checklist.dart';

class BranchTimelinePage extends StatefulWidget{
  const BranchTimelinePage({required this.companyName, required this.branchList, required this.scrollController});

  final String companyName;
  final List<String> branchList;
  final ScrollController scrollController;
  @override
  State<StatefulWidget> createState() => BranchTimelinePageState();


}

class BranchTimelinePageState extends State<BranchTimelinePage> with AutomaticKeepAliveClientMixin {
  late Map<DateTime, List<DiaryItem>> _maplistDiary = {};
  late Map<DateTime, Map<String, String>> _DailyBranch = {};
  late Map<DateTime, Map<String, String>> _DailyBranchExpense = {};
  late bool initDone = false;
  late int initDone2ndCnt = 0;
  late int initUserCnt = 0;
  late int userCnt = 0;
  late int readCnt = 0;
  late int readTotalCnt = 0;
  late ScrollController _scrollController = widget.scrollController;
  late Map<String, List<CheckListItem>> _listCheckListBranch = {};

  late Map<DateTime, DiaryContent> _listDairyContent = {};
  late DateTime? _currentDate = null;

  late Map<DateTime, GlobalKey> globalKeys = {};
  late var sortedKeys;
  late double prevScrollOffset = 0;
  late double nextScrollOffset = 0;
  late List<DateTime> days = [];
  late List<String> userIdList = [];
  late Map<String, bool> filterBranch = {};
  late Map<String, bool> filterType = {};
  late bool filterBranchAll = true;
  late bool filterTypeAll = true;

  late Map<String, bool> filterBranchView = {};
  late Map<String, bool> filterTypeView = {};
  late bool filterBranchAllView = true;
  late bool filterTypeAllView = true;
  late Map<DateTime, int> nothingToShow = {};


  @override
  bool get wantKeepAlive => true;

  final List<String> diaryType = ['근무현황','지출현황','체크리스트','업무일지'];

  @override
  initState() {
    super.initState();

    for (int i = 0; i < 10; i++) {
      days.add(DateTime(DateTime
          .now()
          .year, DateTime
          .now()
          .month, DateTime
          .now()
          .day).subtract(Duration(days: i)));
    }

    widget.branchList.forEach((element) {
      filterBranchView[element] = true;
    });

    diaryType.forEach((element) {
      filterTypeView[element] = true;
    });


    UserDatabase.getItemCollection(
        companyId: widget.companyName, userUid: 'Administrator').get().then((
        QuerySnapshot querySnapshot) {
      setState(() {
        userCnt = querySnapshot.docs.length;
        readTotalCnt = userCnt * 10 * 2;
      });
      querySnapshot.docs.forEach((doc) {
        setState((){
          userIdList.add(doc.id);
        });
      });
      days.forEach((date) {
        getDiaryInfo(date);
      });

      setState(() {
        initDone = true;
      });
    });

    widget.branchList.forEach((branch) {
      BranchDatabase.getBranchCheckListCollection(
          companyId: widget.companyName, branch: branch).get().then((
          QuerySnapshot querySnapshot2) {
        List<CheckListItem> checkList = [];
        for (int i = 0; i < querySnapshot2.docs.length; i++) {
          var data = querySnapshot2.docs[i].data()! as Map<String, dynamic>;
          String title = "";
          DateTime writetime = DateTime.now();
          Map<DateTime, bool> checked = {};
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
                  checked[date] = value == "true" ? true : false;
              }
            }
          });
          setState(() {
            checkList.add(CheckListItem(
                name: title, writetime: writetime, checked: checked));
          });
        }
        String br = branch;
        Map<DateTime, int> checklistStat = {};
        Map<DateTime, List<String>> doneList = {};
        Map<DateTime, List<String>> yetList = {};
        checkList.forEach((element) {
          element.checked.forEach((key2, value2) {
            if (value2) {
              if (checklistStat[key2] == null) {
                checklistStat[key2] = 0;
              }
              checklistStat[key2] = (checklistStat[key2] ?? 0) + 1;
              if (doneList[key2] == null) {
                doneList[key2] = [];
              }
              doneList[key2]!.add(element.name);
            }
            else {
              if (yetList[key2] == null) {
                yetList[key2] = [];
              }
              yetList[key2]!.add(element.name);
            }
          });
        });

        checklistStat.forEach((key3, value3) {
          String diaryText = '';
          if (doneList[key3] != null) {
            for (int i = 0; i < doneList[key3]!.length; i++) {
              if (i != 0) {
                diaryText += '\n';
              }
              diaryText += '  v ' + doneList[key3]![i];
            }
          }

          if (yetList[key3] != null) {
            for (int i = 0; i < yetList[key3]!.length; i++) {
              if (i != 0) {
                diaryText += '\n';
              }
              diaryText += '     ' + yetList[key3]![i];
            }
          }

          setState(() {
            if (_listDairyContent[key3] == null)
              _listDairyContent[key3] = DiaryContent();
            if (value3 == checkList.length) {
              if (_listDairyContent[key3]!.mapBranchCheckListDone[branch] ==
                  null) {
                _listDairyContent[key3]!.mapBranchCheckListDone[branch] = "";
              }
              _listDairyContent[key3]!.mapBranchCheckListDone[branch] =
                  diaryText;
            }
            else {
              if (_listDairyContent[key3]!.mapBranchCheckListYet[branch] ==
                  null) {
                _listDairyContent[key3]!.mapBranchCheckListYet[branch] = "";
              }
              _listDairyContent[key3]!.mapBranchCheckListYet[branch] =
                  diaryText;
            }
          });
        });

        setState(() {
          initDone2ndCnt++;
        });
      });
    });

    _scrollController.addListener(() {
      if(((_scrollController.offset - 11 < prevScrollOffset) || (_scrollController.offset > nextScrollOffset)) && readCnt == readTotalCnt){
        double height = 0;
        for(int i = 0; i < days.length ; i++){
          var date = days[i];
          if(globalKeys[date] != null && globalKeys[date]!.currentContext != null){
            RenderBox? box = globalKeys[date]!.currentContext!.findRenderObject() as RenderBox;
            if(box != null) {
              if(_scrollController.offset >= height){
                setState((){
                  _currentDate = date;
                });
              }
              else{
                setState((){
                  if(i > 0){
                    var tempDate = days[i - 1];
                    if(globalKeys[tempDate] != null && globalKeys[tempDate]!.currentContext != null) {
                      RenderBox? box = globalKeys[tempDate]!.currentContext!
                          .findRenderObject() as RenderBox;
                      if (box != null) {
                        prevScrollOffset = height - box.size.height;
                        if(prevScrollOffset < 0){
                          prevScrollOffset = 0;
                        }
                      }
                    }
                  }
                  else{
                    prevScrollOffset = 0;
                  }

                  nextScrollOffset = height;
                });
                break;
              }
              height += box.size.height;
            }
          }
        }
        //print('offset = ${_scrollController.offset} , height = ${height}');
      }

      if(_scrollController.position.pixels == _scrollController.position.maxScrollExtent && readCnt == readTotalCnt && days.length < 100){
        setState((){
          readCnt = 0;
        });

        DateTime lastdate = days[days.length - 1];
        for (int i = 1; i <= 10; i++) {
          setState((){
            DateTime addDate = lastdate.subtract(Duration(days: i));
            days.add(addDate);
            getDiaryInfo(addDate);
          });
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if(initDone){
      return Container(
          color: Colors.black38,
          child: Stack(
            children: [
              SingleChildScrollView(
                controller: _scrollController,
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const ClampingScrollPhysics(),
                  itemCount: days.length,
                  itemBuilder: (BuildContext context, int index) {
                    //DateTime date = sortedKeys.elementAt(index);
                    return buildDiaryContent(days[index]);
                  },

                  separatorBuilder: (BuildContext context, int index) {
                    if (IsSomethingShow(days[index]) && _listDairyContent[days[index]] != null) {
                      return Divider(height: 5.0,
                          color: Colors.white12,
                          thickness: 8);
                    }
                    else{
                      return Container();
                    }

                  },
                ),
              ),
              if(_currentDate != null) Container(
                  child: Container(
                      color: Color(0xFF333A47),
                      child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              height: 45,
                              color: Colors.black38,
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      Text('  ' + DateFormat('yyyy-MM-dd').format(_currentDate!) + ' ',
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold),
                                      ),
                                      Text(DateFormat('E', 'ko_KR').format(_currentDate!),
                                        style: TextStyle(
                                            color: DateFormat('E', 'ko_KR')
                                                .format(_currentDate!) == '토' ||
                                                DateFormat('E', 'ko_KR').format(
                                                    _currentDate!) == '일' ? Colors
                                                .redAccent[100] : Colors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold
                                        ),
                                      ),
                                    ],
                                  ),
                                  IconButton(
                                    onPressed: (){
                                      setState((){
                                        filterBranchAll = filterBranchAllView;
                                        filterTypeAll = filterTypeAllView;
                                        filterType = {};
                                        filterBranch = {};
                                        filterTypeView.forEach((key, value) {
                                          filterType[key] = value;
                                        });
                                        filterBranchView.forEach((key, value) {
                                          filterBranch[key] = value;
                                        });
                                      });
                                      showDialog<String>(
                                        context: context,
                                        builder: (BuildContext context) {
                                          return StatefulBuilder(builder: (context, _setState){
                                            return AlertDialog(
                                              backgroundColor: Color(0xFF333A47),
                                              title: Text('필터', style: TextStyle(color: Colors.white)),
                                              content:
                                              Container(
                                                  height: MediaQuery.of(context).size.height - 300,
                                                  width: MediaQuery.of(context).size.width - 100,
                                                  child:
                                                  SingleChildScrollView(
                                                    child: Column(
                                                      children: [
                                                        Row(
                                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                          children: [
                                                            Text('사업장', style: TextStyle(color: Colors.white, fontSize: 16),),
                                                            Row(
                                                              children: [
                                                                Text('전체', style: TextStyle(color: Colors.white70, fontSize: 14),),
                                                                Switch(value: filterBranchAll, onChanged: (value){
                                                                  _setState((){
                                                                    filterBranchAll = value;
                                                                    filterBranch.forEach((key, value) {
                                                                      filterBranch[key] = filterBranchAll;
                                                                    });
                                                                  });
                                                                })
                                                              ],
                                                            )
                                                          ],
                                                        ),
                                                        ListView.builder(
                                                          shrinkWrap: true,
                                                          physics: const ClampingScrollPhysics(),
                                                          itemCount: widget.branchList.length,
                                                          itemBuilder: (BuildContext context, index){
                                                            return Theme(
                                                              data: ThemeData(unselectedWidgetColor: Colors.white70, scrollbarTheme: ScrollbarThemeData(isAlwaysShown: true )),
                                                              child: SizedBox(
                                                                height: 40,
                                                                child: CheckboxListTile(
                                                                    value: filterBranch[widget.branchList[index]],
                                                                    activeColor: Colors.transparent,
                                                                    checkColor: Colors.white,
                                                                    controlAffinity: ListTileControlAffinity.leading,
                                                                    checkboxShape: RoundedRectangleBorder(
                                                                      borderRadius: BorderRadius.circular(3),
                                                                      side: BorderSide(color: Colors.white70),
                                                                    ),
                                                                    title: Text(widget.branchList[index], style: TextStyle(color: Colors.white70)),
                                                                    onChanged: (value){
                                                                      _setState((){
                                                                        filterBranch[widget.branchList[index]] = value!;
                                                                        if(value == false){
                                                                          filterBranchAll = value;
                                                                        }
                                                                      });
                                                                    }),
                                                              )
                                                            );
                                                          },
                                                        ),
                                                        Row(
                                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                          children: [
                                                            Text('카테고리', style: TextStyle(color: Colors.white, fontSize: 16)),
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
                                                      ],
                                                    ),
                                                  )
                                              ),
                                              actions: <Widget>[
                                                TextButton(
                                                  onPressed:
                                                  (() {
                                                    _setState((){
                                                      filterBranchAllView = filterBranchAll;
                                                      filterTypeAllView = filterTypeAll;
                                                      filterType.forEach((key, value) {
                                                        if(value == false){
                                                          filterTypeAllView = false;
                                                        }
                                                        filterTypeView[key] = value;
                                                      });
                                                      filterBranch.forEach((key, value) {
                                                        if(value == false){
                                                          filterBranchAllView = false;
                                                        }
                                                        filterBranchView[key] = value;
                                                      });

                                                      _currentDate = days[days.length - 1];
                                                      _listDairyContent.forEach((date, value) {
                                                        if(filterTypeView['근무현황'] != null && filterTypeView['근무현황']!) {
                                                          value
                                                              .mapBranchUserTime
                                                              .keys.forEach((
                                                              element) {
                                                            if (filterBranchView[element] ==
                                                                true) {
                                                              if (_currentDate ==
                                                                  null) {
                                                                setState(() {
                                                                  _currentDate =
                                                                      date;
                                                                });
                                                              }
                                                              else {
                                                                if (_currentDate!
                                                                    .isBefore(
                                                                    date)) {
                                                                  setState(() {
                                                                    _currentDate =
                                                                        date;
                                                                  });
                                                                }
                                                              }
                                                            }
                                                          });
                                                        }
                                                        if(filterTypeView['지출현황'] != null && filterTypeView['지출현황']!) {
                                                          value
                                                              .mapBranchUserExpense
                                                              .keys.forEach((
                                                              element) {
                                                            if (filterBranchView[element] ==
                                                                true) {
                                                              if (_currentDate ==
                                                                  null) {
                                                                setState(() {
                                                                  _currentDate =
                                                                      date;
                                                                });
                                                              }
                                                              else {
                                                                if (_currentDate!
                                                                    .isBefore(
                                                                    date)) {
                                                                  setState(() {
                                                                    _currentDate =
                                                                        date;
                                                                  });
                                                                }
                                                              }
                                                            }
                                                          });
                                                        }
                                                      });
                                                    });
                                                    setState((){

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
                                    icon: (filterTypeAllView && filterBranchAllView) ? Icon(Icons.filter_alt) : Icon(Icons.filter_alt_outlined),
                                  )
                                ],
                              ),
                            ),
                            Divider(height: 1.0,
                              color: Color(0xFF333A47),
                              thickness: 1,),
                          ]
                      )
                  )
              ),
              if(readCnt != readTotalCnt) Center(
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
            ],
          )
      );
    }
    else{
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
  }

  Future<void> getDiaryInfo(DateTime date) async{
    String dateDB = DateFormat('yyyy-MM-dd').format(date);

    userIdList.forEach((user) {
      String name = "";
      String branch = "";
      List<String> userInfo = user.split('-');
      if (userInfo.length >= 2) {
        name = userInfo[0].trimRight();
        branch = userInfo[1].trimRight();
        branch = branch.substring(2, branch.length - 1);
      }

      UserDatabase.getItemCollection(
        companyId: widget.companyName, userUid: user).doc(dateDB).get().then((doc2){
          if(doc2.exists){
            var dateInfo = doc2.data()! as Map<String, dynamic>;
            if(_currentDate == null){
              setState((){
                _currentDate = date;
              });
            }
            else{
              if(_currentDate!.isBefore(date)){
                setState((){
                  _currentDate = date;
                });
              }
            }

            if (dateInfo != null) {
              String text = "";
              String start = "";
              String end = "";
              String duration = "";
              String rest = "";

              if(globalKeys[date] == null){
                setState((){
                  globalKeys[date] = GlobalKey();
                  sortedKeys = globalKeys.keys.toList()..sort();
                });
              }

              dateInfo.forEach((key, value) {
                if (key == 'start') {
                  if (value != null && value.length > 0) {
                    start = value;
                  }
                }
                else if (key == 'end') {
                  if (value != null && value.length > 0) {
                    end = value;
                  }
                }
                else if (key == 'duration') {
                  if (value != null && value.length > 0) {
                    duration = value;
                  }
                }
                else if (key == 'rest') {
                  if (value != null && value.length > 0) {
                    rest = value;
                  }
                }
                else if (key == 'text') {
                  if (value != null && value.length > 0) {
                    text = value;
                  }
                }
              });

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
                  if (_listDairyContent[date] == null)
                    _listDairyContent[date] = DiaryContent();
                  if (_listDairyContent[date]!.mapBranchUserTime[branch] == null) {
                    _listDairyContent[date]!.mapBranchUserTime[branch] = {};
                  }
                  _listDairyContent[date]!.mapBranchUserTime[branch]![name] = ('근무 ' + dur + '시간/' + start + ' ~ ' + end);
                });
              }

              if (name.length > 0 && branch.length > 0 && text.length > 0) {
                setState(() {
                  if (_listDairyContent[date] == null)
                    _listDairyContent[date] = DiaryContent();
                  if (_listDairyContent[date]!.mapBranchUserDiary[branch] ==
                      null) {
                    _listDairyContent[date]!.mapBranchUserDiary[branch] = {};
                  }
                  _listDairyContent[date]!.mapBranchUserDiary[branch]![name] =
                      text;
                });
              }
            }
          }
          setState((){
            readCnt++;
          });
      },);
      UserDatabase
          .getExpenseItemCollection(
          companyId: widget.companyName, userUid: user, date: dateDB)
          .get().then((QuerySnapshot querySnapshot3) {
        querySnapshot3.docs.forEach((doc3) {
          var expenseInfo = doc3.data()! as Map<String, dynamic>;
          var expenseItem = ExpenseItem();
          String expenseStr = '';
          expenseInfo.forEach((key, value) {
            if (key == 'type') {
              expenseItem.type = value;
            }
            else if (key == 'money') {
              expenseItem.money = value;
            }
            else if (key == 'detail') {
              expenseItem.detail = value;
            }
          });
          setState(() {
            if (_listDairyContent[date] == null)
              _listDairyContent[date] = DiaryContent();
            if (_listDairyContent[date]!.mapBranchUserExpense[branch] ==
                null) {
              _listDairyContent[date]!.mapBranchUserExpense[branch] = {};
            }
            if (_listDairyContent[date]!
                .mapBranchUserExpense[branch]![name] == null) {
              _listDairyContent[date]!
                  .mapBranchUserExpense[branch]![name] = [];
            }
            _listDairyContent[date]!.mapBranchUserExpense[branch]![name]!
                .add(expenseItem);
          });
        });
        setState((){
          readCnt++;
        });
      });
    });

  }

  Widget buildDiaryHeader(IconData iconData, String tag) {
    return Container(
      margin: EdgeInsets.only(bottom: 5),
      child:
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Divider(height: 1.0,
            color: Color(0xFF333A47),
            thickness: 1,),
          Container(
            margin: EdgeInsets.only(top: 5),
            padding: EdgeInsets.only(left: 5, right: 5),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                  color: Colors.transparent
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(iconData, size: 18, color: Colors.white70,),
                Text(tag,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: Colors.white70,
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

    if(_listDairyContent[date] != null){
      if(filterTypeView['근무현황'] != null && filterTypeView['근무현황']!){
        _listDairyContent[date]!.mapBranchUserTime.keys.forEach((element) {
          if(filterBranchView[element] == true){
            ret = true;
          }
        });
      }

      if(filterTypeView['지출현황'] != null && filterTypeView['지출현황']!) {
        _listDairyContent[date]!.mapBranchUserExpense.keys.forEach((element) {
          if (filterBranchView[element] == true) {
            ret = true;
          }
        });
      }
    }
    return ret;
  }

  Widget buildDiaryContent(DateTime date) {
    if (_listDairyContent[date] != null) {
      return Container(
        key: globalKeys[date],
        child: (!IsSomethingShow(date)) ? Container() : Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 45,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text('  ' +
                      DateFormat('yyyy-MM-dd').format(date) +
                      ' ',
                    style: TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                        fontWeight: FontWeight.bold)
                    ,),
                  Text(DateFormat('E', 'ko_KR').format(date),
                    style: TextStyle(
                        color: DateFormat('E', 'ko_KR')
                            .format(date) == '토' ||
                            DateFormat('E', 'ko_KR').format(
                                date) == '일' ? Colors
                            .redAccent[100] : Colors.white70,
                        fontSize: 16,
                        fontWeight: FontWeight.bold
                    )
                    ,),
                ],
              ),
            ),

            if(filterTypeView['근무현황']! &&  _listDairyContent[date]!.mapBranchUserTime != null &&
                _listDairyContent[date]!.mapBranchUserTime.length > 0)
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  buildDiaryHeader(
                      Icons.access_time, ' 근무현황'),
                  Container(
                    child: ListView.builder(
                      shrinkWrap: true,
                      padding: EdgeInsets.fromLTRB(5, 5, 0, 5),
                      physics: const ClampingScrollPhysics(),
                      itemCount: _listDairyContent[date]!.mapBranchUserTime.keys.length,
                      itemBuilder: (BuildContext context, int index) {
                        var sortedKeys = _listDairyContent[date]!.mapBranchUserTime.keys.toList()..sort();
                        String branch = sortedKeys.elementAt(index);
                        if(filterBranchView[branch] != null && filterBranchView[branch]!){
                          return Container(
                            child: ListView.builder(
                                padding: EdgeInsets.fromLTRB(0, 0, 0, 10),
                                shrinkWrap: true,
                                physics: const ClampingScrollPhysics(),
                                itemCount: _listDairyContent[date]!.mapBranchUserTime[branch]!.keys.length + 1,
                                itemBuilder:(BuildContext context, int index){
                                  if(index == 0){
                                    return Container(
                                      padding: EdgeInsets.only(bottom: 3),
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.center,
                                        children: [
                                          Icon(Icons.place_outlined, color: Colors.teal[200], size: 18,),
                                          Text(' ' + branch, style: TextStyle(
                                            color: Colors.teal[200],
                                            fontSize: 15,
                                          ),
                                              textAlign: TextAlign.left),
                                        ],
                                      ),
                                    );
                                  }
                                  String user = _listDairyContent[date]!.mapBranchUserTime[branch]!.keys.toList().elementAt(index - 1);
                                  String timeStr = _listDairyContent[date]!.mapBranchUserTime[branch]![user]!;

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
                                          width: 90,
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
                          );
                        }
                        else{
                          return Container();
                        }

                      },
                    ),
                  )
                ],
              ),
            if(filterTypeView['지출현황']! && _listDairyContent[date]!.mapBranchUserExpense != null &&
                _listDairyContent[date]!.mapBranchUserExpense.length > 0)
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  buildDiaryHeader(Icons.attach_money, ' 지출현황'),
                  Container(
                    child:  ListView.builder(
                      shrinkWrap: true,
                      padding: EdgeInsets.fromLTRB(5, 5, 0, 5),
                      physics: const ClampingScrollPhysics(),
                      itemCount: _listDairyContent[date]!.mapBranchUserExpense.keys.length,
                      itemBuilder: (BuildContext context, int index) {
                        var sortedKeys = _listDairyContent[date]!.mapBranchUserExpense.keys.toList()..sort();
                        String branch = sortedKeys.elementAt(index);
                        if(filterBranchView[branch] != null && filterBranchView[branch]!){
                          return ListView.builder(
                              padding: EdgeInsets.fromLTRB(0, 0, 0, 10),
                              shrinkWrap: true,
                              physics: const ClampingScrollPhysics(),
                              itemCount: _listDairyContent[date]!.mapBranchUserExpense[branch]!.length + 1,
                              itemBuilder:(BuildContext context, int index){
                                if(index == 0){
                                  return Container(
                                    padding: EdgeInsets.only(bottom: 3),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.center,
                                      children: [
                                        Icon(Icons.place_outlined, color: Colors.amberAccent[200], size: 18,),
                                        Text(' ' + branch, style: TextStyle(
                                          color: Colors.amberAccent[100],
                                          fontSize: 15,
                                        ),
                                            textAlign: TextAlign.left),
                                      ],
                                    ),
                                  );
                                }
                                String user = _listDairyContent[date]!.mapBranchUserExpense[branch]!.keys.toList().elementAt(index - 1);
                                List<ExpenseItem> listExpense = _listDairyContent[date]!.mapBranchUserExpense[branch]![user]!;
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
                                                padding: EdgeInsets.only(left: 10),
                                                child: Text(ex.detail!, style: TextStyle(color: Colors.white54, fontSize: 13))
                                            )
                                          ],
                                        )
                                    );
                                  },
                                );
                              }
                          );
                        }
                        else{
                          return Container();
                        }
                      },
                    ),
                  )
                ],
              ),
          ],
        )
      );
    }
    else {
      return Container();
    }
  }
}

class DiaryContent{
  Map<String, Map<String, String>> mapBranchUserTime = {};
  Map<String, Map<String, List<ExpenseItem>>> mapBranchUserExpense = {};
  Map<String, Map<String, String>> mapBranchUserDiary = {};
  Map<String, String> mapBranchCheckListDone = {};
  Map<String, String> mapBranchCheckListYet = {};
}

class DiaryItem {
  late String name;
  late String branch;
  late DateTime date;
  late String text;
  late String hdr;
  late String type;
  late bool hdrPrint = false;

  DiaryItem({required this.name, required this.branch, required this.date, required this.text, required this.hdr, required this.type});

}