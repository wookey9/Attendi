import 'package:cloud_firestore/cloud_firestore.dart';

final FirebaseFirestore firestore = FirebaseFirestore.instance;
final CollectionReference mainCollection = firestore.collection('company');

class BranchDatabase {
  static Future<void> addItem({
    required String companyId,
    required String branch,
    required String key,
    required String value,
  }) async {
    DocumentReference documentReferencer =
    mainCollection.doc(companyId).collection('branches').doc(branch);

    Map<String, dynamic> data = <String, dynamic>{
      key: value,
    };

    await documentReferencer
        .set(data,SetOptions(merge: true))
        .whenComplete(() => print("date item added to the database"))
        .catchError((e) => print(e));
  }

  static Future<void> addCheckItem({
    required String companyId,
    required String branch,
    required int checkId,
    required String key,
    required String value,
  }) async {
    DocumentReference documentReferencer =
    mainCollection.doc(companyId).collection('branches').doc(branch).collection('checklist').doc('check'+checkId.toString());

    Map<String, dynamic> data = <String, dynamic>{
      key: value,
    };

    await documentReferencer
        .set(data,SetOptions(merge: true))
        .whenComplete(() => print("date item added to the database"))
        .catchError((e) => print(e));
  }

  static Future<void> addCompanyListItem({
    required String companyId,
    required String key,
    required String value,
  }) async {
    DocumentReference documentReferencer =
    mainCollection.doc('list').collection('companylist').doc(companyId);

    Map<String, dynamic> data = <String, dynamic>{
      key: value,
    };

    await documentReferencer
        .set(data,SetOptions(merge: true))
        .whenComplete(() => print("date item added to the database"))
        .catchError((e) => print(e));
  }

  static Stream<QuerySnapshot> readItems({required String companyId,}) {
    CollectionReference notesItemCollection = mainCollection.doc(companyId).collection('branches');
    return notesItemCollection.snapshots();
  }

  static CollectionReference getBranchCollection({required String companyId,}) {
    CollectionReference notesItemCollection = mainCollection.doc(companyId).collection('branches');
    return notesItemCollection;
  }

  static CollectionReference getBranchCheckListCollection({required String companyId, required String branch}) {
    CollectionReference notesItemCollection = mainCollection.doc(companyId).collection('branches').doc(branch).collection('checklist');
    return notesItemCollection;
  }

  static CollectionReference getCompanyCollection() {
    CollectionReference notesItemCollection = mainCollection;
    return notesItemCollection;
  }

  static CollectionReference getCompanyListCollection() {
    CollectionReference notesItemCollection = mainCollection.doc('list').collection('companylist');
    return notesItemCollection;
  }

  static Future<void> deleteCompanyListItem({
    required String companyId,
  }) async {
    DocumentReference documentReferencer =
    mainCollection.doc('list').collection('companylist').doc(companyId);

    await documentReferencer
        .delete()
        .whenComplete(() => print('Note item deleted from the database'))
        .catchError((e) => print(e));
  }

  static Future<void> deleteItem({
    required String companyId,
    required String branch,
  }) async {
    DocumentReference documentReferencer =
    mainCollection.doc(companyId).collection('branches').doc(branch);

    await documentReferencer
        .delete()
        .whenComplete(() => print('Note item deleted from the database'))
        .catchError((e) => print(e));
  }

  static Future<void> deleteCheckListItem({
    required String companyId,
    required String branch,
    required int checkId,
  }) async {
    DocumentReference documentReferencer =
    mainCollection.doc(companyId).collection('branches').doc(branch).collection('checklist').doc('check'+checkId.toString());

    await documentReferencer
        .delete()
        .whenComplete(() => print('Note item deleted from the database'))
        .catchError((e) => print(e));
  }
}
