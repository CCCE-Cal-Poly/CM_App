import 'package:flutter/material.dart';
import 'package:ccce_application/common/collections/user_data.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserProvider with ChangeNotifier {
  UserData? _user;

  UserData? get user => _user;
  bool isClubAdmin(String clubId) => _user?.isClubAdmin(clubId) ?? false;
  List<String> get clubsAdminOf => _user?.clubsAdminOf ?? [];

  Future<void> loadUserProfile(String uid) async {
    final doc =
      await FirebaseFirestore.instance.collection('users').doc(uid).get();
    if (doc.exists) {
      _user = UserData.fromMap(uid, doc.data()!);
      notifyListeners();
    }
  }
}
