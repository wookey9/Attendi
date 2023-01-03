import 'dart:convert';
import 'dart:developer';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:work_inout/user_database.dart';
import 'branch_database.dart';
import 'package:syncfusion_flutter_xlsio/xlsio.dart' as xlsio;
import 'package:loading_indicator/loading_indicator.dart';
import 'timelineScreen.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'checklist.dart';

class BranchTimelinePage extends StatefulWidget{
  const BranchTimelinePage({required this.companyName, required this.branch, required this.scrollController, required this.adminDbQuerySnapShot, required this.workerDbQuerySnapShot, required this.branchCLQuerySnapShot, required this.workerExpListMap});

  final String companyName;
  final String branch;
  final ScrollController scrollController;
  final QuerySnapshot adminDbQuerySnapShot;
  final QuerySnapshot branchCLQuerySnapShot;
  final Map<String, QuerySnapshot> workerDbQuerySnapShot;
  final Map<String, Map<DateTime, List<ExpenseItem>>> workerExpListMap;
  @override
  State<StatefulWidget> createState() => BranchTimelinePageState();


}

class BranchTimelinePageState extends State<BranchTimelinePage> with AutomaticKeepAliveClientMixin {
  late bool initDone = false;
  late int initDone2ndCnt = 0;
  late int initUserCnt = 0;
  late int userCnt = 0;
  late ScrollController _scrollController = ScrollController();
  late Map<DateTime, DiaryContent> _listDairyContent = {};
  late DateTime _currentDate = DateTime.now().subtract(Duration(days: 30));

  late Map<DateTime, GlobalKey> globalKeys = {};
  late var sortedKeys;
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
  late Map<int, DateTime> scrollToDate = {};
  late double prevScrollOffset = 0;
  late double prevScrollMax = 0;

  final ItemScrollController itemScrollController = ItemScrollController();
  final ItemPositionsListener itemPositionsListener = ItemPositionsListener.create();



  @override
  bool get wantKeepAlive => true;

  final List<String> diaryType = ['근무현황','지출현황','체크리스트','업무일지'];

  @override
  initState() {
    super.initState();

    for (int i = 0; i < 30; i++) {
      days.add(DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day).subtract(Duration(days: i)));
    }

    filterBranchView[widget.branch] = true;

    diaryType.forEach((element) {
      filterTypeView[element] = true;
    });

    setState(() {
      userCnt = widget.adminDbQuerySnapShot.docs.length;
    });
    widget.adminDbQuerySnapShot.docs.forEach((doc) {
      setState((){
        userIdList.add(doc.id);
      });
    });

    getDiaryInfo();

    QuerySnapshot querySnapshot2 = widget.branchCLQuerySnapShot;
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
          if(_listDairyContent[key2] == null){
            _listDairyContent[key2] = DiaryContent();
          }

          if(_listDairyContent[key2]!.mapBranchCheckListDone[widget.branch] == null){
            _listDairyContent[key2]!.mapBranchCheckListDone[widget.branch] = {};
          }

