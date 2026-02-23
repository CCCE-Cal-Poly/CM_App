import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'firebase_keys.dart';

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: FirebaseKeys.webApiKey,
    appId: '1:913522987647:web:77ec67ff2a1e736999a54a',
    messagingSenderId: '913522987647',
    projectId: 'cm-app-90d65',
    authDomain: 'cm-app-90d65.firebaseapp.com',
    storageBucket: 'cm-app-90d65.appspot.com',
    measurementId: 'G-NNYFG8919W',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: FirebaseKeys.androidApiKey,
    appId: '1:913522987647:android:4edbb77540bec80499a54a',
    messagingSenderId: '913522987647',
    projectId: 'cm-app-90d65',
    storageBucket: 'cm-app-90d65.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: FirebaseKeys.iosApiKey,
    appId: '1:913522987647:ios:8edc0b49e1ac6ce899a54a',
    messagingSenderId: '913522987647',
    projectId: 'cm-app-90d65',
    storageBucket: 'cm-app-90d65.appspot.com',
    iosBundleId: 'com.ccce.ccceApplication',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: FirebaseKeys.macosApiKey,
    appId: '1:913522987647:ios:e974e63fa42274ef99a54a',
    messagingSenderId: '913522987647',
    projectId: 'cm-app-90d65',
    storageBucket: 'cm-app-90d65.appspot.com',
    iosBundleId: 'com.ccce.ccceApplication.RunnerTests',
  );
}
