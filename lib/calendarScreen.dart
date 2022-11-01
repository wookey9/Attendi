import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'branch_Database.dart';
import 'user_Database.dart';
import 'package:interval_time_picker/interval_time_picker.dart';
import 'package:time_range_picker/time_range_picker.dart';
import 'package:fluttertoast/fluttertoast.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({Key? key, required this.companyId, required this.title,
    required this.user,required this.workplace,
  }) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;
  final String user;
  final String workplace;
  final String companyId;

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {

  late DateTime _selectedDay;
  late DateTime _focusedDay;
  var _calendarFormat = CalendarFormat.month;
  late Map<DateTime, TimeOfDay> _startTime;
  late Map<DateTime, TimeOfDay> _endTime;
  late Map<DateTime, double> _durationTime;
  late Map<String,Map<DateTime, double>> _durationTimeAdmin;
  late Map<DateTime, double> _restTime;
  late String _startTimePrint = "입력";
  late String _endTimePrint = "입력";
  late double _selectedRestTime = 0;
  late double _totalWorkingTime = 0;
  late String _appTitle;
  final List<String> _branchList = [];
  late List<ListTile> _userListTiles = [];
  late List<String> _userIdList = [];
  late Map<String,double> _userPayPerHour = {};

  TextEditingController _restTimeEditingController = TextEditingController();
  TextEditingController _payEditingController = TextEditingController();
  double _lowestPay = 9160;

  TimeOfDay _startInput = TimeOfDay.now();
  TimeOfDay _endInput = TimeOfDay.now();
  double _durationInput = 0;

  late Map<String,double> payLatestMonth = {};
  late Map<String,double> payPrevMonth = {};

  late double _totalPayLatestMonth = 0;
  late double _totalPayPrevMonth = 0;

  FToast fToast = FToast();

  @override
  void initState()
  {
    _startTime = {};
    _endTime = {};
    _durationTime = {};
    _restTime = {};
    _durationTimeAdmin = {};
    _userPayPerHour = {};
    _selectedDay = DateTime(DateTime.now().year,DateTime.now().month,DateTime.now().day);
    _focusedDay = DateTime.now();

    try{
      BranchDatabase.getBranchCollection(companyId: widget.companyId).get().then((QuerySnapshot querySnapshot){
        setState(() {
          querySnapshot.docs.forEach((doc) {
            //CompanyList[doc.id]
            _branchList.add(doc.id);
          });
        });
      });
    }
    catch(e){
      print(e);
    }

    if(widget.user == 'admin123' && widget.workplace == 'admin_mode'){
      _appTitle = "Administrator";
    }
    else{
      _appTitle = widget.user.replaceAll('-', '').trim() + " - [" + widget.workplace + "]";
    }
    fToast.init(context);
  }

  @override

  TimeOfDay stringToTimeOfDay(String tod) {
    final format = DateFormat.jm(); //"6:00 AM"
    return TimeOfDay.fromDateTime(format.parse(tod));
  }

  void getDataFromUserDoc(String userId){
    UserDatabase.getItemCollection(companyId: widget.companyId,userUid: userId).get().then((QuerySnapshot querySnapshot) {
      querySnapshot.docs.forEach((doc) {
        var dateInfo = doc.data()! as Map<String,dynamic>;
        String id = doc.id;
        DateTime date = DateFormat('yyyy-MM-dd').parse(id);
        if(date != null){
          dateInfo.forEach((key, value) {
            if(key == 'start'){
              if(value != null && value.length > 0){
                _startTime[date] = stringToTimeOfDay(value);
              }
            }
            else if(key == 'end'){
              if(value != null && value.length > 0){
                _endTime[date] = stringToTimeOfDay(value);
              }
            }
            else if(key == 'duration'){
              if(value != null && value.length > 0){
                _durationTime[date] = double.parse(value);
              }
            }
            else if(key == 'rest'){
              if(value != null && value.length > 0){
                _restTime[date] = double.parse(value);
              }
            }
          });
          _totalWorkingTime = _updateTotalWorkingTime(_selectedDay);
          _startTimePrint = _getStartTime();
          _endTimePrint = _getEndTime();

          _selectedRestTime = _restTime[DateTime(_selectedDay.year,_selectedDay.month,_selectedDay.day)]??0;
          _restTimeEditingController.text = _selectedRestTime.toString();
          _restTimeEditingController.selection = TextSelection.fromPosition(TextPosition(offset: _restTimeEditingController.text.length));
        }

      });
    });
  }


  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return getCalendarWidget();
  }

  Widget getCalendarWidget()
  {
    getDataFromUserDoc(_appTitle);
    return Scaffold(
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            Container(alignment: Alignment.topLeft,child: Text(_appTitle,style: const TextStyle(fontSize: 17),  textAlign:
            TextAlign.left),),
          Container(
            alignment: Alignment.bottomLeft,
            child:Text(_selectedDay.month.toString() + "월 근무 시간 : " + _totalWorkingTime.toStringAsFixed(1),style: const TextStyle(fontSize: 15), textAlign:
              TextAlign.left,)
          )

          ],
        ),
      ),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Column(
          // Column is also a layout widget. It takes a list of children and
          // arranges them vertically. By default, it sizes itself to fit its
          // children horizontally, and tries to be as tall as its parent.
          //
          // Invoke "debug painting" (press "p" in the console, choose the
          // "Toggle Debug Paint" action from the Flutter Inspector in Android
          // Studio, or the "Toggle Debug Paint" command in Visual Studio Code)
          // to see the wireframe for each widget.
          //
          // Column has various properties to control how it sizes itself and
          // how it positions its children. Here we use mainAxisAlignment to
          // center the children vertically; the main axis here is the vertical
          // axis because Columns are vertical (the cross axis would be
          // horizontal).
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            Container(
              margin: EdgeInsets.fromLTRB(10,0,10,0),
              child: TableCalendar(
                rowHeight: 40,
                firstDay: DateTime.utc(DateTime.now().year-2, 1, 1),
                lastDay: DateTime.utc(DateTime.now().year+2, 12, 31),
                focusedDay: _focusedDay,
                headerStyle: const HeaderStyle(
                  headerMargin: EdgeInsets.only(left: 40, top: 0, right: 40, bottom: 0),
                  titleCentered: true,
                  titleTextStyle: TextStyle(fontSize: 17.0),
                  formatButtonVisible: true,
                ),
                daysOfWeekHeight: 30,
                daysOfWeekStyle: DaysOfWeekStyle(
                  weekdayStyle: Theme.of(context).textTheme.bodyLarge!,
                  weekendStyle: TextStyle().copyWith(color: Colors.red),
                ),
                calendarStyle: CalendarStyle(
                  outsideDaysVisible: false,

                ),
                calendarFormat: _calendarFormat,
                selectedDayPredicate: (day) {
                  return isSameDay(_selectedDay, day);
                },
                onFormatChanged: (format){
                  setState((){
                    _calendarFormat = format;
                  });
                },

                onDaySelected: (selectedDay, focusedDay) {
                  setState(() {
                    _selectedDay = DateTime(selectedDay.year,selectedDay.month,selectedDay.day);
                    _focusedDay = focusedDay; // update `_focusedDay` here as well
                    _startTimePrint = _getStartTime();
                    _endTimePrint = _getEndTime();
                    _selectedRestTime = _restTime[DateTime(_selectedDay.year,_selectedDay.month,_selectedDay.day)]??0;
                    _restTimeEditingController.text = _selectedRestTime.toString();
                    _restTimeEditingController.selection = TextSelection.fromPosition(TextPosition(offset: _restTimeEditingController.text.length));
                  });
                },
                calendarBuilders: calendarBuilder(),

                onPageChanged: (focusedDay) {
                  setState(() {
                    _focusedDay = focusedDay; // update `_focusedDay` here as well
                    _selectedDay = DateTime(_focusedDay.year,_focusedDay.month,_focusedDay.day);
                    _totalWorkingTime = _updateTotalWorkingTime(_selectedDay);
                    _selectedRestTime = _restTime[DateTime(_selectedDay.year,_selectedDay.month,_selectedDay.day)]??0;
                    _restTimeEditingController.text = _selectedRestTime.toString();
                    _restTimeEditingController.selection = TextSelection.fromPosition(TextPosition(offset: _restTimeEditingController.text.length));
                  });
                },


              ),
            ),
            Expanded(
                child : ListView(
                  children: <Widget>[
                    ListTile(
                      title: Row(
                        mainAxisSize: MainAxisSize.max,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Expanded(
                            child: Container(
                              alignment: Alignment.center,
                              margin: const EdgeInsets.all(3.0),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.blue, width: 2),
                                borderRadius: BorderRadius.all(Radius.circular(8.0))
                              ),
                              child:TextButton( child : Column(
                                children: [
                                  const Text('출근 시간'),
                                  Text(_startTimePrint, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),),
                                ],
                              ),
                              onPressed: (){setTimeRange();},)
                            ,)
                          ),
                          Expanded(
                            child : Container(
                              alignment: Alignment.center,
                              margin: const EdgeInsets.all(3.0),
                              decoration: BoxDecoration(
                                  border: Border.all(color: Colors.blue, width: 2),
                                  borderRadius: const BorderRadius.all(Radius.circular(8.0)),
                                ),
                                child: TextButton(child: Column(
                                  children: [
                                    const Text('퇴근 시간'),
                                    Text(_endTimePrint, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),),
                                  ],
                                ),
                                onPressed: (){setTimeRange();},),
                              ),
                          ),
                        ],
                      )
                    ),
                    ListTile(
                      title: Row(
                        mainAxisSize: MainAxisSize.max,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Expanded(
                              child: Container(
                                alignment: Alignment.center,
                                margin: const EdgeInsets.all(3.0),
                                decoration: BoxDecoration(
                                    border: Border.all(color: Colors.red, width: 2),
                                    borderRadius: BorderRadius.all(Radius.circular(8.0))
                                ),
                                child: Row(
                                  children: [
                                    IconButton(onPressed: (){setState(() {
                                      double rest = _restTime[_selectedDay]??0;
                                      rest -= 0.5;
                                      if(rest < 0) rest = 0;
                                      _restTime[_selectedDay] = rest;
                                      _selectedRestTime = rest;
                                      _getDurationTime(_selectedDay);
                                      String dbDate = DateFormat('yyyy-MM-dd').format(_selectedDay);
                                      UserDatabase.addUserDateItem(companyId: widget.companyId,userUid: _appTitle, date: dbDate, key: "rest", value: _selectedRestTime.toString());
                                    });},
                                      icon: Icon(Icons.arrow_left),
                                      padding: EdgeInsets.all(0),

                                    ),
                                    Expanded(
                                      child:Column(
                                        children: [
                                          const Text('휴식 시간', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),),
                                          Text((_restTime[_selectedDay]??0).toString(), textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),),
                                        ],
                                      )
                                    ),
                                    IconButton(onPressed: (){setState(() {
                                      double rest = _restTime[_selectedDay]??0;
                                      rest += 0.5;
                                      _restTime[_selectedDay] = rest;
                                      _selectedRestTime = rest;
                                      _getDurationTime(_selectedDay);
                                      String dbDate = DateFormat('yyyy-MM-dd').format(_selectedDay);
                                      UserDatabase.addUserDateItem(companyId: widget.companyId,userUid: _appTitle, date: dbDate, key: "rest", value: _selectedRestTime.toString());
                                    });}, icon: Icon(Icons.arrow_right))
                                  ],
                                )
                              )
                          ),
                          Expanded(
                            child :Container(
                              alignment: Alignment.center,
                              margin: const EdgeInsets.all(3.0),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.green, width: 2),
                                borderRadius: BorderRadius.all(Radius.circular(8.0))
                              ),
                              child : Row(
                                children: [
                                  Expanded(
                                    child: Container(
                                      margin : EdgeInsets.fromLTRB(40, 0, 0,0),
                                      child: Column(
                                        children: [
                                          Text('근무 시간', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),),
                                          Text((_durationTime[_selectedDay]??0).toString(), textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),),
                                        ],
                                      )
                                    ),
                                  ),
                                  CloseButton(
                                  onPressed: () {
                                    showDialog<String>(
                                      context: context,
                                      builder: (BuildContext context) => AlertDialog(
                                        title: Text(_selectedDay.month.toString() + '월 '+ _selectedDay.day.toString() + '일'),
                                        content: const Text('근무 기록을 삭제하시겠습니까?'),
                                        actions: <Widget>[
                                          TextButton(
                                            onPressed:
                                            (() async{
                                              await UserDatabase.deleteDoc(companyId: widget.companyId,userUid: _appTitle, date: DateFormat('yyyy-MM-dd').format(_selectedDay)).then((value) =>
                                                  setState(() {
                                                    _startTime.remove(_selectedDay);
                                                    _endTime.remove(_selectedDay);
                                                    _durationTime.remove(_selectedDay);
                                                    _restTime.remove(_selectedDay);

                                                    _startTimePrint = "입력";
                                                    _endTimePrint = "입력";
                                                    _selectedRestTime = 0;
                                                    _totalWorkingTime = _updateTotalWorkingTime(_selectedDay);

                                                  }),
                                              );
                                              await UserDatabase.addUserDateItem(companyId: widget.companyId,userUid: _appTitle, date: DateFormat('yyyy-MM-dd').format(DateTime(_selectedDay.year, _selectedDay.month)), key: "total", value: _totalWorkingTime.toString());
                                              Navigator.pop(context, 'Ok');
                                            }),
                                            child: const Text('Ok'),
                                          ),
                                          TextButton(
                                            onPressed: () => Navigator.pop(context, 'Cancel'),
                                            child: const Text('Cancel'),
                                          ),
                                        ],
                                      ),);
                                  }),
                                ],
                              )
                            )
                          ),
                        ],
                      )
                    ),
                  ],
                )
            ),
            /*
            Column(
              children: [
                Container(
                  margin: EdgeInsets.all(5),
                  child:

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center, // 가운데 정렬
                    children : <Widget>[
                      OutlinedButton( onPressed: _selectStartTime, child: Text(_startTimePrint)),
                      const Text((" ~ ")),
                      OutlinedButton(onPressed: _selectEndTime, child: Text(_endTimePrint)),
                    ],
                  ),


                ),
                Container(
                  margin: EdgeInsets.all(5),
                  child:  OutlinedButton(child: Text(_restTimePrint, style: TextStyle(color: Colors.red),), onPressed: (){
                    _inputRestTimeDialog(context).then((value) => {
                      setState((){
                        _restTimePrint = (_selectedRestTime > 0)? '제외 시간 : ' + _selectedRestTime.toString() : '제외 시간';
                      })
                    });
                  }),
                )
              ],
            ),

             */

          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: (){
          setTimeRange();
        },

        backgroundColor: Colors.green,
        child: const Icon(Icons.access_time),
      ),
    );
  }

  void setTimeRange() async{
    _startInput = getInitialStartTime();
    _endInput = getInitialEndTime();
    TimeRange? result = await showTimeRangePicker(
      context: context,
      start: getInitialStartTime(),
      end: getInitialEndTime(),
      onStartChange: (start) {
        setState(() {
          _startInput = start;
          double s = _startInput.hour + _startInput.minute/60;
          double e = _endInput.hour + _endInput.minute/60;
          if(e > s)
            _durationInput = e - s;
        });
        print("duruation : $_durationInput start time " + start.toString());
      },
      onEndChange: (end) {
        setState(() {
          _endInput = end;
          double s = _startInput.hour + _startInput.minute/60;
          double e = _endInput.hour + _endInput.minute/60;
          if(e > s)
            _durationInput = e - s;
        });
        print("duruation : $_durationInput end time " + end.toString());
      },
      interval: Duration(minutes: 30),
      minDuration: Duration(hours: 1),
      use24HourFormat: false,

      labels: [
        "7",
        "8",
        "9",
        "10",
        "11",
        "12",
        "13",
        "14",
        "15",
        "16",
        "17",
        "18",
        "19",
        "20",
        "21",
        "22",
        "23"
      ].asMap().entries.map((e) {
        return ClockLabel.fromIndex(
            idx: e.key + 7, length: 24, text: e.value);
      }).toList(),

      disabledTime: TimeRange(startTime: TimeOfDay(hour: 23,minute: 0), endTime: TimeOfDay(hour: 7,minute: 0)),
      labelStyle: const TextStyle(
        color: Colors.grey,
        fontSize: 13,
        ),
      strokeColor: Colors.blue.withOpacity(0.5),
      disabledColor: Colors.red.withOpacity(0.5),
      fromText: '출근 시간',
      toText: '퇴근 시간',
      //paintingStyle: PaintingStyle.fill,
      timeTextStyle: const TextStyle(fontSize: 20, color: Colors.white),
      activeTimeTextStyle: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
      ticksWidth: 1,
      ticks: 24,
      labelOffset: -20,
      builder:  (context, child) {
        return Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.only(top: 5),
              child: Container(
                alignment: Alignment.topCenter,
                height: 700,
                width: 400,
                child: child,
              ),
            ),
          ],
        );
      },
    );
    if(result == null){

    }
    else{
      setState(() {
        _startTime[_selectedDay] = _startInput;
        _endTime[_selectedDay] = _endInput;
        _startTimePrint = _getStartTime();
        _endTimePrint = _getEndTime();
        _getDurationTime(_selectedDay);
      });
      String dbDate = DateFormat('yyyy-MM-dd').format(_selectedDay);
      await UserDatabase.addUserDateItem(companyId: widget.companyId,userUid: _appTitle, date: dbDate, key: "start", value: _startInput.format(context));
      await UserDatabase.addUserDateItem(companyId: widget.companyId,userUid: _appTitle, date: dbDate, key: "end", value: _endInput.format(context));
    }
  }

  TimeOfDay getInitialStartTime(){

    TimeOfDay start = TimeOfDay(hour: TimeOfDay.now().hour, minute: 0);

    if(start.hour >= 23)
      start = TimeOfDay(hour: 20, minute: 0);

    else if(start.hour < 7)
      start = TimeOfDay(hour: 7, minute: 0);

    if(_startTime[_selectedDay] != null){
      start = _startTime[_selectedDay]!;
    }

    return start;
  }

  TimeOfDay getInitialEndTime(){
    TimeOfDay start = getInitialStartTime();
    TimeOfDay end = TimeOfDay(hour: start.hour + 3, minute: 0);

    if(_endTime[_selectedDay] != null){
      end = _endTime[_selectedDay]!;
    }

    return end;
  }

  AnimatedContainer buildCalendarDayMarker({
    required String text,
    required Color color,
  }) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 300),
      decoration: BoxDecoration(
        shape: BoxShape.rectangle,
        borderRadius: BorderRadius.circular(3),
        color: color,
      ),
      width: 30,

      height: 13,
      child: Center(
        child: Text(
          text,
          style: TextStyle().copyWith(
            fontSize: 13.0,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildEventsMarkerNum(DateTime day) {
    if(_durationTime[day] != null)
    {
      return buildCalendarDayMarker(
        text: _durationTime[day]!.toStringAsFixed(1), color: Colors.green,
      );
    }
    else if(_startTime[day] != null || _endTime[day] != null || (_durationTime[day]??1) == 0 ){
      return buildCalendarDayMarker(
          text: '!', color: Colors.yellow,
      );
    }
    else
    {
      return Container();
    }

  }

  CalendarBuilders calendarBuilder() {
    return CalendarBuilders(
      markerBuilder: (context, date, events) {
        DateTime date2 = DateTime(date.year, date.month, date.day);
        return _buildEventsMarkerNum(date2);
      },
    );
  }

  void _getDurationTime(DateTime date) async{
    if(_startTime[date]!=null && _endTime[date]!=null)
    {
      double start = _startTime[date]!.hour + _startTime[date]!.minute/60;
      double end = _endTime[date]!.hour + _endTime[date]!.minute/60;

      if(end > start)
      {
        double duration = end - start;
        if(duration > 0) {
          setState(() {
            double restTime = _restTime[date]??0;
            _durationTime[date] = (duration - restTime) < 0 ? 0 : (duration - restTime);
            _totalWorkingTime = _updateTotalWorkingTime(_selectedDay);
          });
          String dbDate = DateFormat('yyyy-MM-dd').format(date);
          await UserDatabase.addUserDateItem(companyId: widget.companyId,userUid: _appTitle, date: dbDate, key: "duration", value: _durationTime[date].toString());

          dbDate = DateFormat('yyyy-MM-dd').format(DateTime(date.year, date.month));
          await UserDatabase.addUserDateItem(companyId: widget.companyId,userUid: _appTitle, date: dbDate, key: "total", value: _totalWorkingTime.toString());
        }
      }
    }
  }

  _updateTotalWorkingTime(DateTime date)
  {
    double total = 0;
    _durationTime.forEach((key, value) {
      if(key.year == date.year && key.month == date.month)
      {
        total += value;
      }
    });
    return total;
  }

  int daysBetween(DateTime from, DateTime to) {
    from = DateTime(from.year, from.month, from.day);
    to = DateTime(to.year, to.month, to.day);
    return (to.difference(from).inHours / 24).round();
  }

  TimeOfDay _convertTimeTo24Hours(TimeOfDay time)
  {
    final now = DateTime.now();
    DateTime temp = DateTime(now.year, now.month, now.day, time.hour, time.minute);
    temp = DateTime.parse(DateFormat('yyyy-MM-dd HH:mm:ss').format(temp));
    return TimeOfDay.fromDateTime(temp);
  }

  _getInitialTime(DateTime date){
    double min = TimeOfDay.now().minute / 30;
    int hour = TimeOfDay.now().hour;
    min = min.round()*30;
    if(min == 60){
      min = 0;
      hour += 1;
    }

    TimeOfDay _time = TimeOfDay(hour: hour, minute: min as int);


    return _time;
  }

  _selectStartTime() async {
    DateTime date = DateTime(_selectedDay.year, _selectedDay.month, _selectedDay.day);
    TimeOfDay _time = _getInitialTime(date);
    if(_startTime[date] != null){
      _time = _startTime[date]!;
    }

    final TimeOfDay? newTime = await showIntervalTimePicker(
      context: context,
      interval: 30,
      builder:  (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(alwaysUse24HourFormat: false),
          child: child!,
        );
      },
      initialTime: _time,
    );
    if (newTime != null) {
      setState(() {
        _time = _convertTimeTo24Hours(newTime);
        _startTime[date] = _time;
        _startTimePrint = _getStartTime();
      });
      String dbDate = DateFormat('yyyy-MM-dd').format(date);
      await UserDatabase.addUserDateItem(companyId: widget.companyId,userUid: _appTitle, date: dbDate, key: "start", value: _time.format(context));
      _getDurationTime(date);
    }
  }

  _selectEndTime() async {
    DateTime date = DateTime(_selectedDay.year, _selectedDay.month, _selectedDay.day);
    TimeOfDay _time = _getInitialTime(date);
    if(_endTime[date] != null){
      _time = _endTime[date]!;
    }

    final TimeOfDay? newTime = await showIntervalTimePicker(
      context: context,
      interval: 30,
      builder:  (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(alwaysUse24HourFormat: false),
          child: child!,
        );
      },
      initialTime: _time,
    );
    if (newTime != null) {
      setState(() {
        _time = _convertTimeTo24Hours(newTime);
        _endTime[date] = _time;
        _endTimePrint = _getEndTime();
      });
      String dbDate = DateFormat('yyyy-MM-dd').format(date);
      await UserDatabase.addUserDateItem(companyId: widget.companyId,userUid: _appTitle, date: dbDate, key: "end", value: _time.format(context));
      _getDurationTime(date);
    }
  }

  String _getStartTime(){
    String ret = "";
    DateTime date = DateTime(_selectedDay.year, _selectedDay.month, _selectedDay.day);
    if(_startTime[date] != null)
    {
      ret += "${_startTime[date]?.format(context)}";

    }
    return ret;
  }

  String _getEndTime(){
    String ret = "";
    DateTime date = DateTime(_selectedDay.year, _selectedDay.month, _selectedDay.day);
    if(_endTime[date] != null)
    {
      ret += "${_endTime[date]?.format(context)}";

    }
    return ret;
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
class CustomRangeTextInputFormatter extends TextInputFormatter {

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue,TextEditingValue newValue,) {
    if(newValue.text == '')
      return TextEditingValue();
    else if(double.parse(newValue.text) < 0)
      return TextEditingValue().copyWith(text: '0');

    double ret = double.parse(newValue.text);
    return double.parse(newValue.text) > 24 ? TextEditingValue().copyWith(text: '24') : newValue;
  }
}