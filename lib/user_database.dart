import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'branch_database.dart';

final CollectionReference _mainCollection = mainCollection;

class UserDatabase {
  static Future<void> addUserDateItem({
    required String companyId,
    required String userUid,
    required String date,
    required String key,
    required String value,
  }) async {
    DocumentReference documentReferencer =
    _mainCollection.doc(companyId).collection('users').doc(userUid).collection('dates').doc(date);

    Map<String, dynamic> data = <String, dynamic>{
      key: value,
    };

    await documentReferencer
        .set(data,SetOptions(merge: true))
        .whenComplete(() => print("date item added to the database"))
        .catchError((e) => print(e));

    DocumentReference adminDocUserListReferencer =
    _mainCollection.doc(companyId).collection('users').doc('Administrator').collection('userList').doc(userUid);

    List<String> userInfo = userUid.split('-');
    if(userInfo.length >= 2){
      Map<String, dynamic> userData = <String, dynamic>{
        'name': userInfo[0].trimRight(),
        'workPlace' : userInfo[1].trimLeft(),
      };

      await adminDocUserListReferencer
          .set(userData,SetOptions(merge: true))
          .whenComplete(() => print("added to database userList"))
          .catchError((e) => print(e));
    }
  }

  static Future<void> addUserDateExpenseItem({
    required String companyId,
    required String userUid,
    required String date,
    required int expenseId,
    required String key,
    required String value,
  }) async {
    DocumentReference documentReferencer =
    _mainCollection.doc(companyId).collection('users').doc(userUid).collection('dates').doc(date).collection('expense').doc('ex'+ expenseId.toString());

    Map<String, dynamic> data = <String, dynamic>{
      key: value,
    };

    await documentReferencer
        .set(data,SetOptions(merge: true))
        .whenComplete(() => print("date item added to the database"))
        .catchError((e) => print(e));
  }

  static Future<void> addUserItem({
    required String companyId,
    required String userUid,
    required String key,
    required String value,
  }) async {
    DocumentReference documentReferencer =
    _mainCollection.doc(companyId).collection('users').doc(userUid);

    Map<String, dynamic> data = <String, dynamic>{
      key: value,
    };

    await documentReferencer
        .set(data,SetOptions(merge: true))
        .whenComplete(() => print("date item added to the database"))
        .catchError((e) => print(e));
  }

  static Future<void> addAdminUserItem({
    required String companyId,
    required String userUid,
    required String key,
    required String value,
  }) async {
    DocumentReference documentReferencer =
    _mainCollection.doc(companyId).collection('users').doc('Administrator').collection('userList').doc(userUid);

    Map<String, dynamic> data = <String, dynamic>{
      key: value,
    };

    await documentReferencer
        .set(data,SetOptions(merge: true))
        .whenComplete(() => print("date item added to the database"))
        .catchError((e) => print(e));
  }

  static Stream<QuerySnapshot> readItems({required String companyId, required String userUid,}) {
    if(userUid == 'Administrator'){
      CollectionReference notesItemCollection = _mainCollection.doc(companyId).collection('users').doc(userUid).collection('userList');

      return notesItemCollection.snapshots();
    }
    else{
      CollectionReference notesItemCollection = _mainCollection.doc(companyId).collection('users').doc(userUid).collection('dates');
      return notesItemCollection.snapshots();
    }
  }

  static CollectionReference getUserCollection({required String companyId}) {
    CollectionReference notesItemCollection = _mainCollection.doc(companyId).collection('users');
    return notesItemCollection;
  }

  static CollectionReference getItemCollection({required String companyId, required String userUid,}) {
    if(userUid == 'Administrator'){
      CollectionReference notesItemCollection = _mainCollection.doc(companyId).collection('users').doc(userUid).collection('userList');

      return notesItemCollection;
    }
    else{
      CollectionReference notesItemCollection = _mainCollection.doc(companyId).collection('users').doc(userUid).collection('dates');
      return notesItemCollection;
    }
  }

