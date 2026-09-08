import 'package:ccce_application/services/error_logger.dart';
import 'package:flutter/material.dart';
import 'package:ccce_application/common/collections/user_data.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ccce_application/services/notification_service.dart';

class UserProvider with ChangeNotifier {
  UserData? _user;

  UserData? get user => _user;
  bool isClubAdmin(String clubId) => _user?.isClubAdmin(clubId) ?? false;
  List<String> get clubsAdminOf => _user?.clubsAdminOf ?? [];

  Future<void> loadUserProfile(String uid) async {

    ErrorLogger.logError(
      'UserProvider',
      'Loading user profile for $uid',
      sendToCrashlytics: true,
    );

    final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();

    ErrorLogger.logError(
      'UserProvider',
      'users/$uid exists: ${doc.exists}',
      sendToCrashlytics: true,
    );


    if (!doc.exists) {
      ErrorLogger.logError(
        'UserProvider',
        'USER PROFILE DOES NOT EXIST for $uid',
        sendToCrashlytics: true,
      );
      return;
    }

    if (doc.exists) {
      final previousRole = _user?.role;
      _user = UserData.fromMap(uid, doc.data()!);
      if (previousRole != null && previousRole != _user?.role) {
        await NotificationService.refreshTokenForUser(uid);
      }
      notifyListeners();
    }
  }
}
