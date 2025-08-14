import 'dart:async';
import 'package:ccce_application/common/features/sign_up.dart';
import 'package:ccce_application/common/providers/event_provider.dart';
import 'package:ccce_application/common/theme/theme.dart';
import 'package:ccce_application/common/widgets/gold_app_bar.dart';
import 'package:ccce_application/rendered_page.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EmailVerificationScreen extends StatefulWidget {
  const EmailVerificationScreen({super.key});

  @override
  State<EmailVerificationScreen> createState() => _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  bool _isResending = false;
  Timer? _checkTimer;

  @override
  void initState() {
    super.initState();

    // Start polling for verification
    _checkTimer = Timer.periodic(const Duration(seconds: 3), (_) async {
      await FirebaseAuth.instance.currentUser?.reload();
      final user = FirebaseAuth.instance.currentUser;
      if (user != null && user.emailVerified) {
        _checkTimer?.cancel();
        _onVerified();
      }
    });
  }

  @override
  void dispose() {
    _checkTimer?.cancel();
    super.dispose();
  }

  void _onVerified() async {
    // Set TOS now that they're verified
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('TOS', true);

    // Optional: fetch events after verification
    final eventProvider = Provider.of<EventProvider>(context, listen: false);
    await eventProvider.fetchAllEvents();

    // Go to the main app
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MaterialApp(
          home: Scaffold(appBar: GoldAppBar(), body: RenderedPage()),
        )),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.mail, size: 64, color: AppColors.calPolyGreen),
            const SizedBox(height: 16),
            const Text(
              "Email Verification",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                "A verification email has been sent to your inbox.\nPlease verify your email to continue.",
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 20),

            // Resend email
            SizedBox(
              width: 200,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.calPolyGreen,
                  foregroundColor: AppColors.lightGold,
                  shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.zero),
                ),
                onPressed: _isResending
                    ? null
                    : () async {
                        setState(() => _isResending = true);
                        await FirebaseAuth.instance.currentUser
                            ?.sendEmailVerification();
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
                    : const Text("Resend Email"),
              ),
            ),
            const SizedBox(height: 16),

            TextButton(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const SignUp()),
                );
              },
              child: const Text(
                "I'm not receiving an email",
                style: TextStyle(color: Colors.black54),
              ),
            )
          ],
        ),
      ),
    );
  }
}