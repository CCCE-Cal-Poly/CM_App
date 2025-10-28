import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class NotificationService {
  static Future<void> firebaseMessagingBackgroundHandler(
      RemoteMessage message) async {
    await Firebase.initializeApp();
    print('Background message received: ${message.messageId}');
  }

  static Future<void> initForUid(String uid) async {
    try {
      final NotificationSettings settings = await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        print('User granted permission');
        
        final String? token = await FirebaseMessaging.instance.getToken();
        if (token != null) {
          await saveTokenForUser(uid, token);
        }

        FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
          if (newToken != null) await saveTokenForUser(uid, newToken);
        });

        FirebaseMessaging.onMessage.listen((RemoteMessage message) {
          print('Foreground message received:');
          print('Title: ${message.notification?.title}');
          print('Body: ${message.notification?.body}');
          print('Data: ${message.data}');
        });

        FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
          print('App opened from notification:');
          print('Title: ${message.notification?.title}');
          print('Body: ${message.notification?.body}');
          print('Data: ${message.data}');
        });

      } else {
        print('User declined or has not accepted permission');
      }
    } catch (e) {
      print('Error initializing NotificationService: $e');
    }
  }

  static Future<void> saveTokenForUser(String uid, String token) async {
    try {
      final docRef = FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('fcmTokens')
          .doc(token);
      await docRef.set({'token': token, 'createdAt': FieldValue.serverTimestamp()});
    } catch (e) {
      print('Error saving token: $e');
    }
  }

  static Future<void> removeTokenForUser(String uid, String token) async {
    try {
      final docRef = FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('fcmTokens')
          .doc(token);
      await docRef.delete();
    } catch (e) {
      print('Error removing token: $e');
    }
  }
}
