import 'package:ccce_application/common/collections/calevent.dart';
import 'package:ccce_application/common/features/sign_in.dart';
import 'package:ccce_application/common/theme/theme.dart';
import 'package:ccce_application/common/widgets/gold_app_bar.dart';
import 'package:ccce_application/rendered_page.dart';
import 'package:ccce_application/common/features/onboarding/onboarding_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:provider/provider.dart';
import 'package:ccce_application/common/providers/app_state.dart';
import 'package:ccce_application/common/providers/event_provider.dart';
import 'package:ccce_application/common/providers/user_provider.dart';
import 'package:ccce_application/common/providers/club_provider.dart';

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

  // Request notification permissions when the app starts
  _requestNotificationPermissions();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AppState>(create: (_) => AppState()),
        ChangeNotifierProvider<EventProvider>(create: (_) => EventProvider()),
        ChangeNotifierProvider<UserProvider>(create: (_) => UserProvider()),
        ChangeNotifierProvider<ClubProvider>(create: (_) => ClubProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  Future<bool> _isTOSAccepted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('TOS') ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _isTOSAccepted(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const MaterialApp(
            home: Scaffold(
                body: Center(
                    child: CircularProgressIndicator(
              color: AppColors.calPolyGreen,
              backgroundColor: AppColors.calPolyGreen,
            ))),
          );
        }
        final tosAccepted = snapshot.data!;
        if (!tosAccepted) {
          return const MaterialApp(
            home: Scaffold(
                appBar: GoldAppBar(),
                body: OnboardingScreen()), // Show TOS/Onboarding screen
          );
        }
        return StreamBuilder<User?>(
          stream: FirebaseAuth.instance.authStateChanges(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const CircularProgressIndicator();
            }
            if (!snapshot.hasData) {
              // User is not signed in, show sign-in screen
              return const MaterialApp(
                home: SignIn(), // <-- Replace with your sign-in screen widget
              );
            }
            // User is signed in, load user profile data and clubs
            WidgetsBinding.instance.addPostFrameCallback((_) {
              Provider.of<UserProvider>(context, listen: false)
                  .loadUserProfile(snapshot.data!.uid);
              Provider.of<ClubProvider>(context, listen: false).loadClubs();
            });

            // User is signed in, check if eventProvider is loaded
            return Consumer<EventProvider>(
              builder: (context, eventProvider, child) {
                if (!eventProvider.isLoaded) {
                  return const MaterialApp(
                    home: Scaffold(
                      backgroundColor: AppColors.calPolyGreen,
                      body: Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      ),
                    ),
                  );
                }
                // User is signed in and events are loaded, show main app
                return const MaterialApp(
                  home: Scaffold(appBar: GoldAppBar(), body: RenderedPage()),
                );
              },
            );
          },
        );
      },
    );
  }
}
