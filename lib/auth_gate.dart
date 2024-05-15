import 'package:ccce_application/rendered_page.dart';
import 'package:firebase_auth/firebase_auth.dart' hide EmailAuthProvider;
import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:flutter/material.dart';
// import 'package:ccce_application/src/screens/home_page.dart';

// import 'main.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});
  static const calPolyGreen = Color(0xFF003831);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return SignInScreen(         
            providers: [
              EmailAuthProvider(),
            ],
            headerBuilder: (context, constraints, shrinkOffset) {
              return Padding(
                padding: const EdgeInsets.all(20),
                child: AspectRatio(
                  aspectRatio: 1,
                  child: Image.asset('assets/cmLogo.jpg'),
                ),
              );
            },
            subtitleBuilder: (context, action) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: action == AuthAction.signIn
                    ? const Text(
                        'Welcome to the Construction Management App, please sign in!')
                    : const Text(
                        'Welcome to Construction Management App, please sign up!'),
              );
            },
          );
        }

        return const RenderedPage();
      },
    );
  }
}