  static CollectionReference getExpenseItemCollection({required String companyId, required String userUid, required String date}) {
    CollectionReference notesItemCollection = _mainCollection.doc(companyId).collection('users').doc(userUid).collection('dates').doc(date).collection('expense');
    return notesItemCollection;
  }



  static Future<void> deleteDoc({
    required String companyId,
    required String userUid,
    required String date,
  }) async {
    DocumentReference documentReferencer =
    _mainCollection.doc(companyId).collection('users').doc(userUid).collection('dates').doc(date);

    await documentReferencer
        .delete()
        .whenComplete(() => print('Note item deleted from the database'))
        .catchError((e) => print(e));
  }

  static Future<void> deleteExpenseDoc({
    required String companyId,
    required String userUid,
    required String date,
    required int expenseId
  }) async {
    DocumentReference documentReferencer =
    _mainCollection.doc(companyId).collection('users').doc(userUid).collection('dates').doc(date).collection('expense').doc('ex'+ expenseId.toString());

    await documentReferencer
        .delete()
        .whenComplete(() => print('Note item deleted from the database'))
        .catchError((e) => print(e));
  }

  static Future<void> deleteItem({
    required String companyId,
    required String userUid,
    required String date,
    required String key,
  }) async {
    _mainCollection.doc(companyId).collection('users').doc(userUid).update({key : FieldValue.delete()}).whenComplete((){
      print(key + ' Field Deleted');
    });
  }

  static Future<void> deleteUser({
    required String companyId,
    required String userUid,
  }) async {
    DocumentReference documentReferencer = _mainCollection.doc(companyId).collection('users').doc(userUid);
    DocumentReference documentReferencer2 = _mainCollection.doc(companyId).collection('users').doc('Administrator').collection('userList').doc(userUid);


/*
    await documentReferencer
        .delete()
        .whenComplete(() => print('User Calendar deleted from the database'))
        .catchError((e) => print(e));*/

    await documentReferencer2
        .delete()
        .whenComplete(() => print('User Info deleted from the database'))
        .catchError((e) => print(e));
  }

  static Future<String> updateAdminPasswordDb(String companyId, String initialPassword) async{
    String passWord = '';
    await UserDatabase.getItemCollection(companyId: companyId, userUid: 'Administrator').get().then((QuerySnapshot querySnapshot) {
      bool adminExist = false;
      querySnapshot.docs.forEach((doc) {
        if(doc.id == 'Administrator'){
          adminExist = true;
          try{
            passWord = doc['password'];
          }
          catch (e){
            print(e);
            UserDatabase.addAdminUserItem(companyId : companyId, userUid: 'Administrator', key: 'password', value: initialPassword);
          }
        }
      });
    });
    return passWord;
  }

  static Future<String> getAdminEmailDb(String companyId) async{
    String email = '';
    await UserDatabase.getItemCollection(companyId: companyId, userUid: 'Administrator').get().then((QuerySnapshot querySnapshot) {
      bool adminExist = false;
      querySnapshot.docs.forEach((doc) {
        if(doc.id == 'Administrator'){
          adminExist = true;
          try{
            email = doc['email'];
          }
          catch (e){
            print(e);
          }
        }
      });
    });
    return email;
  }

  static Future<int> getMinuteIntervalDb(String companyId) async{
    int minuteInterval = 30;
    await UserDatabase.getItemCollection(companyId: companyId, userUid: 'Administrator').get().then((QuerySnapshot querySnapshot) {
      bool adminExist = false;
      querySnapshot.docs.forEach((doc) {
        if(doc.id == 'Administrator'){
          adminExist = true;
          try{
            var minInter = int.parse(doc['minute_interval']);
            if(minInter != null){
              minuteInterval = minInter;
            }
          }
          catch (e){
            print(e);
          }
        }
      });
    });
    return minuteInterval;
  }

}
