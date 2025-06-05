import 'package:ccce_application/common/widgets/gold_app_bar.dart';
import 'package:ccce_application/rendered_page.dart';
import 'package:ccce_application/common/features/onboarding/onboarding_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

// import 'package:isar/isar.dart';
// import 'package:ccce_application/src/screens/profile_screen.dart';
// import 'package:ccce_application/src/screens/home_screen.dart';
Future<void> _requestNotificationPermissions() async {
  FirebaseMessaging messaging = FirebaseMessaging.instance;

  NotificationSettings settings = await messaging.requestPermission(
    alert: true,
    announcement: false,
    badge: true,
    carPlay: false,
    criticalAlert: false,
    provisional: false,
    sound: true,
  );

  if (settings.authorizationStatus == AuthorizationStatus.authorized) {
    print('User granted permission');
  } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
    print('User granted provisional permission');
  } else {
    print('User declined or has not granted permission');
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  final prefs = await SharedPreferences.getInstance();

  // Request notification permissions when the app starts
  _requestNotificationPermissions();

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  MyApp({super.key});
  late var _tosCheck;

  Future<void> _loadTOS() async {
    final prefs = await SharedPreferences.getInstance();
    _tosCheck = prefs.getBool('TOS') ?? false;
  }

  @override
  Widget build(BuildContext context) {
    _loadTOS();
    return StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const MaterialApp(
              home: Scaffold(appBar: GoldAppBar(), body: OnboardingScreen()),
              //home: AuthGate(),
            );
          }

          return const MaterialApp(
              home: Scaffold(appBar: GoldAppBar(), body: RenderedPage()));
        });
  }
}


// class CMApp extends StatelessWidget {
//   const CMApp({super.key});
//   final String title = 'CM';
//   static const calPolyGreen = Color(0xFF003831);
//   static const appBackgroundColor = Color(0xFFE4E3D3);

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       drawer: Drawer(
//           child: ListView(children: <Widget>[
//         ListTile(
//           title: const Text('Home'),
//           onTap: () {
//             Navigator.pushReplacement(context,
//                 MaterialPageRoute(builder: (context) => const HomeScreen()));
//           },
//         ),
//         ListTile(
//           title: const Text('Events'),
//           onTap: () {
//             Navigator.pushReplacement(context,
//                 MaterialPageRoute(builder: (context) => const HomeScreen()));
//           },
//         ),
//         ListTile(
//           title: const Text('Club Info'),
//           onTap: () {
//             Navigator.pushReplacement(context,
//                 MaterialPageRoute(builder: (context) => const HomeScreen()));
//           },
//         ),
//         ListTile(
//           title: const Text('Academics'),
//           onTap: () {
//             Navigator.pushReplacement(context,
//                 MaterialPageRoute(builder: (context) => const HomeScreen()));
//           },
//         ),
//         ListTile(
//           title: const Text('Resources'),
//           onTap: () {
//             Navigator.pushReplacement(context,
//                 MaterialPageRoute(builder: (context) => const HomeScreen()));
//           },
//         )
//       ])),
//       appBar: AppBar(
//         leading: Builder(
//           builder: (context) => IconButton(
//               onPressed: () => Scaffold.of(context).openDrawer(),
//               icon: const Icon(Icons.dehaze)),
//         ),
//         backgroundColor: calPolyGreen,
//         centerTitle: true,
//         iconTheme: const IconThemeData(color: Colors.white),
//         title: Text(
//           title,
//           style: const TextStyle(
//             color: Colors.white,
//           ),
//         ),
//         actions: <Widget>[
//           IconButton(
//             icon: const Icon(Icons.account_circle_rounded),
//             tooltip: 'Open Profile',
//             onPressed: () {
//               Navigator.pushReplacement(
//                   context,
//                   MaterialPageRoute(
//                       builder: (context) => const ProfileScreen()));
//             },
//           ),
//         ],
//       ),
//     );
//   }
// }