          _listDairyContent[key2]!.mapBranchCheckListDone[widget.branch]![element.name] = value2;
        });
      });
    });

    setState(() {
      initDone2ndCnt++;
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

                      if(h < height){
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
                              height += nextbox.size.height + 5;
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
                          height += nextbox.size.height + 5;
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

  @override
  Widget build(BuildContext context) {
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
            Container(
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
                                Text('  ' + DateFormat('yyyy-MM-dd').format(_currentDate) + ' ',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 17,
                                      fontWeight: FontWeight.bold),
                                ),
                                Text(DateFormat('E', 'ko_KR').format(_currentDate),
                                  style: TextStyle(
                                      color: DateFormat('E', 'ko_KR')
                                          .format(_currentDate) == '토' ||
                                          DateFormat('E', 'ko_KR').format(
                                              _currentDate) == '일' ? Colors
                                          .redAccent[100] : Colors.white,
                                      fontSize: 17,
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
                                            height: 220,
                                            width: MediaQuery.of(context).size.width - 100,
                                            child:
                                            SingleChildScrollView(
                                              child: Column(
                                                children: [
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
                                                    value.mapBranchUserTime.keys.forEach((element) {
                                                      if (filterBranchView[element] == true) {
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
                                                      }
                                                    });
                                                  }
                                                  if(filterTypeView['지출현황'] != null && filterTypeView['지출현황']!) {
                                                    value.mapBranchUserExpense.keys.forEach((element) {
                                                      if (filterBranchView[element] == true) {
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
                                                      }
                                                    });
                                                  }
                                                  if(filterTypeView['체크리스트'] != null && filterTypeView['체크리스트']!) {
                                                    value.mapBranchUserExpense.keys.forEach((element) {
                                                      if (filterBranchView[element] == true) {
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
            ),
          ],
        )
    );
  }

  Widget get positionsView => ValueListenableBuilder<Iterable<ItemPosition>>(
    valueListenable: itemPositionsListener.itemPositions,
    builder: (context, positions, child) {
      int? min;
      int? max;
      if (positions.isNotEmpty) {
        // Determine the first visible item by finding the item with the
        // smallest trailing edge that is greater than 0.  i.e. the first
        // item whose trailing edge in visible in the viewport.
        min = positions
            .where((ItemPosition position) => position.itemTrailingEdge > 0)
            .reduce((ItemPosition min, ItemPosition position) =>
        position.itemTrailingEdge < min.itemTrailingEdge
            ? position
            : min)
            .index;
        // Determine the last visible item by finding the item with the
        // greatest leading edge that is less than 1.  i.e. the last
        // item whose leading edge in visible in the viewport.
        max = positions
            .where((ItemPosition position) => position.itemLeadingEdge < 1)
            .reduce((ItemPosition max, ItemPosition position) =>
        position.itemLeadingEdge > max.itemLeadingEdge
            ? position
            : max)
            .index;
      }
      return Row(
        children: <Widget>[
          Expanded(child: Text('First Item: ${min ?? ''}')),
          Expanded(child: Text('Last Item: ${max ?? ''}')),
        ],
      );
    },
  );

  Future<void> getDiaryInfo() async{

    userIdList.forEach((user) {
      String name = "";
      String branch = "";
      List<String> userInfo = user.split('-');
      if (userInfo.length >= 2) {
        name = userInfo[0].trimRight();
        branch = userInfo[1].trimRight();
        branch = branch.substring(2, branch.length - 1);
      }

      if(widget.workerDbQuerySnapShot[user] != null){
        QuerySnapshot querySnapshot = widget.workerDbQuerySnapShot[user]!;
        for(int i = 0; i < querySnapshot.docs.length; i++){
          var doc = querySnapshot.docs[i];
          DateTime date = DateFormat('yyyy-MM-dd').parse(doc.id);
          if(date != null){
            if(globalKeys[date] == null){
              setState((){
                globalKeys[date] = GlobalKey();
                sortedKeys = globalKeys.keys.toList()..sort();
              });
            }
            if(doc.exists){
              var dateInfo = doc.data()! as Map<String, dynamic>;
              if (dateInfo != null) {
                String text = "";
                String start = "";
                String end = "";
                String duration = "";
                String rest = "";
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
              }
            }
            if(widget.workerExpListMap[user] != null && widget.workerExpListMap[user]![date] != null){
              widget.workerExpListMap[user]![date]!.forEach((expenseItem) {
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
                  if(expenseItem != null){
                    _listDairyContent[date]!.mapBranchUserExpense[branch]![name]!
                        .add(expenseItem);
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
              });
            }
          }
        }
        setState(() {
          initDone = true;
        });
      }
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
        _listDairyContent[date]!.mapBranchUserTime.forEach((key, value) {
          if(filterBranchView[key] == true){
            value.forEach((key, value) {
              if(value.length > 0){
                ret = true;
              }
            });
          }
        });
      }

      if(filterTypeView['지출현황'] != null && filterTypeView['지출현황']!) {
        _listDairyContent[date]!.mapBranchUserExpense.forEach((key, value) {
          if(filterBranchView[key] == true){
            value.forEach((key, value) {
              if(value.length > 0){
                ret = true;
              }
            });
          }
        });
      }

      if(filterTypeView['체크리스트'] != null && filterTypeView['체크리스트']!) {
        _listDairyContent[date]!.mapBranchCheckListDone.forEach((key, value) {
          if (filterBranchView[key] == true) {
            value.forEach((key2, value2) {
              if(value2 != 'false'){
                ret = true;
              }
            });
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
                        fontSize: 17,
                        fontWeight: FontWeight.bold)
                    ,),
                  Text(DateFormat('E', 'ko_KR').format(date),
                    style: TextStyle(
                        color: DateFormat('E', 'ko_KR')
                            .format(date) == '토' ||
                            DateFormat('E', 'ko_KR').format(
                                date) == '일' ? Colors
                            .redAccent[100] : Colors.white70,
                        fontSize: 17,
                        fontWeight: FontWeight.bold
                    )
                    ,),
                ],
              ),
            ),
            if(filterTypeView['체크리스트']! &&  _listDairyContent[date]!.mapBranchCheckListDone != null &&
                (_listDairyContent[date]!.mapBranchCheckListDone.length > 0) && _listDairyContent[date]!.mapBranchCheckListDone[widget.branch] != null && _listDairyContent[date]!.mapBranchCheckListDone[widget.branch]!.length > 0)
              Column(
                children: [
                  buildDiaryHeader(
                      Icons.check, ' 체크리스트'),
                  Container(
                    child: ListView.builder(
                      shrinkWrap: true,
                      padding: EdgeInsets.fromLTRB(5, 5, 0, 5),
                      physics: const ClampingScrollPhysics(),
                      itemCount: _listDairyContent[date]!.mapBranchCheckListDone[widget.branch]!.keys.length,
                      itemBuilder:(BuildContext context, int index){
                        String checkName = _listDairyContent[date]!.mapBranchCheckListDone[widget.branch]!.keys.toList().elementAt(index);
                        bool checked = _listDairyContent[date]!.mapBranchCheckListDone[widget.branch]![checkName]! != 'false';

                        return Container(
                          padding: EdgeInsets.fromLTRB(15, 0, 0, 3),
                          child:   Text((checked?'v ':'  ') + checkName,style: TextStyle(fontWeight: FontWeight.bold, color: checked?Colors.green[200]:Colors.redAccent[100]),),
                        );
                      }
                    ),
                  ),
                ],
              ),
            if(filterTypeView['근무현황']! &&  _listDairyContent[date]!.mapBranchUserTime != null &&
                _listDairyContent[date]!.mapBranchUserTime.length > 0  && _listDairyContent[date]!.mapBranchUserTime[widget.branch] != null && _listDairyContent[date]!.mapBranchUserTime[widget.branch]!.length > 0)
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
                        itemCount: _listDairyContent[date]!.mapBranchUserTime[widget.branch]!.keys.length,
                        itemBuilder:(BuildContext context, int index){
                          String user = _listDairyContent[date]!.mapBranchUserTime[widget.branch]!.keys.toList().elementAt(index);
                          String timeStr = _listDairyContent[date]!.mapBranchUserTime[widget.branch]![user]!;

                          return Container(
                            padding: EdgeInsets.fromLTRB(15, 0, 0, 3),
                            child:   Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  alignment: Alignment.centerLeft,
                                  width: 90,
                                  child: Text(user,style: TextStyle(fontWeight: FontWeight.bold, color: Colors.teal[200]),),
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
                  )
                ],
              ),
            if(filterTypeView['지출현황']! && _listDairyContent[date]!.mapBranchUserExpense != null &&
                _listDairyContent[date]!.mapBranchUserExpense.length > 0  && _listDairyContent[date]!.mapBranchUserExpense[widget.branch] != null && _listDairyContent[date]!.mapBranchUserExpense[widget.branch]!.length > 0)
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  buildDiaryHeader(Icons.attach_money, ' 지출현황'),
                  Container(
                    child:  ListView.builder(
                      shrinkWrap: true,
                      padding: EdgeInsets.fromLTRB(5, 5, 0, 5),
                      physics: const ClampingScrollPhysics(),
                        itemCount: _listDairyContent[date]!.mapBranchUserExpense[widget.branch]!.length,
                        itemBuilder:(BuildContext context, int index){
                          String user = _listDairyContent[date]!.mapBranchUserExpense[widget.branch]!.keys.toList().elementAt(index);
                          List<ExpenseItem> listExpense = _listDairyContent[date]!.mapBranchUserExpense[widget.branch]![user]!;
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
                                            child: Text(user,style: TextStyle(fontWeight: FontWeight.bold, color: Colors.yellow[200]),),
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
                    ),
                  ),
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
  Map<String, Map<String, String>> mapBranchCheckListDone = {};
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