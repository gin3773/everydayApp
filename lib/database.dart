import 'package:firebase_auth/firebase_auth.dart';

import 'wordclass.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DatabaseService {
  FirebaseUser user;

  DatabaseService(this.user);

  final CollectionReference userWordsCollection =
      Firestore.instance.collection('users');

  final CollectionReference wordsCollection =
      Firestore.instance.collection('all_words');

  Stream<List<NewWord>> get userWordsList {
    return userWordsCollection
        .document(user.uid)
        .collection('words')
        .snapshots()
        .map(userWordsListFromSnapshot);
  }

  List<NewWord> userWordsListFromSnapshot(QuerySnapshot snapshot) {
    return snapshot.documents.map((doc) {
      return NewWord(
          doc.data['name'] ?? 'waiting',
          doc.data['definition'] ?? 'waiting',
          doc.data['example'] ?? 'waiting');
    }).toList();
  }

  Future<String> getSavedName() async {
    String savedName;
    await userWordsCollection
        .document(user.uid)
        .get()
        .then((DocumentSnapshot snapshot) {
      savedName = snapshot.data['name'];
    });
    return savedName;
  }

  Future<String> getSavedCuriosity() async {
    String savedCuriosity;
    await userWordsCollection
        .document(user.uid)
        .get()
        .then((DocumentSnapshot snapshot) {
      savedCuriosity = snapshot.data['curiosity'];
    });
    return savedCuriosity;
  }

  Future<String> getSavedDef() async {
    String savedDef;
    await userWordsCollection
        .document(user.uid)
        .get()
        .then((DocumentSnapshot snapshot) {
      savedDef = snapshot.data['definition'];
    });
    return savedDef;
  }

  Future<String> getSavedExample() async {
    String savedExample;
    await userWordsCollection
        .document(user.uid)
        .get()
        .then((DocumentSnapshot snapshot) {
      savedExample = snapshot.data['example'];
    });
    return savedExample;
  }

  Future saveWord(NewWord word) async {
    final snapshot = await userWordsCollection
        .document(user.uid)
        .collection('words')
        .document('${word.name}')
        .get();
    if (snapshot.exists) {
      userWordsCollection
          .document(user.uid)
          .collection('words')
          .document('${word.name}')
          .updateData({
        'name': word.name,
        'definition': word.definition,
        'example': word.example
      });
    } else {
      userWordsCollection
          .document(user.uid)
          .collection('words')
          .document('${word.name}')
          .setData({
        'name': word.name,
        'definition': word.definition,
        'example': word.example
      });
    }
  }
}
