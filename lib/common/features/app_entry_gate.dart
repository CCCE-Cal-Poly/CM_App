// NEW app_entry_gate.dart:
 
import 'dart:async';

import 'package:ccce_application/common/features/onboarding/onboarding_screen.dart';
import 'package:ccce_application/common/features/sign_in.dart';
import 'package:ccce_application/common/features/verification_screen.dart';
import 'package:ccce_application/common/providers/club_provider.dart';
import 'package:ccce_application/common/providers/company_provider.dart';
import 'package:ccce_application/common/providers/event_provider.dart';
import 'package:ccce_application/common/providers/user_provider.dart';
import 'package:ccce_application/common/theme/theme.dart';
import 'package:ccce_application/common/widgets/gold_app_bar.dart';
import 'package:ccce_application/rendered_page.dart';
import 'package:ccce_application/services/error_logger.dart';
import 'package:ccce_application/services/notification_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
 
class AppEntryGate extends StatefulWidget {
  const AppEntryGate({super.key});
  

  @override
  State<AppEntryGate> createState() => _AppEntryGateState();
 
  
}

class _AppEntryGateState extends State<AppEntryGate> with WidgetsBindingObserver {
    StreamSubscription<DocumentSnapshot>? _deletionListener;
  String? _initializedUserUid;
  String? _deletionListenerUserUid;
  bool _hasSeenExistingUserDoc = false;

    Future<bool> _isTOSAccepted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('TOS') ?? false;
  }

  
  @override
  void initState() {
    super.initState();
    ErrorLogger.logInfo('Auth', 'initState called in AppEntryGate');
    validateUser();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    _deletionListener?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      validateUser();
    }
  }

  

    Future<void> validateUser() async {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      
      try {
        await user.reload();
      } catch (error) {
        print("Error reloading user: $error");
        ErrorLogger.logError('Auth', 'Error reloading user: $error');
        await FirebaseAuth.instance.signOut();
      }
    }

    void _setupDeletionListener() {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        return;
      }

      if (_deletionListenerUserUid == user.uid && _deletionListener != null) {
        return;
      }

      _deletionListener?.cancel();
      _deletionListenerUserUid = user.uid;
      _hasSeenExistingUserDoc = false;

      _deletionListener = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .snapshots()
          .listen((snapshot) {
        if (snapshot.exists) {
          _hasSeenExistingUserDoc = true;
          return;
        }

        if (_hasSeenExistingUserDoc) {
          ErrorLogger.logInfo('Auth', 'Account deleted remotely');
          FirebaseAuth.instance.signOut();
          return;
        }

        ErrorLogger.logWarning(
            'Auth', 'User document missing during initial bootstrap');
      }, onError: (error) {
        ErrorLogger.logError('Auth', 'Deletion listener error: $error');
      });
  }

  


  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _isTOSAccepted(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(
                color: AppColors.calPolyGreen,
                backgroundColor: AppColors.calPolyGreen,
              ),
            ),
          );
        }
 
        final tosAccepted = snapshot.data!;
        if (!tosAccepted) {
          return const Scaffold(appBar: GoldAppBar(), body: OnboardingScreen());
        }
 
        return StreamBuilder<User?>(
          stream: FirebaseAuth.instance.userChanges(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(
                  child: CircularProgressIndicator(
                    color: AppColors.calPolyGreen,
                    backgroundColor: AppColors.calPolyGreen,
                  ),
                ),
              );
            }
 
            if (!snapshot.hasData) {
              return const SignIn();
            }
 
            final user = snapshot.data!;

            final requiresEmailVerification =
                user.providerData.any((p) => p.providerId == 'password');
 
            if (requiresEmailVerification && !user.emailVerified) {
              ErrorLogger.logInfo('Auth', 'User email not verified: ${user.uid}');
              return const EmailVerificationScreen();
            }

            ErrorLogger.logInfo('Auth', 'User authenticated and email verified: ${user.uid}');
            if (_initializedUserUid != user.uid) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted) {
                  return;
                }

                _initializedUserUid = user.uid;
                Provider.of<UserProvider>(context, listen: false)
                    .loadUserProfile(user.uid);
                Provider.of<ClubProvider>(context, listen: false).loadClubs();
                NotificationService.initForUid(user.uid);
                _setupDeletionListener();
              });
            }
 
            return Consumer2<EventProvider, CompanyProvider>(
              builder: (context, eventProvider, companyProvider, child) {
                if (!eventProvider.isLoaded) {
                  return const Scaffold(
                    backgroundColor: AppColors.calPolyGreen,
                    body: Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                  );
                }
 
                if (companyProvider.isLoaded && eventProvider.needsLogoLinking) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    eventProvider.linkCompanyLogos(companyProvider.allCompanies);
                  });
                }
 
                return const Scaffold(
                  appBar: GoldAppBar(),
                  body: RenderedPage(),
                );
              },
            );
          },
        );
      },
    );
  }


    
}