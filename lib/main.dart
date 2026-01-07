import 'package:ccce_application/common/features/sign_in.dart';
import 'package:ccce_application/common/providers/company_provider.dart';
import 'package:ccce_application/common/theme/theme.dart';
import 'package:ccce_application/common/widgets/gold_app_bar.dart';
import 'package:ccce_application/rendered_page.dart';
import 'package:ccce_application/common/features/onboarding/onboarding_screen.dart';
import 'package:ccce_application/services/error_logger.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:ccce_application/services/notification_service.dart';
import 'package:provider/provider.dart';
import 'package:ccce_application/common/providers/app_state.dart';
import 'package:ccce_application/common/providers/event_provider.dart';
import 'package:ccce_application/common/providers/user_provider.dart';
import 'package:ccce_application/common/providers/club_provider.dart';

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
    ErrorLogger.logInfo('Notifications', 'User granted permission');
  } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
    ErrorLogger.logInfo('Notifications', 'User granted provisional permission');
  } else {
    ErrorLogger.logWarning('Notifications', 'User declined or has not granted permission');
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  FirebaseMessaging.onBackgroundMessage(
      NotificationService.firebaseMessagingBackgroundHandler);

  await _requestNotificationPermissions();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AppState>(create: (_) => AppState()),
        ChangeNotifierProvider<EventProvider>(create: (_) => EventProvider()),
        ChangeNotifierProvider<CompanyProvider>(
            create: (_) => CompanyProvider()),
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
            debugShowCheckedModeBanner: false,
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
            debugShowCheckedModeBanner: false,
            home: Scaffold(
              appBar: GoldAppBar(),
              body: OnboardingScreen()), 
          );
        }
        return StreamBuilder<User?>(
          stream: FirebaseAuth.instance.authStateChanges(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const CircularProgressIndicator();
            }
            if (!snapshot.hasData) {
              return const MaterialApp(
                debugShowCheckedModeBanner: false,
                home: SignIn(),
              );
            }
            WidgetsBinding.instance.addPostFrameCallback((_) {
              Provider.of<UserProvider>(context, listen: false)
                  .loadUserProfile(snapshot.data!.uid);
              Provider.of<ClubProvider>(context, listen: false).loadClubs();
              // Initialize notification service for this signed-in user
              NotificationService.initForUid(snapshot.data!.uid);
            });

            return Consumer2<EventProvider, CompanyProvider>(
              builder: (context, eventProvider, companyProvider, child) {
                if (!eventProvider.isLoaded) {
                  return const MaterialApp(
                    debugShowCheckedModeBanner: false,
                    home: Scaffold(
                      backgroundColor: AppColors.calPolyGreen,
                      body: Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      ),
                    ),
                  );
                }
                
                if (companyProvider.isLoaded && eventProvider.needsLogoLinking) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    eventProvider.linkCompanyLogos(companyProvider.allCompanies);
                  });
                }
                
                return const MaterialApp(
                  debugShowCheckedModeBanner: false,
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
