 
// verification_screen.dart:
 
import 'dart:async';
import 'package:ccce_application/common/features/app_entry_gate.dart';
import 'package:ccce_application/common/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:ccce_application/services/notification_service.dart';
 
class EmailVerificationScreen extends StatefulWidget {
  const EmailVerificationScreen({super.key});
 
  @override
  State<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}
 
class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  bool _isResending = false;
  Timer? _checkTimer;
  int _resendCooldown = 0;
  Timer? _cooldownTimer;
 
  @override
  void initState() {
    super.initState();
 
    // Immediately check if already verified (handles stale cache on app restart)
    _checkVerificationNow();
 
    // Then start polling every 3 seconds
    _checkTimer = Timer.periodic(const Duration(seconds: 3), (_) async {
      await _checkVerificationNow();
    });
  }
 
  Future<void> _checkVerificationNow() async {
    try {
      await FirebaseAuth.instance.currentUser?.reload();
    } catch (e) {
      // reload() can throw if user was deleted or token expired.
      // If the user no longer exists, sign them out gracefully.
      if (e is FirebaseAuthException &&
          (e.code == 'user-not-found' || e.code == 'user-disabled')) {
        _checkTimer?.cancel();
        _cooldownTimer?.cancel();
        await FirebaseAuth.instance.signOut();
        return;
      }
      // For network errors, just skip this cycle — the timer will retry.
      return;
    }
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && user.emailVerified) {
      _checkTimer?.cancel();
      _cooldownTimer?.cancel();
      _onVerified();
    }
  }
 
  @override
  void dispose() {
    _checkTimer?.cancel();
    _cooldownTimer?.cancel();
    super.dispose();
  }
 
  void _onVerified() async {
    // Set TOS now that they're verified
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('TOS', true);
 
    // Route back through the shared app entry gate so all bootstrap logic
    // (auth/TOS checks, provider loading, app shell routing) runs in one place.
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => const AppEntryGate(),
      ),
      (route) => false,
    );
  }
 
  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // Prevent back button — user must verify or sign out
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.mail, size: 64, color: AppColors.calPolyGreen),
              const SizedBox(height: 16),
              const Text(
                "Email Verification Required",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  "A verification email has been sent to your inbox.\nPlease verify your email to continue.\n\nCheck your spam or junk folder if you don't see the email.\n\nThis page will automatically proceed once your email is verified.",
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 20),
 
              // Resend email with cooldown to prevent spam
              SizedBox(
                width: 200,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.calPolyGreen,
                    foregroundColor: AppColors.lightGold,
                    shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.zero),
                  ),
                  onPressed: (_isResending || _resendCooldown > 0)
                      ? null
                      : () async {
                          if (!mounted) return;
                          setState(() => _isResending = true);
                          try {
                            await FirebaseAuth.instance.currentUser
                                ?.sendEmailVerification();
                            if (!context.mounted) return;
 
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Verification email sent!'),
                                backgroundColor: Colors.green,
                              ),
                            );
 
                            // Start a 60-second cooldown to prevent abuse
                            setState(() {
                              _resendCooldown = 60;
                            });
                            _cooldownTimer?.cancel();
                            _cooldownTimer = Timer.periodic(
                              const Duration(seconds: 1),
                              (timer) {
                                if (!mounted) {
                                  timer.cancel();
                                  return;
                                }
                                setState(() {
                                  _resendCooldown--;
                                  if (_resendCooldown <= 0) {
                                    timer.cancel();
                                  }
                                });
                              },
                            );
                          } catch (e) {
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error: $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                          if (!mounted) return;
                          setState(() => _isResending = false);
                        },
                  child: _isResending
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(_resendCooldown > 0
                          ? "Resend (${_resendCooldown}s)"
                          : "Resend Email"),
                ),
              ),
              const SizedBox(height: 16),
 
              TextButton(
                onPressed: () async {
                  // Clean up FCM token before signing out
                  final user = FirebaseAuth.instance.currentUser;
                  if (user != null) {
                    try {
                      final token = await FirebaseMessaging.instance.getToken();
                      if (token != null) {
                        await NotificationService.removeTokenForUser(
                            user.uid, token);
                      }
                    } catch (_) {}
                  }
                  await FirebaseAuth.instance.signOut();
                  // After sign-out, authStateChanges() fires and main.dart's
                  // StreamBuilder will show the SignIn screen automatically.
                  // No manual navigation needed.
                },
                child: const Text(
                  "Use a different email",
                  style: TextStyle(color: Colors.black54),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}



// import 'dart:async';
// import 'package:ccce_application/common/providers/event_provider.dart';
// import 'package:ccce_application/common/theme/theme.dart';
// import 'package:ccce_application/common/widgets/gold_app_bar.dart';
// import 'package:ccce_application/rendered_page.dart';
// import 'package:flutter/material.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:provider/provider.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:firebase_messaging/firebase_messaging.dart';
// import 'package:ccce_application/services/notification_service.dart';

// class EmailVerificationScreen extends StatefulWidget {
//   const EmailVerificationScreen({super.key});

//   @override
//   State<EmailVerificationScreen> createState() => _EmailVerificationScreenState();
// }

// class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
//   bool _isResending = false;
//   Timer? _checkTimer;
//   int _resendCooldown = 0;
//   Timer? _cooldownTimer;

//   @override
//   void initState() {
//     super.initState();

//     // Immediately check if already verified (handles stale cache on app restart)
//     _checkVerificationNow();

//     // Then start polling every 3 seconds
//     _checkTimer = Timer.periodic(const Duration(seconds: 3), (_) async {
//       await _checkVerificationNow();
//     });
//   }

//   Future<void> _checkVerificationNow() async {
//     try {
//       await FirebaseAuth.instance.currentUser?.reload();
//     } catch (e) {
//       // reload() can throw if user was deleted or token expired.
//       // If the user no longer exists, sign them out gracefully.
//       if (e is FirebaseAuthException &&
//           (e.code == 'user-not-found' || e.code == 'user-disabled')) {
//         _checkTimer?.cancel();
//         _cooldownTimer?.cancel();
//         await FirebaseAuth.instance.signOut();
//         return;
//       }
//       // For network errors, just skip this cycle — the timer will retry.
//       return;
//     }
//     final user = FirebaseAuth.instance.currentUser;
//     if (user != null && user.emailVerified) {
//       _checkTimer?.cancel();
//       _cooldownTimer?.cancel();
//       _onVerified();
//     }
//   }

//   @override
//   void dispose() {
//     _checkTimer?.cancel();
//     _cooldownTimer?.cancel();
//     super.dispose();
//   }

//   void _onVerified() async {
//     // Set TOS now that they're verified
//     print("Email verified for user: ${FirebaseAuth.instance.currentUser?.email}");
//     final prefs = await SharedPreferences.getInstance();
//     await prefs.setBool('TOS', true);

//     // Fetch events after verification
//     if (mounted) {
//       final eventProvider = Provider.of<EventProvider>(context, listen: false);
//       await eventProvider.fetchAllEvents();
//     }

//     // Navigate to the main app without creating a nested MaterialApp.
//     // pushAndRemoveUntil clears the entire navigation stack so there is
//     // no way for the user to navigate back to the verification screen.
//     // if (mounted) {
//     //   Navigator.of(context).pushAndRemoveUntil(
//     //     MaterialPageRoute(
//     //       builder: (_) => const Scaffold(
//     //         appBar: GoldAppBar(),
//     //         body: RenderedPage(),
//     //       ),
//     //     ),
//     //     (route) => false,
//     //   );
//     // }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return PopScope(
//       canPop: false, // Prevent back button — user must verify or sign out
//       child: Scaffold(
//         backgroundColor: Colors.white,
//         body: SafeArea(
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               const Icon(Icons.mail, size: 64, color: AppColors.calPolyGreen),
//               const SizedBox(height: 16),
//               const Text(
//                 "Email Verification Required",
//                 style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
//               ),
//               const Padding(
//                 padding: EdgeInsets.all(16.0),
//                 child: Text(
//                   "A verification email has been sent to your inbox.\nPlease verify your email to continue.\n\nCheck your spam or junk folder if you don't see the email.\n\nThis page will automatically proceed once your email is verified.",
//                   textAlign: TextAlign.center,
//                 ),
//               ),
//               const SizedBox(height: 20),

//               // Resend email with cooldown to prevent spam
//               SizedBox(
//                 width: 200,
//                 child: ElevatedButton(
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: AppColors.calPolyGreen,
//                     foregroundColor: AppColors.lightGold,
//                     shape: const RoundedRectangleBorder(
//                         borderRadius: BorderRadius.zero),
//                   ),
//                   onPressed: (_isResending || _resendCooldown > 0)
//                       ? null
//                       : () async {
//                           setState(() => _isResending = true);
//                           try {
//                             await FirebaseAuth.instance.currentUser
//                                 ?.sendEmailVerification();
//                             if (mounted) {
//                               ScaffoldMessenger.of(context).showSnackBar(
//                                 const SnackBar(
//                                   content: Text('Verification email sent!'),
//                                   backgroundColor: Colors.green,
//                                 ),
//                               );
//                               // Start a 60-second cooldown to prevent abuse
//                               setState(() {
//                                 _resendCooldown = 60;
//                               });
//                               _cooldownTimer?.cancel();
//                               _cooldownTimer = Timer.periodic(
//                                 const Duration(seconds: 1),
//                                 (timer) {
//                                   if (!mounted) {
//                                     timer.cancel();
//                                     return;
//                                   }
//                                   setState(() {
//                                     _resendCooldown--;
//                                     if (_resendCooldown <= 0) {
//                                       timer.cancel();
//                                     }
//                                   });
//                                 },
//                               );
//                             }
//                           } catch (e) {
//                             if (mounted) {
//                               ScaffoldMessenger.of(context).showSnackBar(
//                                 SnackBar(
//                                   content: Text('Error: $e'),
//                                   backgroundColor: Colors.red,
//                                 ),
//                               );
//                             }
//                           }
//                           if (mounted) {
//                             setState(() => _isResending = false);
//                           }
//                         },
//                   child: _isResending
//                       ? const SizedBox(
//                           height: 16,
//                           width: 16,
//                           child: CircularProgressIndicator(
//                             strokeWidth: 2,
//                             color: Colors.white,
//                           ),
//                         )
//                       : Text(_resendCooldown > 0
//                           ? "Resend (${_resendCooldown}s)"
//                           : "Resend Email"),
//                 ),
//               ),
//               const SizedBox(height: 16),

//               TextButton(
//                 onPressed: () async {
//                   // Clean up FCM token before signing out
//                   final user = FirebaseAuth.instance.currentUser;
//                   if (user != null) {
//                     try {
//                       final token = await FirebaseMessaging.instance.getToken();
//                       if (token != null) {
//                         await NotificationService.removeTokenForUser(user.uid, token);
//                       }
//                     } catch (_) {}
//                   }
//                   await FirebaseAuth.instance.signOut();
//                   // After sign-out, authStateChanges() fires and main.dart's
//                   // StreamBuilder will show the SignIn screen automatically.
//                   // No manual navigation needed.
//                 },
//                 child: const Text(
//                   "Use a different email",
//                   style: TextStyle(color: Colors.black54),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }