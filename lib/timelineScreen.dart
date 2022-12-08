import 'dart:async';
import 'dart:math';
import 'package:day_night_time_picker/lib/state/time.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:webviewx/webviewx.dart';
import 'package:work_inout/userScreen.dart';

import 'checklist.dart';
import 'package:calendar_timeline/calendar_timeline.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:day_night_time_picker/lib/constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:time_range/time_range.dart';
import 'package:work_inout/user_database.dart';
import 'branch_database.dart';
import 'package:day_night_time_picker/day_night_time_picker.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_time_range/flutter_time_range.dart';
import 'package:flutter_time_picker_spinner/flutter_time_picker_spinner.dart';
import 'package:pattern_formatter/pattern_formatter.dart';

import 'myAdKakaoFit.dart';

const List<String> expenseType = ['발주', '매장카드','계좌이체', '기타'];

class TimeLinePage extends StatefulWidget{
  const TimeLinePage({Key? key, required this.companyId, required this.title,
    required this.user,required this.workplace,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => _TimeLineState();

  final String title;
  final String user;
  final String workplace;
  final String companyId;
}

class _TimeLineState extends State<TimeLinePage> {
  late DateTime _selectedDate;
  late String _selectedDateDB;
  late Map<DateTime, String> _rangeMap = {};
  late int selectCnt = 0;
  late List<double> _restTimeRef = [
    0
  ]; //List.generate(20, (index) => index*0.5);
  final ScrollController _scrollController = ScrollController(
      keepScrollOffset: false);

  final ScrollController _userScrollController = ScrollController(
      keepScrollOffset: false);
  late double _selectedRestHour = 0;
  late DateTime _focusDay = DateTime.now();
  late Map<DateTime, double> _restTime;
  late Map<DateTime, TimeOfDay> _startTime;
  late Map<DateTime, TimeOfDay> _endTime;
  late Map<DateTime, double> _durationTime;
  late Map<DateTime, String> _workDiary;
  late double _totalWorkingTime = 0;
  late TimeOfDay? _selectedTimeFrom = null;
  late TimeOfDay? _selectedTimeTo = null;

  late String _userId;
  late bool _userLocked = false;

  late String _passwordNew;
  late String _passwordRef;
  late String _branchNotice = "";
  late String _branchDiaryFormat = "";
  final double _dayCharSize = 12;
  late String _selectFromTo = "";
  late bool _calendarExpand = true;
  late List<CheckListItem> _checkList = [];
  late List<String> curCheckTitle = [];
  late List<bool?> curChecked = [];
  late List<ExpenseItem> _listExpense = [];
  late List<ExpenseItem> _listExpenseOrg = [];
  late int _minuteInterval = 30;

  TextEditingController _inputController = new TextEditingController();

  var _restTimeListKey;
  late bool _diaryChanged = false;
  FocusNode _diaryFocusNode = new FocusNode();
  late CalendarFormat _calendarFormat = CalendarFormat.month;
  late double _calendarHeight = 500;
  late int _calendarExpandDuration = 300;
  StreamController<DateTime> _timeStreamCon = StreamController<DateTime>.broadcast();

  var _fillCalendar = true;
  late double _calendarRowHeight = 85;
  final double divHeight = 20;
  static const _locale = 'ko';

  int _selectedBottomIndex = 0;

  var _bottomTabController;

  String _formatNumber(String s) => NumberFormat.decimalPattern(_locale).format(int.parse(s));
  String get _currency => NumberFormat.compactSimpleCurrency(locale: _locale).currencySymbol;


  @override
  void initState() {
    initializeDateFormatting('ko-KR');
    _initDateInfo();
    _restTimeListKey = ObjectKey(_restTimeRef);
    _updateRestTimeRef(_selectedDate);
    super.initState();
  }

  double _timeOfDayToDouble(TimeOfDay tod) => tod.hour + tod.minute / 60.0;

  void _initDateInfo() {

    _selectedDate = DateTime(DateTime
        .now()
        .year, DateTime
        .now()
        .month, DateTime
        .now()
        .day);
    _selectedDateDB = DateFormat('yyyy-MM-dd').format(_selectedDate);
    _startTime = {};
    _endTime = {};
    _durationTime = {};
    _restTime = {};
    _workDiary = {};
    _userId =
        widget.user.replaceAll('-', '').trim() + " - [" + widget.workplace +
            "]";
    
    UserDatabase.getMinuteIntervalDb(widget.companyId).then((value) {
      setState(() {
        _minuteInterval = value;
      });
    });

    BranchDatabase.getBranchCollection(companyId: widget.companyId).get().then((
        QuerySnapshot querySnapshot) {
      for (int i = 0; i < querySnapshot.docs.length; i++) {
        String branchName = querySnapshot.docs[i].id;
        var data = querySnapshot.docs[i].data()! as Map<String, dynamic>;
        if(widget.workplace == branchName){
          data.forEach((key, value) {
            if (key == 'notice') {
              if (value != null && value.length > 0) {
                setState(() {
                  _branchNotice = value;
                });
              }
            }
            else if (key == 'diaryFormat') {
              if (value != null && value.length > 0) {
                setState(() {
                  _branchDiaryFormat = value;
                  _inputController.text = _branchDiaryFormat;
                });
              }
            }
          });
          getDataFromUserDoc(_userId);
          BranchDatabase.getBranchCheckListCollection(companyId: widget.companyId, branch: branchName).get().then((QuerySnapshot querySnapshot2){
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
                    if(date != null)
                      checked[date] = value;
                  }
                }
              });
              setState((){
                _checkList.add(CheckListItem(name: title, writetime: writetime, checked: checked));
              });

            }
          });
        }
      }
    });
    getDailyDataFromUserDoc(_userId, _selectedDateDB);

  }

  bool isWeekend(DateTime date){
    String w = DateFormat('E','ko_KR').format(_selectedDate);
    if(w == '토' || w == '일'){
      return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
        length: 2,
        child: Scaffold(
          backgroundColor: Color(0xFF333A47),
          appBar: AppBar(
            automaticallyImplyLeading: _fillCalendar,
            leadingWidth: 30,
            backgroundColor: Color(0xFF333A47),
            title:
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text((_selectedDate.year != DateTime.now().year?_selectedDate.year.toString() + ' - ' : '') +  _selectedDate.month.toString() + '월 ' + (_fillCalendar ? '' : (_selectedDate.day.toString() + '일')), style: TextStyle(fontSize: 25, color: Colors.teal[200], fontWeight: FontWeight.bold)),
                    if(!_fillCalendar) Text(' ('+DateFormat('E','ko_KR').format(_selectedDate) + ')', style: TextStyle(fontSize: 25, color: isWeekend(_selectedDate) ? Colors.redAccent[100] : Colors.teal[200], fontWeight: FontWeight.bold)),
                    if(_fillCalendar) Text(_totalWorkingTime.toString() + '시간', style: TextStyle(fontSize: 24, color: Colors.redAccent[100], fontWeight: FontWeight.bold)),
                  ],
                ),
                Padding(padding: EdgeInsets.fromLTRB(0, 0, 0, 5),
                  child: Text('  @' + _userId, style: TextStyle(fontSize : 12, color: Colors.white, ), maxLines: 2,),)
              ],
            ),

            actions: [
              if(_fillCalendar) IconButton(
                  onPressed: (){
                    setState((){
                      _selectedDate = DateTime(DateTime
                          .now()
                          .year, DateTime
                          .now()
                          .month, DateTime
                          .now()
                          .day);
                      _selectedDateDB = DateFormat('yyyy-MM-dd').format(_selectedDate);
                      _focusDay = _selectedDate;
                      _selectedTimeFrom = _startTime[_selectedDate] ?? TimeOfDay(hour: TimeOfDay.now().hour, minute: (TimeOfDay.now().minute / _minuteInterval).floor() * _minuteInterval);
                      _selectedTimeTo = _endTime[_selectedDate] ?? TimeOfDay(hour: TimeOfDay.now().hour, minute: (TimeOfDay.now().minute / _minuteInterval).floor() * _minuteInterval);
                      getDailyDataFromUserDoc(_userId, _selectedDateDB);
                      if (_restTime[_selectedDate] != null) {
                        _selectedRestHour = _restTime[_selectedDate]!;
                      }
                      else {
                        _selectedRestHour = 0;
                      }
                      //_updateSelectedRestHour();
                      _inputController.text = _workDiary[_selectedDate] ?? _branchDiaryFormat;
                      _totalWorkingTime = _updateTotalWorkingTime(_selectedDate);
                      _diaryFocusNode.unfocus();
                    });
                  },
                  icon: Icon(Icons.today_outlined)
              ),
            ],
          ),
/*
          bottomNavigationBar: (!_fillCalendar) ? null : BottomAppBar(
            child: Container(
              color: Color(0xFF333A47),
              child: TabBar(
                indicator: BoxDecoration(color: Colors.black38),
                tabs: <Widget>[
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.calendar_month,color: _getBottomSelectedColor(0),),
                        Text(" 캘린더", style: TextStyle(color: _getBottomSelectedColor(0)))
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
 */
          body:
          //_fillCalendar ? _buildCalendar() :
          Column(
            children: [
              _buildCalendar(),
              if(!_fillCalendar) ...{
                if(_calendarExpand == false)...{
                  Expanded(
                      child:
                      Material(
                        color: Color(0xFF333A47),
                        child: SingleChildScrollView(
                            controller: _userScrollController,
                            child: Column(
                              children: [
                                getAdKakaoFit('Attendi-web-userScreen-320x100'),
                                Divider(
                                    color: Colors.white38,
                                    thickness: 1,
                                    height: 1),
                                Padding(
                                    padding: EdgeInsets.only(left: 10, top: 10),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.center,
                                      children: [
                                        Icon(Icons.work_history_outlined,
                                          color: Colors.white,),
                                        Text(' 근무 시간',
                                          style: TextStyle(
                                              fontSize: 17, color: Colors.white),
                                          textAlign: TextAlign.center,),
                                      ],
                                    )
                                ),
                                Container(
                                  padding: EdgeInsets.only(
                                      top: 15, left: 20, right: 20),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment
                                        .spaceAround,
                                    children: [
                                      TextButton(
                                          style: ButtonStyle(
                                            overlayColor: MaterialStateColor
                                                .resolveWith((states) =>
                                            Colors.white38),
                                            backgroundColor: MaterialStateColor
                                                .resolveWith((states) =>
                                            _selectFromTo == "from"
                                                ? Colors.white38
                                                : Colors.transparent),

                                          ),
                                          onPressed: () {
                                            setState(() {
                                              if (_selectFromTo == "from") {
                                                _selectFromTo = "";
                                              }
                                              else {
                                                _selectFromTo = "from";
                                                _timeStreamCon.add(
                                                    convertTimeToDateTime(
                                                        _selectedTimeFrom));
                                              }
                                            });
                                          },
                                          child: Text(_selectedTimeFrom != null
                                              ? (_selectedTimeFrom!.format(context))
                                              : TimeOfDay(hour: TimeOfDay
                                              .now()
                                              .hour, minute: (TimeOfDay
                                              .now()
                                              .minute / 30).floor() * 30).format(
                                              context),
                                            style: TextStyle(color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 20),
                                          )
                                      ),
                                      Icon(Icons.arrow_forward,
                                        color: Colors.white38,),
                                      TextButton(
                                          style: ButtonStyle(
                                            overlayColor: MaterialStateColor
                                                .resolveWith((states) =>
                                            Colors.white38),
                                            backgroundColor: MaterialStateColor
                                                .resolveWith((states) =>
                                            _selectFromTo == "to"
                                                ? Colors.white38
                                                : Colors.transparent),
                                          ),
                                          onPressed: () {
                                            setState(() {
                                              if (_selectFromTo == "to") {
                                                _selectFromTo = "";
                                              }
                                              else {
                                                _selectFromTo = "to";
                                                _timeStreamCon.add(
                                                    convertTimeToDateTime(
                                                        _selectedTimeTo));
                                              }
                                            });
                                          },
                                          child: Text(_selectedTimeTo != null
                                              ? (_selectedTimeTo!.format(context))
                                              : TimeOfDay(hour: TimeOfDay
                                              .now()
                                              .hour, minute: (TimeOfDay
                                              .now()
                                              .minute / 30).floor() * 30).format(
                                              context),
                                            style: TextStyle(color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 20),
                                          )
                                      ),
                                    ],
                                  ),
                                ),

                                Divider(color: Colors.white38,
                                    thickness: 1,
                                    height: divHeight),
                                AnimatedContainer(
                                  height: _selectFromTo == "from" ? 150 : 0,
                                  duration: Duration(milliseconds: 300),
                                  onEnd: () {
                                    _updateSelectedRestHour();
                                  },
                                  child: Container(
                                    height: 150,
                                    child: (_selectFromTo == "from") ? getTimeSlider(_selectedTimeFrom) : Container(),
                                  ),
                                ),
                                AnimatedContainer(
                                  height: _selectFromTo == "to" ? 150 : 0,
                                  duration: Duration(milliseconds: 300),
                                  onEnd: () {
                                    _updateSelectedRestHour();
                                  },
                                  child: Container(
                                    height: 150,
                                    child: (_selectFromTo == "to") ? getTimeSlider(_selectedTimeTo) : Container(),
                                  ),
                                ),
                                if(_selectFromTo != "") Divider(
                                    color: Colors.white38,
                                    thickness: 1,
                                    height: divHeight),
                                Padding(
                                    padding: EdgeInsets.only(
                                        left: 10, top: 0, bottom: 10),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.center,
                                      children: [
                                        Icon(Icons.forest, color: Colors.white,
                                          size: 22,),
                                        Text(' 휴식 시간',
                                          style: TextStyle(
                                            fontSize: 17, color: Colors.white,),
                                          textAlign: TextAlign.center,),
                                      ],
                                    )
                                ),
                                SizedBox(height: 4),
                                SizedBox(
                                  height: 45,
                                  child: ListView.builder(
                                    key: _restTimeListKey,
                                    controller: _scrollController,
                                    scrollDirection: Axis.horizontal,
                                    padding: EdgeInsets.only(left: 20),
                                    itemCount: _restTimeRef.length,
                                    itemExtent: 90,
                                    itemBuilder: (BuildContext context, int index) {
                                      return Padding(
                                        padding: const EdgeInsets.only(right: 8.0),
                                        child: TimeButton(
                                            borderColor: Colors.white38,
                                            activeBorderColor: Colors.white,
                                            backgroundColor: Color(0xFF333A47),
                                            activeBackgroundColor: Color(
                                                0xFF333A47),
                                            textStyle: TextStyle(
                                                fontWeight: FontWeight.normal,
                                                color: Colors.white38),
                                            activeTextStyle: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white),
                                            time: _restTimeRef[index].toString() +
                                                ' 시간',
                                            value: _selectedRestHour ==
                                                _restTimeRef[index],
                                            onSelect: (_) =>
                                                setState(() {
                                                  _selectRestHour(
                                                      index, _restTimeRef[index]);
                                                  //_getDurationTime(_selectedDate);
                                                })
                                        ),
                                      );
                                    },

                                  ),
                                ),
                                SizedBox(height: 4,),
                                Divider(color: Colors.white38,
                                    thickness: 1,
                                    height: divHeight),
                                Padding(
                                    padding: EdgeInsets.only(
                                        left: 10, top: 0, bottom: 10),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.center,
                                      children: [
                                        Container(
                                          padding: EdgeInsets.only(top: 4),
                                          child: Icon(Icons.attach_money,
                                            color: Colors.white, size: 25,),
                                        ),
                                        Text(' 지출 내역',
                                          style: TextStyle(
                                              fontSize: 17, color: Colors.white),
                                          textAlign: TextAlign.center,),
                                      ],
                                    )
                                ),
                                _buildExpenseList(),
                                SizedBox(height: 4),
                                Divider(color: Colors.white38,
                                    thickness: 1,
                                    height: divHeight),
                                _buildChecklist(),
                                if(curChecked.length > 0) SizedBox(height: 4),
                                if(curChecked.length > 0) Divider(color: Colors.white38,
                                    thickness: 1,
                                    height: divHeight),
                                Padding(
                                    padding: EdgeInsets.only(
                                        left: 10, top: 0, bottom: 10),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.center,
                                      children: [
                                        Container(
                                          padding: EdgeInsets.only(top: 4),
                                          child: Icon(Icons.note_alt_outlined,
                                            color: Colors.white, size: 25,),
                                        ),
                                        Text(' 업무 일지',
                                          style: TextStyle(
                                              fontSize: 17, color: Colors.white),
                                          textAlign: TextAlign.center,),
                                      ],
                                    )
                                ),
                                Container(
                                    margin: EdgeInsets.fromLTRB(20, 5, 20, 0),
                                    padding: EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: Color(0xFF333A47),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                          color: Colors.white70
                                      ),
                                    ),
                                    child: Column(
                                      children: [
                                        Container(
                                          padding: EdgeInsets.fromLTRB(0, 0, 0, 10),
                                          alignment: Alignment.centerLeft,
                                          child: Text(
                                            _getWorkDiaryHdr(), style: TextStyle(
                                            fontSize: 15,
                                            color: Colors.blueAccent[100],),),
                                        ),
                                        SingleChildScrollView(
                                          scrollDirection: Axis.vertical,
                                          child:
                                          TextFormField(
                                            decoration: InputDecoration(
                                              enabledBorder: UnderlineInputBorder(
                                                borderSide: BorderSide(
                                                    color: Colors.white70),
                                              ),
                                              focusedBorder: UnderlineInputBorder(
                                                borderSide: BorderSide(
                                                    color: Colors.white70),
                                              ),
                                            ),
                                            controller: _inputController,
                                            keyboardType: TextInputType.multiline,
                                            maxLines: null,
                                            autofocus: false,
                                            style: TextStyle(
                                                fontSize: 15, color: Colors
                                                .white70),

                                            focusNode: _diaryFocusNode,
                                            onChanged: (text) {
                                              if (_diaryChanged == false) {
                                                setState(() {
                                                  _diaryChanged = true;
                                                });
                                              }
                                            },
                                          ),
                                        ),
                                      ],
                                    )
                                ),
                                SizedBox(height: 8),
                                Divider(color: Colors.white38,
                                    thickness: 1,
                                    height: divHeight),
                                getAdKakaoFit('Attendi-web-userScreen3'),
                                Divider(color: Colors.white38,
                                    thickness: 1,
                                    height: divHeight),
                              ],
                            )
                        ),
                      )

                  )
                }
              }
            ],
          ),
          floatingActionButton: _buildFloatingActionButton(),
        )
    );
  }


  Color? _getBottomSelectedColor(int index){
    return _selectedBottomIndex == index ? Colors.redAccent[100] : Colors.white30;
  }

  void _onBottomItemTapped(int index) {
    setState(() {
      _selectedBottomIndex = index;
    });
  }

  Widget getTimeSlider(TimeOfDay? seltime){
    TimeOfDay time = seltime ?? TimeOfDay.now();
    return CupertinoTheme(
      data: CupertinoThemeData(brightness: Brightness.dark),
      child: CupertinoDatePicker(
        initialDateTime: DateTime(DateTime.now().year,DateTime.now().month,DateTime.now().day,time.hour,time.minute),
        use24hFormat: false,
        mode: CupertinoDatePickerMode.time,
        minuteInterval: _minuteInterval,
        onDateTimeChanged: (DateTime date){
          setState(() {
            //_dateTime = time;
            if (_selectFromTo == "from") {
              _selectedTimeFrom =
                  TimeOfDay.fromDateTime(date);
              if (date.isAfter(convertTimeToDateTime(
                  _selectedTimeTo))) {
                _selectedTimeTo = _selectedTimeFrom;
              }
            }
            else if (_selectFromTo == "to") {
              _selectedTimeTo =
                  TimeOfDay.fromDateTime(date);
              if (date.isBefore(convertTimeToDateTime(
                  _selectedTimeFrom))) {
                _selectedTimeFrom = _selectedTimeTo;
              }
            }
          });
        },
      ),
    );
  }

  DateTime convertTimeToDateTime(TimeOfDay? t){
    final now = new DateTime.now();
    if(t != null){
      return DateTime(now.year, now.month, now.day, t.hour, t.minute);
    }
    else{
      return DateTime(now.year, now.month, now.day, now.hour, (now.minute / 30).floor() * 30);
    }
  }

  bool isSameDay(DateTime? a, DateTime? b) {
    if (a == null || b == null) {
      return false;
    }

    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  Widget _buildExpenseList(){
    return ListView.builder(
      padding: EdgeInsets.all(10),
        itemCount: _listExpense.length + 1,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemBuilder: (BuildContext context, int index){
          if(index == _listExpense.length){
            return TextButton(
                onPressed: (){
                  setState(() {
                    _listExpense.add(ExpenseItem());
                    double curoffset = _userScrollController.offset;
                    _userScrollController.animateTo(curoffset + 146,
                        duration: Duration(milliseconds: 300), curve: Curves.easeIn);
                  });
                },
                child: Container(
                  alignment: Alignment.center,
                  margin: EdgeInsets.all(10),
                  child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text('지출 내역 추가 ',style: TextStyle(color: Colors.white70,fontSize: 16),),
                        Icon(Icons.add, color: Colors.white,),
                      ]
                  )
                )
            );
          }
          else{
            return
              Container(
                  margin: const EdgeInsets.all(10),
                  padding: const EdgeInsets.only(left: 10, bottom: 5, right: 10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.all(Radius.circular(5)),
                    border: Border.all(
                        color: Colors.white70
                    ),
                  ),
                  child:
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: EdgeInsets.all(5),
                              child: DropdownButton(
                                  dropdownColor: Color(0xFF333A47),

                                  hint: Text("지출 유형", style: TextStyle(color : Colors.white70), ),
                                  underline: Container(),
                                  items: expenseType.map((String value) {
                                    return DropdownMenuItem(
                                      value: value,
                                      child: Text(value, style: TextStyle(color : Colors.white70),),
                                    );
                                  }).toList(),
                                  onChanged: (String? value){
                                    setState((){
                                      _listExpense[index].type = value;
                                    });
                                  },
                                value: _listExpense[index].type
                              ),
                            ),

                            Flexible(
                              child: Container(
                                padding: EdgeInsets.only(left: 10, bottom: 5),
                                child:
                                TextFormField(
                                  initialValue: _listExpense[index].money,
                                  decoration: InputDecoration(
                                    enabledBorder: UnderlineInputBorder(
                                      borderSide: BorderSide(
                                          color: Colors.white70),
                                    ),
                                    focusedBorder: UnderlineInputBorder(
                                      borderSide: BorderSide(
                                          color: Colors.white70),
                                    ),
                                    labelText: '금액',
                                    labelStyle: TextStyle(color: Colors.white70),
                                    prefixText: _currency,
                                    prefixStyle: TextStyle(color: Colors.white70),
                                  ),
                                  style: TextStyle(color: Colors.white70),
                                  onChanged: ((value){
                                    setState(() {
                                      _listExpense[index].money = value;
                                    });
                                  }),
                                  inputFormatters: [
                                    ThousandsFormatter(allowFraction: true)
                                  ],
                                  keyboardType: TextInputType.number,
                                ),
                              ),

                            ),
                            IconButton(
                              icon: Icon(Icons.close_rounded, size: 18, color: Colors.white70,),
                              onPressed: (){
                                setState(() {
                                  _listExpense.removeAt(index);
                                });
                              },
                            ),
                          ],
                        )
                      ),
                      Flexible(
                        child: Container(
                          padding: EdgeInsets.all(5),
                          child:
                          TextFormField(
                            initialValue: _listExpense[index].detail,
                            keyboardType: TextInputType.multiline,
                            maxLines: null,
                            decoration: InputDecoration(
                              enabledBorder: UnderlineInputBorder(
                                borderSide: BorderSide(
                                    color: Colors.white70),
                              ),
                              focusedBorder: UnderlineInputBorder(
                                borderSide: BorderSide(
                                    color: Colors.white70),
                              ),
                              labelText: '상세 내역',
                              labelStyle: TextStyle(color: Colors.white70),
                            ),
                            style: TextStyle(color: Colors.white70),
                            onChanged: ((value){
                              setState(() {
                                _listExpense[index].detail = value;
                              });
                            }),
                          ),
                        ),

                      ),
                    ],
                  ),
              );
          }
    });
  }

  Widget _buildChecklist(){
    setState((){
      curCheckTitle = [];
      curChecked = [];
      _checkList.forEach((element) {
        if(element.writetime.isBefore(_selectedDate) || element.writetime.isAtSameMomentAs(_selectedDate)){
          curCheckTitle.add(element.name);
          curChecked.add(element.checked[_selectedDate] == 'false' ? false : true);
        }
      });
    });

    return curChecked.length > 0 ? ListView.separated(
        itemCount: curCheckTitle.length + 1,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemBuilder: (BuildContext context, int index){
          if(index == 0){
            return Padding(
                padding: EdgeInsets.only(left: 10, top: 5, bottom: 5),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(Icons.checklist,
                      color: Colors.white,),
                    Text(' 체크리스트',
                      style: TextStyle(
                          fontSize: 17, color: Colors.white),
                      textAlign: TextAlign.center,),
                  ],
                )
            );
          }
          else{
            return StatefulBuilder(builder: (context, _setState){
              return Theme(
                  data: ThemeData(unselectedWidgetColor: Colors.white70, scrollbarTheme: ScrollbarThemeData(isAlwaysShown: true )),
                  child:    CheckboxListTile(
                      value: curChecked[index - 1],
                      activeColor: Colors.transparent,
                      checkColor: Colors.white,
                      controlAffinity: ListTileControlAffinity.leading,
                      checkboxShape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(3),
                        side: BorderSide(color: Colors.white70),
                      ),
                      title: Text(curCheckTitle[index - 1], style: TextStyle(color: Colors.white70)),
                      onChanged: (value){
                        _setState((){
                          curChecked[index - 1] = value;
                        });
                      })
              );
            });
          }
        },
        separatorBuilder: (BuildContext context, int index) {
          return SizedBox(height: 1,);
      },
    ) : Container();
  }

  Widget _buildCalendar(){
    return Expanded(
      flex: _fillCalendar?1:0,
      child:
      Material(
        color: Color(0xFF333A47),
        elevation: 5,
        child: AnimatedContainer(
          color: Colors.black38,
            height: _calendarHeight,
            onEnd: (){
              setState((){
                int dur = 300;
                if(_calendarExpand){
                  if(_calendarFormat == CalendarFormat.week){
                    _fillCalendar = false;
                    _calendarFormat = CalendarFormat.twoWeeks;
                    _calendarHeight = _calendarRowHeight * 2 + 30;
                    _calendarExpandDuration = (dur / 2).floor();
                  }
                  else if(_calendarFormat == CalendarFormat.twoWeeks){
                    _fillCalendar = false;
                    _calendarFormat = CalendarFormat.month;
                    _calendarHeight = _calendarRowHeight * 5 + 30;
                    _calendarExpandDuration = (dur / 2).floor();
                  }
                  else{
                    _fillCalendar = true;
                  }
                }
                else{
                  if(_calendarFormat == CalendarFormat.month){
                    if(_calendarHeight != _calendarRowHeight * 5 + 30){
                      _fillCalendar = false;
                      _calendarHeight = _calendarRowHeight * 5 + 30;
                      _calendarExpandDuration = (dur / 2).floor();
                    }
                    else{
                      _fillCalendar = false;
                      _calendarHeight = _calendarRowHeight * 2 + 30;
                      _calendarFormat = CalendarFormat.twoWeeks;
                      _calendarExpandDuration = (dur / 2).floor();
                    }
                  }
                  else if(_calendarFormat == CalendarFormat.twoWeeks){
                    _fillCalendar = false;
                    _calendarFormat = CalendarFormat.week;
                    _calendarHeight = 0;
                    _calendarExpandDuration = dur;
                    _updateSelectedRestHour();
                  }
                  else{
                    _fillCalendar = false;
                    _calendarFormat = CalendarFormat.week;
                    _calendarHeight = 0;
                    _calendarExpandDuration = (dur / 5).floor();
                    _updateSelectedRestHour();
                  }
                }
              });
            },
            duration: Duration(milliseconds: _calendarExpandDuration),
            curve: Curves.linear,
            padding: EdgeInsets.only(left: 15, right: 15),
            child: TableCalendar(
              focusedDay: _focusDay,
              selectedDayPredicate: (day) => isSameDay(_selectedDate, day),
              firstDay: DateTime.now().subtract(Duration(days: 365)),
              lastDay:  DateTime.now().add(Duration(days: 365)),
              onDaySelected: (DateTime selected, DateTime focused){
                setState(() {
                  if (selected != null) {
                    if(selected.isBefore(DateTime(DateTime.now().add(Duration(days: 1)).year, DateTime.now().add(Duration(days: 1)).month, DateTime.now().add(Duration(days: 1)).day))){
                      _selectedDate = DateTime(selected.year, selected.month, selected.day);
                      _selectedDateDB = DateFormat('yyyy-MM-dd').format(_selectedDate);
                      _selectedTimeFrom = _startTime[_selectedDate] ?? TimeOfDay(hour: TimeOfDay.now().hour, minute: (TimeOfDay.now().minute / _minuteInterval).floor() * _minuteInterval);
                      _selectedTimeTo = _endTime[_selectedDate] ?? TimeOfDay(hour: TimeOfDay.now().hour, minute: (TimeOfDay.now().minute / _minuteInterval).floor() * _minuteInterval);
                      getDailyDataFromUserDoc(_userId, _selectedDateDB);
                      if (_restTime[_selectedDate] != null) {
                        _selectedRestHour = _restTime[_selectedDate]!;
                      }
                      else {
                        _selectedRestHour = 0;
                      }
                      _inputController.text = _workDiary[_selectedDate] ?? _branchDiaryFormat;
                      _totalWorkingTime = _updateTotalWorkingTime(_selectedDate);
                      _diaryFocusNode.unfocus();
                      _selectFromTo = "";

                      if(_calendarFormat == CalendarFormat.week){
                        _updateSelectedRestHour();
                      }

                      if(isSameDay(_focusDay,focused) && _calendarFormat == CalendarFormat.month){
                        //_calendarFormat = CalendarFormat.twoWeeks;
                        //_fillCalendar = false;
                        _calendarExpand = false;
                        _calendarHeight -= 1;
                        _calendarExpandDuration = 10;
                      }
                      _focusDay = DateTime(focused.year, focused.month, focused.day);
                    }
                    else{
                      print(DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().add(Duration(days: 1)).day));
                      Fluttertoast.showToast(msg: '미래의 업무는 입력할 수 없어요!');
                    }
                  }
                  selectCnt++;
                });
              },
              headerStyle: HeaderStyle(
                titleTextFormatter: (DateTime date, _){
                  String titleText = "";
                  if(date.year == DateTime.now().year){
                    titleText = date.month.toString() + '월 - [ ' + _totalWorkingTime.toString() + '시간 ]';
                  }
                  else{
                    titleText = date.year.toString() + '년 ' + date.month.toString() + '월 [ ' + _totalWorkingTime.toString() + '시간 근무 ]';
                  }
                  return titleText;
                },

                titleCentered: true,
                titleTextStyle: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20,),
                formatButtonDecoration: BoxDecoration(border: Border.all(color: Colors.white70,style: BorderStyle.solid),borderRadius: BorderRadius.circular(10)),
                formatButtonTextStyle: TextStyle(fontSize: 13, color: Colors.white70, ),
                //rightChevronVisible: false,
                //leftChevronVisible: false,
                rightChevronIcon: Icon(Icons.arrow_forward_ios_rounded, size: 15, color: Colors.white70,),
                leftChevronIcon:  Icon(Icons.arrow_back_ios_new_rounded, size: 15,color: Colors.white70),
                formatButtonVisible: !_fillCalendar,
                headerPadding: EdgeInsets.only(top: 5, bottom: 10),

              ),
              daysOfWeekStyle: DaysOfWeekStyle(
                weekdayStyle: TextStyle(color: Colors.white, fontSize: _dayCharSize),
                weekendStyle: TextStyle(color: Colors.redAccent[100], fontSize: _dayCharSize),
              ),
              calendarFormat: _calendarFormat,
              onFormatChanged: (format){
                setState((){
                  //_calendarFormat = format;

                  if(format == CalendarFormat.week){
                    //_fillCalendar = false;
                    //_calendarFormat = CalendarFormat.twoWeeks;
                    _calendarExpand = false;
                    _calendarHeight -= 1;
                    _calendarExpandDuration = 10;
                  }
                  else{
                    //_fillCalendar = true;
                    //_calendarFormat = format;
                    _calendarExpand = true;
                    _calendarHeight += 1;
                    _calendarExpandDuration = 10;
                  }
                });
              },
              onPageChanged: (DateTime date){
                setState((){
                  if(_calendarFormat == CalendarFormat.month){
                    _focusDay = DateTime(date.year, date.month, date.day);
                    _selectedDate = DateTime(date.year, date.month, date.day);
                    _selectedDateDB = DateFormat('yyyy-MM-dd').format(_selectedDate);
                    _selectedTimeFrom = _startTime[_selectedDate] ?? TimeOfDay(hour: TimeOfDay.now().hour, minute: (TimeOfDay.now().minute / _minuteInterval).floor() * _minuteInterval);
                    _selectedTimeTo = _endTime[_selectedDate] ?? TimeOfDay(hour: TimeOfDay.now().hour, minute: (TimeOfDay.now().minute / _minuteInterval).floor() * _minuteInterval);
                    getDailyDataFromUserDoc(_userId, _selectedDateDB);
                    if (_restTime[_selectedDate] != null) {
                      _selectedRestHour = _restTime[_selectedDate]!;
                    }
                    else {
                      _selectedRestHour = 0;
                    }
                    _inputController.text = _workDiary[_selectedDate] ?? _branchDiaryFormat;
                    _totalWorkingTime = _updateTotalWorkingTime(_selectedDate);
                    _diaryFocusNode.unfocus();
                  }
                });
              },
              calendarBuilders: calendarBuilder(),
              rowHeight: _calendarRowHeight,

              shouldFillViewport: _fillCalendar,
              calendarStyle: CalendarStyle(
                markersAlignment: Alignment.topCenter,
                canMarkersOverflow: true,
                outsideDaysVisible: false,
                cellAlignment: Alignment.topCenter,
                cellPadding: EdgeInsets.all(3),
                cellMargin: EdgeInsets.zero,
                weekendTextStyle: TextStyle(color: Colors.redAccent[100], fontSize: _dayCharSize),
                todayTextStyle: TextStyle(color: Colors.blue, fontSize: _dayCharSize, fontWeight: FontWeight.bold, decoration: TextDecoration.underline),
                selectedTextStyle: TextStyle(color: isSameDay(_selectedDate, DateTime.now()) ? Colors.blue : Colors.white, fontWeight: FontWeight.bold, fontSize: _dayCharSize, decoration: isSameDay(_selectedDate, DateTime.now()) ? TextDecoration.underline : null),
                defaultTextStyle: TextStyle(color: Colors.white, fontSize: _dayCharSize),
                selectedDecoration: BoxDecoration(shape: BoxShape.rectangle, borderRadius: BorderRadius.circular(5), color: Colors.black26,
                    border: Border.all(color: Colors.teal[200]!,style: BorderStyle.solid, width: 2)),
                todayDecoration: BoxDecoration(shape: BoxShape.rectangle, ),
                defaultDecoration: BoxDecoration(shape: BoxShape.rectangle,),
                weekendDecoration: BoxDecoration(shape: BoxShape.rectangle, ),
                disabledDecoration: BoxDecoration(shape: BoxShape.rectangle, ),
                outsideDecoration: BoxDecoration(shape: BoxShape.rectangle, ),
                holidayDecoration: BoxDecoration(shape: BoxShape.rectangle, ),
                rowDecoration: BoxDecoration(shape: BoxShape.rectangle, border: Border(top: BorderSide(color: Colors.white38, ))),
              ),
              availableCalendarFormats: {CalendarFormat.month : "월", CalendarFormat.twoWeeks : "2주" , CalendarFormat.week : "주"},
              daysOfWeekHeight: 30,
              formatAnimationDuration: const Duration(microseconds: 300),
              locale: 'ko-KR',
              headerVisible: false,// _fillCalendar,

            )
        )
      )
    );
  }

  Widget buildCalendarDayMarker({
    required String text,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.zero,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.rectangle,
          borderRadius: BorderRadius.circular(3),
          color: color,
        ),
        child:Text(
          text,
          style: TextStyle().copyWith(
            fontSize: 9.0,
            color: Colors.white,
          ),
          textAlign: TextAlign.center,
        ),
    );
  }

  Widget _buildEventsMarkerNum(DateTime day) {
    var isCheckDone = true;
    var curCheckListcnt = 0;

    _checkList.forEach((element) {
      if(element.checked[day] != null && element.checked[day] != 'false'){
        curCheckListcnt++;
      }
      else if(day.isBefore(element.writetime)){

      }
      else{
        curCheckListcnt++;
        isCheckDone = false;
      }
    });

    return Stack(
      children: [
        Positioned(
          child: Container(
              margin: EdgeInsets.only(top: 18),
              padding: EdgeInsets.only(left: 2,right: 2),
              child:
              Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if(_durationTime[day] != null) buildCalendarDayMarker(
                    text: '근무 ' +  _durationTime[day].toString(), color: Colors.teal[400]!,
                  ),
                  if(_startTime[day] != null) buildCalendarDayMarker(
                    text: _startTime[day]!.format(context), color: Colors.blueAccent[100]!,
                  ),
                  if(_endTime[day] != null) ...{
                    if(convertTimeToDateTime(_endTime[day]).isAfter(convertTimeToDateTime(_startTime[day]))) ...{
                      buildCalendarDayMarker(
                        text: _endTime[day]!.format(context), color: Colors.redAccent[100]!,
                      ),
                      if(curCheckListcnt > 0)
                      if(isCheckDone) buildCalendarDayMarker(text: '체크리스트', color: Colors.green[400]!)
                      else buildCalendarDayMarker(text: '체크 !', color: Colors.red[400]!),
                    }
                    else buildCalendarDayMarker(
                      text: '!', color: Colors.red[400]!,
                    ),
                  },
                  if(_restTime[day] != null) buildCalendarDayMarker(
                    text: '휴식 ' + _restTime[day].toString(), color: Colors.blueGrey[300]!,
                  ),
                  if(_workDiary[day] != null && _workDiary[day]!.length > 0) buildCalendarDayMarker(
                    text: '업무일지 ', color: Colors.deepPurpleAccent[100]!,
                  ),
                ],
              )
          )
        ),
        Positioned(child: Container()),
        if(day == _selectedDate && _calendarFormat == CalendarFormat.month)
          Container(
            padding: EdgeInsets.only(top: 30),
            child: Center(
              child:
              Container(
                padding: EdgeInsets.all(5),
                child: Icon(Icons.edit, color: Colors.white24, size: 17,),
                decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white24),

              ),
            ),
          ),
      ],
    );
  }

  CalendarBuilders calendarBuilder() {
    return CalendarBuilders(
      markerBuilder: (context, date, events) {
        DateTime date2 = DateTime(date.year, date.month, date.day);
        return _buildEventsMarkerNum(date2);
      },
    );
  }


  _updateRestTimeRef(DateTime date) {
    _restTimeRef = List.generate((10 * 2).toInt(), (index) => index * 0.5);
    /*
    if (_startTime[date] != null && _endTime[date] != null) {
      double start = _startTime[date]!.hour + _startTime[date]!.minute / 60;
      double end = _endTime[date]!.hour + _endTime[date]!.minute / 60;
      double duration = end - start;

      _restTimeRef =
          List.generate((10 * 2).toInt(), (index) => index * 0.5);
    }
    else {
      _restTimeRef = [0];
    }

     */
    //_restTimeListKey = ObjectKey(_restTimeRef);
  }

  _selectRestHour(int index, double restTime) {
    _selectedRestHour = restTime;
    double offset = index < 0 ? 0 : index * 90;
    if (offset > _scrollController.position.maxScrollExtent) {
      offset = _scrollController.position.maxScrollExtent;
    }
    _scrollController.animateTo(offset,
        duration: Duration(milliseconds: 500), curve: Curves.easeIn);
  }

  _updateSelectedRestHour() {
    if (_restTimeRef.contains(_selectedRestHour)) {
      int index = (_selectedRestHour * 2).toInt();
      double offset = index < 0 ? 0 : index * 90;
      if (offset > _scrollController.position.maxScrollExtent) {
        offset = _scrollController.position.maxScrollExtent;
      }
      _scrollController.animateTo(offset,
          duration: Duration(milliseconds: 500), curve: Curves.easeIn);
    }
    else {
      _selectedRestHour = 0;
    }
  }

  TimeOfDay stringToTimeOfDay(String tod) {
    final format = DateFormat.jm(); //"6:00 AM"
    return TimeOfDay.fromDateTime(format.parse(tod));
  }

  void getDataFromUserDoc(String userId) {
    UserDatabase.getUserCollection(companyId: widget.companyId).get().then((QuerySnapshot querySnapshot){
      bool noticeShow = true;
      querySnapshot.docs.forEach((doc) {
        if(doc.id == userId){
          var userInfo = doc.data()! as Map<String, dynamic>;
          if(userInfo != null){
            userInfo.forEach((key, value) {
              if(key == 'password'){
                if(value != null && value.length > 0){
                  _passwordRef = value;
                  _userLocked = true;
                }
              }
              if(key == 'noticeShow'){
                if(value != null && value.length > 0){
                  DateTime date = DateFormat('yyyy-MM-dd').parse(value);
                  //date = date.subtract(Duration(days: 6));
                  if(date.isBefore(DateTime.now().subtract(Duration(days: 1)))){
                    noticeShow = true;
                  }
                  else{
                    noticeShow = false;
                  }
                }
              }
            });
          }
        }
      });

      if(noticeShow){
        showDialog<String>(
          context: context,
          builder: (BuildContext context) => AlertDialog(
            contentPadding: EdgeInsets.all(5),
            backgroundColor: Color(0xFF333A47),
            title: Text(_branchNotice.length > 0 ? '공지사항' : '광고', style: TextStyle(fontSize: 15, color: Colors.white)),
            content: Container(
              margin: EdgeInsets.all(5),

                constraints : BoxConstraints(maxHeight: 400),
                child: SingleChildScrollView(
                    child: Column(
                      children: [
                        getAdKakaoFit('Attendi-web-userScreen4'),
                        if(_branchNotice.length > 0) Text(_branchNotice,style: TextStyle(color: Colors.white70), textAlign: TextAlign.left,),
                      ],
                    )
                )
        ),
            actions: <Widget>[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context, 'Do not show again');
                      UserDatabase.addUserItem(companyId: widget.companyId,userUid: _userId, key: 'noticeShow', value: DateTime.now().toString());
                    },
                    child: Text('1일간 열지않기', style: TextStyle(color: Colors.grey),),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context, 'Cancel');
                    },
                    child: const Text('닫기'),
                  ),
                ],
              )
            ],
          )
        );
      }

    });

    UserDatabase.getItemCollection(companyId: widget.companyId, userUid: userId)
        .get()
        .then((QuerySnapshot querySnapshot) {
      querySnapshot.docs.forEach((doc) {
        var dateInfo = doc.data()! as Map<String, dynamic>;
        String id = doc.id;
        DateTime date = DateFormat('yyyy-MM-dd').parse(id);
        if (date != null) {
          if(date.isBefore(DateTime.now().subtract(Duration(days:100)))){
            //print('Data deleted! user : $userId , date : $date');
            //UserDatabase.deleteDoc(companyId: widget.companyId, userUid: userId, date: id).then((value) => print('Data deleted! user : $userId , date : $date'));
          }
          else{
            setState(() {
              dateInfo.forEach((key, value) {
                if (key == 'start') {
                  if (value != null && value.length > 0) {
                    _startTime[date] = stringToTimeOfDay(value);
                  }
                }
                else if (key == 'end') {
                  if (value != null && value.length > 0) {
                    _endTime[date] = stringToTimeOfDay(value);
                  }
                }
                else if (key == 'duration') {
                  if (value != null && value.length > 0) {
                    _durationTime[date] = double.parse(value);
                    _rangeMap[date] = _durationTime[date].toString();
                  }
                }
                else if (key == 'rest') {
                  if (value != null && value.length > 0) {
                    _restTime[date] = double.parse(value);
                  }
                }
                else if (key == 'text') {
                  if (value != null && value.length > 0) {
                    _workDiary[date] = value;
                  }

                  _inputController.text = _workDiary[_selectedDate]??_branchDiaryFormat;
                }
              });
              _totalWorkingTime = _updateTotalWorkingTime(_selectedDate);
              _selectedRestHour = _restTime[_selectedDate] ?? 0;

              _selectedTimeFrom = _startTime[_selectedDate] ?? TimeOfDay(hour: TimeOfDay.now().hour, minute: (TimeOfDay.now().minute / _minuteInterval).floor() * _minuteInterval);
              _selectedTimeTo = _endTime[_selectedDate] ?? TimeOfDay(hour: TimeOfDay.now().hour, minute: (TimeOfDay.now().minute / _minuteInterval).floor() * _minuteInterval);

              if (_restTime[_selectedDate] != null) {
                //_updateSelectedRestHour();
              }
              _updateRestTimeRef(_selectedDate);
            });
          }
        }
      });
    });
  }

  void getDailyDataFromUserDoc(String userId, String date){
    UserDatabase.getExpenseItemCollection(companyId: widget.companyId, userUid: userId, date: date).get().then((QuerySnapshot querySnapshot) {
      setState((){
        _listExpense.clear();
        _listExpenseOrg.clear();
      });
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
        setState((){
          _listExpense.add(expenseItem);
          _listExpenseOrg.add(expenseItem);
        });
      });
    });
  }

  void _getDurationTime(DateTime date) async {
    if (_startTime[date] != null && _endTime[date] != null) {
      double start = _startTime[date]!.hour + _startTime[date]!.minute / 60;
      double end = _endTime[date]!.hour + _endTime[date]!.minute / 60;

      if (end > start) {
        double duration = end - start;
        if (duration > 0) {
          setState(() {
            double restTime = _restTime[date] ?? 0;
            _durationTime[date] =
            (duration - restTime) < 0 ? 0 : (duration - restTime);
            _rangeMap[date] = _durationTime[_selectedDate].toString();
            _totalWorkingTime = _updateTotalWorkingTime(_selectedDate);
          });
          String dbDate = DateFormat('yyyy-MM-dd').format(date);
          await UserDatabase.addUserDateItem(companyId: widget.companyId,
              userUid: _userId,
              date: dbDate,
              key: "duration",
              value: _durationTime[date].toString());

          dbDate =
              DateFormat('yyyy-MM-dd').format(DateTime(date.year, date.month));
          await UserDatabase.addUserDateItem(companyId: widget.companyId,
              userUid: _userId,
              date: dbDate,
              key: "total",
              value: _totalWorkingTime.toString());
        }
      }
      else{
        setState(() {
          _durationTime[date] = 0;
          _rangeMap[date] = '';
          _totalWorkingTime = _updateTotalWorkingTime(_selectedDate);
        });
        String dbDate = DateFormat('yyyy-MM-dd').format(date);
        await UserDatabase.addUserDateItem(companyId: widget.companyId,
            userUid: _userId,
            date: dbDate,
            key: "duration",
            value: _durationTime[date].toString());

        dbDate = DateFormat('yyyy-MM-dd').format(DateTime(date.year, date.month));
        await UserDatabase.addUserDateItem(companyId: widget.companyId,
            userUid: _userId,
            date: dbDate,
            key: "total",
            value: _totalWorkingTime.toString());
      }
    }
    else {
      setState(() {
        _durationTime[date] = 0;
        _rangeMap[date] = '';
        _totalWorkingTime = _updateTotalWorkingTime(_selectedDate);
      });
      String dbDate = DateFormat('yyyy-MM-dd').format(date);
      await UserDatabase.addUserDateItem(companyId: widget.companyId,
          userUid: _userId,
          date: dbDate,
          key: "duration",
          value: _durationTime[date].toString());

      dbDate = DateFormat('yyyy-MM-dd').format(DateTime(date.year, date.month));
      await UserDatabase.addUserDateItem(companyId: widget.companyId,
          userUid: _userId,
          date: dbDate,
          key: "total",
          value: _totalWorkingTime.toString());
    }
  }

  String _getWorkDiaryHdr() {
    String workDiaryHdr = '';

    if (_selectedTimeFrom != null && _selectedTimeTo != null){
      double start = _selectedTimeFrom!.hour + _selectedTimeFrom!.minute / 60;
      double end = _selectedTimeTo!.hour + _selectedTimeTo!.minute / 60;
      double duration = 0;
      if (end > start) {
        duration = (end - start - _selectedRestHour) < 0 ? 0 : (end -
            start - _selectedRestHour);
      }

      workDiaryHdr = "출근 : " + _selectedTimeFrom!.format(context)
          + " / 퇴근 : " + _selectedTimeTo!.format(context);

      workDiaryHdr += "\n근무 : " + duration.toString() + '시간';
      if (_selectedRestHour != null && _selectedRestHour > 0.0) {
        workDiaryHdr += " / 휴식 : " + _selectedRestHour.toString() + '시간';
      }
    }
    return workDiaryHdr;
  }

  _updateTotalWorkingTime(DateTime date) {
    double total = 0;
    _durationTime.forEach((key, value) {
      if (key.year == date.year && key.month == date.month) {
        total += value;
      }
    });
    return total;
  }

  Widget? _buildFloatingActionButton() {
    if(!_fillCalendar){
      return
        Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Container(
              margin: EdgeInsets.only(right: 10),
              height: 40,
              width: 80,
              alignment: Alignment.center,
              child:
                  WebViewAware(
                    child: FloatingActionButton.extended(
                      elevation: 5,
                      backgroundColor: Colors.blue[300],
                      icon: Icon(Icons.undo, color: Colors.white,),
                      label: Text('취소', style: TextStyle(color: Colors.white70)),
                      extendedIconLabelSpacing: 5,
                      onPressed: (){
                        setState((){
                          //_fillCalendar = true;
                          //_calendarFormat = CalendarFormat.month;
                          _calendarExpand = true;
                          _calendarHeight += 1;
                          _calendarExpandDuration = 10;
                        });
                      },
                    ),
                  ),
            ),
            Container(
              height: 40,
              width: 80,
              alignment: Alignment.center,
              child: WebViewAware(
                child: FloatingActionButton.extended(
                  elevation: 5,
                  backgroundColor: Colors.redAccent[100],
                  icon: Icon(Icons.save, color: Colors.white,),
                  label: Text('저장', style: TextStyle(color: Colors.white70)),
                  extendedIconLabelSpacing: 5,
                  onPressed: () async{
                    bool changed = false;
                    List<ExpenseItem> tempExpense = [];
                    for(int i = 0; i < _listExpense.length; i++){
                      if(_listExpense[i].type != null && _listExpense[i].type!.length > 0){
                        if(_listExpense[i].money != null && _listExpense[i].money!.length > 0){

                        }
                        else{
                          Fluttertoast.showToast(msg: '지출 내역 오류! 지출 금액을 입력하세요.', timeInSecForIosWeb: 2, webPosition: "center", backgroundColor: Colors.redAccent,);
                          return;
                        }
                      }

                      if(_listExpense[i].detail != null && _listExpense[i].detail!.length > 0){
                        if(_listExpense[i].money != null && _listExpense[i].money!.length > 0){

                        }
                        else{
                          Fluttertoast.showToast(msg: '지출 내역 오류! 지출 금액을 입력하세요.', timeInSecForIosWeb: 2, webPosition: "center", backgroundColor: Colors.redAccent,);
                          return;
                        }
                      }

                      if(_listExpense[i].money != null && _listExpense[i].money!.length > 0){
                        if(_listExpense[i].type != null && _listExpense[i].type!.length > 0){
                          tempExpense.add(_listExpense[i]);
                        }
                        else{
                          Fluttertoast.showToast(msg: '지출 내역 오류! 지출 유형을 선택하세요.', timeInSecForIosWeb: 2, webPosition: "center", backgroundColor: Colors.redAccent,);
                          return;
                        }
                      }
                    }

                    int curIdx = 0;
                    for(int i = 0; i < _checkList.length; i++){
                      if(_checkList[i].writetime.isBefore(_selectedDate) || _checkList[i].writetime.isAtSameMomentAs(_selectedDate)){
                        if(curChecked[curIdx] != null){
                          setState((){
                            if(curChecked[curIdx++]!){
                              if(_checkList[i].checked[_selectedDate] == 'false'){
                                _checkList[i].checked[_selectedDate] = widget.user;
                              }
                            }
                            else{
                              _checkList[i].checked[_selectedDate] = 'false';
                            }

                          });
                          BranchDatabase.addCheckItem(companyId: widget.companyId, branch: widget.workplace
                              , checkId: i, key: _selectedDateDB, value: (_checkList[i].checked[_selectedDate]??'false'));
                        }
                      }
                    }
                    for(int i = 0; i < _listExpenseOrg.length; i++){
                      await UserDatabase.deleteExpenseDoc(companyId: widget.companyId, userUid: _userId,
                          date: _selectedDateDB, expenseId: i);
                    }
                    for(int i = 0; i < tempExpense.length; i++){
                      if(tempExpense[i].type != null && tempExpense[i].type!.length > 0){
                        UserDatabase.addUserDateExpenseItem(
                            companyId: widget.companyId,
                            userUid: _userId,
                            date: _selectedDateDB,
                            expenseId: i,
                            key: "type",
                            value: tempExpense[i].type!);
                      }
                      if(tempExpense[i].money != null && tempExpense[i].money!.length > 0){
                        UserDatabase.addUserDateExpenseItem(
                            companyId: widget.companyId,
                            userUid: _userId,
                            date: _selectedDateDB,
                            expenseId: i,
                            key: "money",
                            value: tempExpense[i].money!);
                      }
                      if(tempExpense[i].detail != null && tempExpense[i].detail!.length > 0){
                        UserDatabase.addUserDateExpenseItem(
                            companyId: widget.companyId,
                            userUid: _userId,
                            date: _selectedDateDB,
                            expenseId: i,
                            key: "detail",
                            value: tempExpense[i].detail!);
                      }
                    }

                    if(_inputController.text != _branchDiaryFormat){
                      setState((){
                        _workDiary[_selectedDate] = _inputController.text;
                      });

                      if(_workDiary[_selectedDate] != null && _workDiary[_selectedDate]!.length > 0) {
                        UserDatabase.addUserDateItem(
                            companyId: widget.companyId,
                            userUid: _userId,
                            date: _selectedDateDB,
                            key: "text",
                            value: _workDiary[_selectedDate]!);
                        changed = true;
                      }
                    }

                    if (_selectedTimeFrom != null && _selectedTimeTo != null) {
                      setState((){
                        _startTime[_selectedDate] = _selectedTimeFrom!;
                        _endTime[_selectedDate] = _selectedTimeTo!;
                      });
                      UserDatabase.addUserDateItem(companyId: widget.companyId,
                          userUid: _userId,
                          date: _selectedDateDB,
                          key: "start",
                          value: _selectedTimeFrom!.format(context));


                      UserDatabase.addUserDateItem(companyId: widget.companyId,
                          userUid: _userId,
                          date: _selectedDateDB,
                          key: "end",
                          value: _selectedTimeTo!.format(context));

                      if(_selectedRestHour != null && _selectedRestHour >= 0){
                        setState((){
                          _restTime[_selectedDate] = _selectedRestHour;
                        });

                        UserDatabase.addUserDateItem(companyId: widget.companyId,
                            userUid: _userId,
                            date: _selectedDateDB,
                            key: "rest",
                            value: _selectedRestHour.toString());
                      }
                      changed = true;
                    }
                    _getDurationTime(_selectedDate);

                    //_fillCalendar = true;
                    //_calendarFormat = CalendarFormat.month;
                    if(changed){
                      setState((){
                        _calendarExpand = true;
                        _calendarHeight += 1;
                        _calendarExpandDuration = 10;
                      });

                      Fluttertoast.showToast(msg: '근무기록이 저장되었습니다.', timeInSecForIosWeb: 2, webPosition: "center");
                    }
                    else{
                      Fluttertoast.showToast(msg: '근무기록 오류! 근무 시간을 확인하세요', timeInSecForIosWeb: 2, webPosition: "center", backgroundColor: Colors.redAccent,);
                    }
                  },
                ),),
            )
          ],
        );
    }
    else{
      return  SpeedDial(
        overlayOpacity: 0,
        elevation: 5,
        buttonSize: Size(40,40),
        childrenButtonSize: Size(40,40),
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
              backgroundColor: Colors.redAccent[100],
              labelBackgroundColor: Colors.blueGrey,
              child: Icon(Icons.delete_outline, color: Colors.white),
              label: '근무기록 삭제',
              labelStyle: TextStyle(color: Colors.white),
              onTap: () {
                showDialog<String>(
                  context: context,
                  builder: (BuildContext context) =>
                      AlertDialog(
                        backgroundColor: Color(0xFF333A47),
                        title: Text(
                          _selectedDate.month.toString() + '월 ' +
                              _selectedDate.day.toString() + '일', style: TextStyle(color: Colors.white70),),
                        content: const Text('근무 기록을 삭제하시겠습니까?', style: TextStyle(color: Colors.white70)),
                        actions: <Widget>[
                          TextButton(
                            onPressed:
                            (() async {
                              await UserDatabase.deleteDoc(
                                  companyId: widget.companyId,
                                  userUid: _userId,
                                  date: DateFormat('yyyy-MM-dd').format(
                                      _selectedDate)).then((value) =>
                                  setState(() {
                                    _startTime.remove(_selectedDate);
                                    _endTime.remove(_selectedDate);
                                    _durationTime.remove(_selectedDate);
                                    _restTime.remove(_selectedDate);
                                    _workDiary.remove(_selectedDate);
                                    _rangeMap.remove(_selectedDate);

                                    _selectedTimeFrom = null;
                                    _selectedTimeTo = null;
                                    _selectedRestHour = 0;
                                    _inputController.text = "";
                                    _totalWorkingTime =
                                        _updateTotalWorkingTime(
                                            _selectedDate);
                                  }),
                              );

                              await UserDatabase.getExpenseItemCollection(companyId: widget.companyId, userUid: _userId, date: DateFormat('yyyy-MM-dd').format(_selectedDate)).get().then((QuerySnapshot querySnapshot2) {
                                for(int i = 0; i < querySnapshot2.docs.length; i++){
                                  UserDatabase.deleteExpenseDoc(companyId: widget.companyId, userUid: _userId, date: DateFormat('yyyy-MM-dd').format(_selectedDate), expenseId: i);
                                }
                              });

                              await UserDatabase.addUserDateItem(
                                  companyId: widget.companyId,
                                  userUid: _userId,
                                  date: DateFormat('yyyy-MM-dd').format(
                                      DateTime(_selectedDate.year,
                                          _selectedDate.month)),
                                  key: "total",
                                  value: _totalWorkingTime.toString());
                              Navigator.pop(context, 'Ok');
                            }),
                            child: Text('Ok',style: TextStyle(color: Colors.teal[200])),
                          ),
                          TextButton(
                            onPressed: () =>
                                Navigator.pop(context, 'Cancel'),
                            child: Text('Cancel',style: TextStyle(color: Colors.teal[200])),
                          ),
                        ],
                      ),);
              }
          ),
          SpeedDialChild(
            child: _userLocked? Icon(Icons.lock_open, color: Colors.white) : Icon(Icons.lock_outline, color: Colors.white),
            backgroundColor: Colors.redAccent[100],
            labelBackgroundColor: Colors.blueGrey,
            labelShadow: [BoxShadow(color: Colors.black12), BoxShadow(color: Colors.black12)],
            label: _userLocked? '잠금 해제' : '계정 잠금',
            labelStyle: TextStyle(color: Colors.white),
            onTap: (){
              setState((){
                if(_userLocked == false){
                  showDialog<String>(
                    context: context,
                    builder: (BuildContext context) => AlertDialog(
                      backgroundColor: Color(0xFF333A47),
                      title: const Text('비밀번호를 설정하시겠습니까?', style: TextStyle(fontSize: 15, color: Colors.white)),
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
                                labelText: 'New Password',
                                labelStyle: TextStyle(color: Colors.white70),
                              ),
                              onChanged: ((value) => {
                                setState(() {
                                  _passwordNew = value;
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
                              UserDatabase.addUserItem(companyId: widget.companyId,userUid: _userId, key: 'password', value: _passwordNew);
                              _userLocked = !_userLocked;
                              Navigator.pop(context, 'Ok');
                            })
                          },
                          child: const Text('Ok'),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context, 'Cancel');
                            _passwordNew = "";
                          },
                          child: const Text('Cancel'),
                        ),
                      ],
                    ),);
                }
                else{
                  showDialog<String>(
                    context: context,
                    builder: (BuildContext context) => AlertDialog(
                      backgroundColor: Color(0xFF333A47),
                      title: const Text('잠금을 해제하시겠습니까?', style: TextStyle(fontSize: 15, color: Colors.white)),

                      actions: <Widget>[
                        TextButton(
                          onPressed: () => {
                            setState((){
                              UserDatabase.addUserItem(companyId: widget.companyId,userUid: _userId, key: 'password', value: "");
                              _passwordRef = "";
                              _userLocked = !_userLocked;
                              Navigator.pop(context, 'Ok');
                            })
                          },
                          child: const Text('Ok'),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context, 'Cancel');
                            _passwordNew = "";
                          },
                          child: const Text('Cancel'),
                        ),
                      ],
                    ),);
                }

              });
            }
          ),
          SpeedDialChild(
            child: _branchNotice.length > 0 ? Icon(Icons.notification_important_outlined, color: Colors.white,) : Icon(Icons.notifications_none, color: Colors.white,),
            backgroundColor: Colors.redAccent[100],
            labelBackgroundColor: Colors.blueGrey,
            labelShadow: [BoxShadow(color: Colors.black12), BoxShadow(color: Colors.black12)],
            label: '공지사항',
            labelStyle: TextStyle(color: Colors.white),
            onTap: (){
              showDialog<String>(
                context: context,
                builder: (BuildContext context) => AlertDialog(
                  backgroundColor: Color(0xFF333A47),
                  title: const Text('공지사항', style: TextStyle(fontSize: 15, color: Colors.white)),
                  content: Container(
                      child: _branchNotice.length > 0 ?
                      Text(_branchNotice,style: TextStyle(color: Colors.white70), textAlign: TextAlign.left,) :
                      Text("등록된 공지사항이 없습니다.", style: TextStyle(color: Colors.white70),textAlign: TextAlign.left)
                  ),
                  actions: <Widget>[
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context, 'Cancel');
                      },
                      child: const Text('Close'),
                    ),
                  ],
                ),);
            },
          ),
          SpeedDialChild(
            child: Icon(Icons.no_accounts, color: Colors.white,),
            backgroundColor: Colors.redAccent[100],
            labelBackgroundColor: Colors.blueGrey,
            labelShadow: [BoxShadow(color: Colors.black12), BoxShadow(color: Colors.black12)],
            label: '회원탈퇴',
            labelStyle: TextStyle(color: Colors.white),
            onTap: (){
              showDialog<String>(
                context: context,
                builder: (BuildContext context) => AlertDialog(
                  backgroundColor: Color(0xFF333A47),
                  title: const Text('회원탈퇴', style: TextStyle(fontSize: 15, color: Colors.white)),
                  content: Container(
                      child: Text("탈퇴하시겠습니까? 모든 기록이 삭제됩니다.", style: TextStyle(color: Colors.white70),textAlign: TextAlign.left)
                  ),
                  actions: <Widget>[
                    TextButton(
                      onPressed: () async{
                        await UserDatabase.deleteUser(companyId: widget.companyId, userUid: _userId);

                        UserDatabase.getItemCollection(companyId: widget.companyId, userUid: _userId).get().then((QuerySnapshot querySnapshot) {
                          querySnapshot.docs.forEach((doc) {
                            UserDatabase.deleteDoc(companyId: widget.companyId, userUid: _userId, date: doc.id);
                            UserDatabase.getExpenseItemCollection(companyId: widget.companyId, userUid: _userId, date: doc.id).get().then((QuerySnapshot querySnapshot2) {
                              for(int i = 0; i < querySnapshot2.docs.length; i++){
                                UserDatabase.deleteExpenseDoc(companyId: widget.companyId, userUid: _userId, date: doc.id, expenseId: i);
                              }
                            });
                          });
                        });

                        Navigator.pop(context, 'Ok');
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                settings: RouteSettings(name: '/'+ widget.companyId),
                                builder: (context) => UserLoginPage(companyId: widget.companyId, title: 'Attendi'))
                        );
                      },
                      child: const Text('Ok'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context, 'Cancel');
                      },
                      child: const Text('Cancel'),
                    ),
                  ],
                ),);
            },
          )
        ],
      );


    }
  }
}



class ExpenseItem{
  String? type;
  String? money;
  String? detail;
}
