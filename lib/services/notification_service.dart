import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';

class NotificationService {
  static Future<void> firebaseMessagingBackgroundHandler(
      RemoteMessage message) async {
    await Firebase.initializeApp();
    print('Background message received: ${message.messageId}');
    print('Title: ${message.notification?.title}');
    print('Body: ${message.notification?.body}');
    print('Data: ${message.data}');
    
    final notif = message.notification;
    if (notif != null) {
      await flutterLocalNotificationsPlugin.show(
        notif.hashCode,
        notif.title,
        notif.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            _androidChannel.id,
            _androidChannel.name,
            channelDescription: _androidChannel.description,
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
            styleInformation: BigTextStyleInformation(
              notif.body ?? '',
              contentTitle: notif.title,
            ),
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: message.data.isNotEmpty ? message.data.toString() : null,
      );
    }
  }

  static final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _androidChannel = AndroidNotificationChannel(
    'ccce_notifications',
    'CCCE Notifications',
    description: 'Channel for CCCE app notifications',
    importance: Importance.high,
  );

  static Future<void> _initLocalNotifications() async {
    try {
      const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosInit = DarwinInitializationSettings();
      final initSettings = InitializationSettings(android: androidInit, iOS: iosInit);

      await flutterLocalNotificationsPlugin.initialize(initSettings,
          onDidReceiveNotificationResponse: (NotificationResponse response) {
        if (kDebugMode) print('Local notification tapped: ${response.payload}');
      });

      await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(_androidChannel);
    } catch (e) {
      print('Error initializing local notifications: $e');
    }
  }

  static Future<void> initForUid(String uid) async {
    try {
      await _initLocalNotifications();

      final NotificationSettings settings = await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        print('User granted permission');
        
        final String? token = await FirebaseMessaging.instance.getToken();
        if (token != null) {
          print('FCM Token: $token');
          print('Copy this token to test notifications in Firebase Console');
          await saveTokenForUser(uid, token);
        }

        FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
          print('FCM Token refreshed: $newToken');
          await saveTokenForUser(uid, newToken);
        });

        FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
          print('Foreground message received: ${message.messageId}');
          print('Title: ${message.notification?.title}');
          print('Body: ${message.notification?.body}');
          print('Data: ${message.data}');

          final notif = message.notification;
          if (notif != null) {
            await flutterLocalNotificationsPlugin.show(
              notif.hashCode,
              notif.title,
              notif.body,
              NotificationDetails(
                android: AndroidNotificationDetails(
                  _androidChannel.id,
                  _androidChannel.name,
                  channelDescription: _androidChannel.description,
                  importance: Importance.high,
                  priority: Priority.high,
                  icon: '@mipmap/ic_launcher',
                  styleInformation: BigTextStyleInformation(
                    notif.body ?? '',
                    contentTitle: notif.title,
                  ),
                ),
                iOS: DarwinNotificationDetails(
                  presentAlert: true,
                  presentBadge: true,
                  presentSound: true,
                ),
              ),
              payload: message.data.isNotEmpty ? message.data.toString() : null,
            );
          }
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
