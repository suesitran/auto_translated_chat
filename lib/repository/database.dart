import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:public_chat/_shared/data/chat_data.dart';

final class Database {
  static Database? _instance;

  Database._();

  static Database get instance {
    _instance ??= Database._();
    return _instance!;
  }

  final String _publicRoom = 'public';
  final String _userList = 'users';

  void writePublicMessage(Message message) {
    FirebaseFirestore.instance.collection(_publicRoom).add(message.toMap());
  }

  Future<void> updatePublicMessage(
      String messageId, Map<String, dynamic> data) {
    return FirebaseFirestore.instance
        .collection(_publicRoom)
        .doc(messageId)
        .set(data, SetOptions(merge: true));
  }

  Query<T> getPublicChatContents<T>({
    required FromFirestore<T> fromFirestore,
    required ToFirestore<T> toFirestore,
  }) {
    return FirebaseFirestore.instance
        .collection(_publicRoom)
        .orderBy('time', descending: true)
        .withConverter(fromFirestore: fromFirestore, toFirestore: toFirestore);
  }

  void saveUser(User user) {
    final Map<String, dynamic> userMap = {
      "displayName": user.displayName ?? "",
      "uid": user.uid,
      "photoUrl": user.photoURL,
    };
    FirebaseFirestore.instance
        .collection(_userList)
        .doc(user.uid)
        .set(userMap, SetOptions(merge: true));
  }

  Future<void> updateUser(String uid, Map<String, dynamic> data) {
    return FirebaseFirestore.instance
        .collection(_userList)
        .doc(uid)
        .set(data, SetOptions(merge: true));
  }

  Future<DocumentSnapshot<UserDetail>> getUser(String uid) {
    return FirebaseFirestore.instance
        .collection(_userList)
        .doc(uid)
        .withConverter(
            fromFirestore: _userDetailFromFirestore,
            toFirestore: _userDetailToFirestore)
        .get(const GetOptions(source: Source.serverAndCache));
  }

  Stream<QuerySnapshot<UserDetail>> getUserStream() {
    return FirebaseFirestore.instance
        .collection(_userList)
        .withConverter(
            fromFirestore: _userDetailFromFirestore,
            toFirestore: _userDetailToFirestore)
        .snapshots();
  }

  /// ###############################################################
  /// fromFirestore and toFirestore
  UserDetail _userDetailFromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
    SnapshotOptions? options,
  ) =>
      UserDetail.fromMap(snapshot.id, snapshot.data() ?? {});

  Map<String, Object?> _userDetailToFirestore(
    UserDetail value,
    SetOptions? options,
  ) =>
      value.toMap();
}
