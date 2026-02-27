import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:ccce_application/services/error_logger.dart';

class NotificationService {
  static String? _currentUid;
  static bool _lifecycleObserverAttached = false;

  static Future<void> firebaseMessagingBackgroundHandler(
      RemoteMessage message) async {
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp();
      }
    } on FirebaseException catch (e) {
      if (e.code != 'duplicate-app') {
        rethrow;
      }
    }
    ErrorLogger.logInfo('NotificationService', 'Background message received: ${message.messageId}');
    ErrorLogger.logInfo('NotificationService', 'Title: ${message.notification?.title}');
    ErrorLogger.logInfo('NotificationService', 'Body: ${message.notification?.body}');
    ErrorLogger.logInfo('NotificationService', 'Data: ${message.data}');
    
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
        if (kDebugMode) ErrorLogger.logInfo('NotificationService', 'Local notification tapped: ${response.payload}');
      });

      await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(_androidChannel);
    } catch (e) {
      ErrorLogger.logError('NotificationService', 'Error initializing local notifications', error: e);
    }
  }

  static Future<void> initForUid(String uid) async {
    try {
      _currentUid = uid;
      _ensureLifecycleObserver();
      await _initLocalNotifications();

      final NotificationSettings settings = await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        ErrorLogger.logInfo('NotificationService', 'User granted permission');

        await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
          alert: true,
          badge: true,
          sound: true,
        );
                
        final String? token = await FirebaseMessaging.instance.getToken();
        if (token != null) {
          ErrorLogger.logInfo('NotificationService', 'FCM Token: $token');
          ErrorLogger.logInfo('NotificationService', 'Copy this token to test notifications in Firebase Console');
          await saveTokenForUser(uid, token);
        }

        FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
          ErrorLogger.logInfo('NotificationService', 'FCM Token refreshed: $newToken');
          await saveTokenForUser(uid, newToken);
        });

        FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
          ErrorLogger.logInfo('NotificationService', 'Foreground message received: ${message.messageId}');
          ErrorLogger.logInfo('NotificationService', 'Title: ${message.notification?.title}');
          ErrorLogger.logInfo('NotificationService', 'Body: ${message.notification?.body}');
          ErrorLogger.logInfo('NotificationService', 'Data: ${message.data}');

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
          ErrorLogger.logInfo('NotificationService', 'App opened from notification:');
          ErrorLogger.logInfo('NotificationService', 'Title: ${message.notification?.title}');
          ErrorLogger.logInfo('NotificationService', 'Body: ${message.notification?.body}');
          ErrorLogger.logInfo('NotificationService', 'Data: ${message.data}');
        });

      } else {
        ErrorLogger.logWarning('NotificationService', 'User declined or has not accepted permission');
      }
    } catch (e) {
      ErrorLogger.logError('NotificationService', 'Error initializing NotificationService', error: e);
    }
  }

  static Future<void> refreshTokenForUser(String uid) async {
    try {
      final String? token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        await saveTokenForUser(uid, token);
      }
    } catch (e) {
      ErrorLogger.logError('NotificationService', 'Error refreshing token', error: e);
    }
  }

  static void _ensureLifecycleObserver() {
    if (_lifecycleObserverAttached) return;
    WidgetsBinding.instance.addObserver(_NotificationLifecycleObserver());
    _lifecycleObserverAttached = true;
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
      ErrorLogger.logError('NotificationService', 'Error saving token', error: e);
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
      ErrorLogger.logError('NotificationService', 'Error removing token', error: e);
    }
  }
}

class _NotificationLifecycleObserver extends WidgetsBindingObserver {
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      final uid = NotificationService._currentUid;
      if (uid != null) {
        NotificationService.refreshTokenForUser(uid);
      }
    }
  }
}
