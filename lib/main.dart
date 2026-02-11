import 'package:ccce_application/common/features/sign_in.dart';
import 'package:ccce_application/common/features/verification_screen.dart';
import 'package:ccce_application/common/providers/company_provider.dart';
import 'package:ccce_application/common/theme/theme.dart';
import 'package:ccce_application/common/widgets/gold_app_bar.dart';
import 'package:ccce_application/rendered_page.dart';
import 'package:ccce_application/common/features/onboarding/onboarding_screen.dart';
import 'package:ccce_application/services/error_logger.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:ui';
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
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_analytics/observer.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
    ErrorLogger.logWarning(
        'Notifications', 'User declined or has not granted permission');
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
  } on FirebaseException catch (e) {
    if (e.code != 'duplicate-app') {
      rethrow;
    }
  }

  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };

  await FirebaseAppCheck.instance.activate(
    providerAndroid: kDebugMode
        ? const AndroidDebugProvider()
        : const AndroidPlayIntegrityProvider(),
    providerApple: kDebugMode
        ? const AppleDebugProvider()
        : const AppleAppAttestProvider(),
  );

  FirebaseFirestore.instance.settings =
      const Settings(persistenceEnabled: true);
  await FirebaseAnalytics.instance.logAppOpen();

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

  static final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;
  static final FirebaseAnalyticsObserver _observer =
      FirebaseAnalyticsObserver(analytics: _analytics);

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
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            navigatorObservers: [_observer],
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
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            navigatorObservers: [_observer],
            home: Scaffold(appBar: GoldAppBar(), body: OnboardingScreen()),
          );
        }
        return StreamBuilder<User?>(
          stream: FirebaseAuth.instance.authStateChanges(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const CircularProgressIndicator();
            }
            if (!snapshot.hasData) {
              return MaterialApp(
                debugShowCheckedModeBanner: false,
                navigatorObservers: [_observer],
                home: SignIn(),
              );
            }

            final user = snapshot.data!;

            if (!user.emailVerified) {
              return MaterialApp(
                debugShowCheckedModeBanner: false,
                navigatorObservers: [_observer],
                home: const EmailVerificationScreen(),
              );
            }

            WidgetsBinding.instance.addPostFrameCallback((_) {
              Provider.of<UserProvider>(context, listen: false)
                  .loadUserProfile(user.uid);
              Provider.of<ClubProvider>(context, listen: false).loadClubs();
              // Initialize notification service for this signed-in user
              NotificationService.initForUid(user.uid);
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

                if (companyProvider.isLoaded &&
                    eventProvider.needsLogoLinking) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    eventProvider
                        .linkCompanyLogos(companyProvider.allCompanies);
                  });
                }

                return MaterialApp(
                  debugShowCheckedModeBanner: false,
                  navigatorObservers: [_observer],
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
