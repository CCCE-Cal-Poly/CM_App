import 'package:ccce_application/common/providers/event_provider.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ccce_application/rendered_page.dart';
import 'package:ccce_application/common/features/sign_up.dart';
import 'package:ccce_application/common/features/verification_screen.dart';
import 'package:ccce_application/common/widgets/gold_app_bar.dart';
import 'package:ccce_application/common/theme/theme.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class SignIn extends StatefulWidget {
  const SignIn({super.key});

  @override
  State<SignIn> createState() => _SignInState();
}

class _SignInState extends State<SignIn> {
  dynamic errorMsg = '';
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    errorMsg = '';
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: const GoldAppBar(),
      backgroundColor: AppColors.calPolyGreen,
      body: SingleChildScrollView(
        child: Center(
          child: Stack(
            alignment: Alignment.center,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  SizedBox(height: screenHeight * 0.1),

                  // 👷 Hardhat logo image
                  Padding(
                    padding: EdgeInsets.only(
                      top: screenHeight * 0.02,
                      bottom: screenHeight * 0.03,
                    ),
                    child: Image.asset(
                      'assets/icons/hardhat.png',
                      height: screenHeight * 0.12,
                    ),
                  ),

                  const Text(
                    'Cal Poly Construction\nManagement',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 20,
                      color: AppColors.tanText,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'SansSerifPro',
                    ),
                  ),

                  SizedBox(
                    height: screenHeight * 0.025,
                    child: Text(
                      errorMsg,
                      style: const TextStyle(
                        color: Colors.red,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),

                  // Email TextField
                  Container(
                    width: screenWidth * 0.75,
                    height: screenHeight * 0.065,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                    ),
                    child: TextField(
                      controller: _emailController,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.black,
                        fontWeight:
                            FontWeight.bold, // This makes the typed text bold
                      ),
                      textAlignVertical: TextAlignVertical.center,
                      decoration: InputDecoration(
                        isDense: true,
                        hintText: 'Email',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          vertical: screenHeight * 0.015,
                          horizontal: screenWidth * 0.025,
                        ),
                        hintStyle: const TextStyle(
                          fontSize: 16,
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: screenHeight * 0.020),

                  // Password TextField
                  Container(
                    width: screenWidth * 0.75,
                    height: screenHeight * 0.065,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                    ),
                    child: TextField(
                      controller: _passwordController,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.black,
                        fontWeight:
                            FontWeight.bold, // This makes the typed text bold
                      ),
                      obscureText: true,
                      decoration: const InputDecoration(
                        hintText: 'Password',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.all(10),
                        hintStyle: TextStyle(
                          fontSize: 16,
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: screenHeight * 0.02),

                  // Sign In Button
                  SizedBox(
                    width: screenWidth * 0.75,
                    height: screenHeight * 0.065,
                    child: ElevatedButton(
                      onPressed: _signInFunc,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.lightGold,
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.zero, // No rounded corners
                        ),
                        elevation: 0, // No shadow
                      ),
                      child: const Text(
                        'SIGN IN',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: screenHeight * 0.015),

                  GestureDetector(
                    onTap: _showForgotPasswordDialog,
                    child: const Text(
                      'Forgot Password?',
                      style: TextStyle(
                        color: AppColors.tanText,
                        fontSize: 14,
                        decoration: TextDecoration.underline,
                        decorationColor: AppColors.tanText,
                      ),
                    ),
                  ),

                  SizedBox(height: screenHeight * 0.01),

                  GestureDetector(
                    onTap: () {
                      // Handle the tap event (e.g., navigate to sign-up page)
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => const SignUp()),
                      );
                    },
                    child: const Text(
                      "I don't have an account yet...",
                      style: TextStyle(
                          color: AppColors.tanText,
                          fontSize: 14,
                          decoration: TextDecoration.underline,
                          decorationColor: AppColors.tanText),
                    ),
                  ),
                  SizedBox(
                      height: screenHeight *
                          .02), // space after the GestureDetector
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: Divider(
                          color: Colors.white,
                          thickness: screenHeight * 0.001,
                          indent: screenWidth * 0.16,
                          endIndent: screenWidth * 0.03,
                        ),
                      ),
                      const Text(
                        'OR',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Expanded(
                        child: Divider(
                          color: Colors.white,
                          thickness: screenHeight * 0.001,
                          indent: screenWidth * 0.03,
                          endIndent: screenWidth * 0.16,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: screenHeight * .02),
                  SizedBox(
                    width: screenWidth * 0.75,
                    height: screenHeight * 0.065,
                    child: ElevatedButton(
                      onPressed: _signInWithGoogle,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.tanText,
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.zero, // No rounded corners
                        ),
                        elevation: 0, // No shadow
                      ),
                      child: const Text(
                        'Sign In with Google',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _signInFunc() async {
    // Clear previous error messages at the beginning of the attempt
    setState(() {
      errorMsg = "";
    });

    try {
      String email = _emailController.text.trim();
      String password = _passwordController.text.trim();

      if (email.isEmpty || password.isEmpty) {
        setState(() {
          errorMsg = "Email and password cannot be blank.";
        });
        return; // Stop execution if fields are empty
      }

      print("Attempting to sign in with email: $email");

      UserCredential userCredential =
          await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      print("FirebaseAuth.instance.signInWithEmailAndPassword completed.");

      if (userCredential.user != null) {
        print("Sign-in successful, user UID: ${userCredential.user!.uid}");
        
        // Check if email is verified
        if (!userCredential.user!.emailVerified) {
          print("Email not verified, redirecting to verification screen");
          if (mounted) {
            setState(() {
              errorMsg = "";
            });
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const EmailVerificationScreen()),
            );
          }
          return;
        }
        
        // User is confirmed to be non-null and verified, proceed with navigation
        try {
          // Ensure errorMsg is cleared on successful auth before navigation
          if (mounted) {
            // Check if the widget is still in the tree
            setState(() {
              errorMsg = "";
            });
          }

          print("Navigating to RenderedPage...");
          if (mounted) {
            // Check if the widget is still in the tree before navigating
            final prefs = await SharedPreferences.getInstance();
            await prefs.setBool('TOS', true);

            final eventProvider =
                Provider.of<EventProvider>(context, listen: false);
            await eventProvider.fetchAllEvents();
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const MaterialApp(
                    home: Scaffold(appBar: GoldAppBar(), body: RenderedPage())),
              ),
            );
          }
          print("Navigation call to RenderedPage completed.");
        } catch (navError, navStack) {
          print("Error during setState or navigation: $navError");
          print("Navigation Error StackTrace: $navStack");
          if (mounted) {
            setState(() {
              errorMsg = "Error navigating: ${navError.toString()}";
            });
          }
        }
      } else {
        // This case should ideally not be reached if signInWithEmailAndPassword throws an error for failure
        print(
            "Sign-in attempt returned null user, but no exception was thrown.");
        if (mounted) {
          setState(() {
            errorMsg = "Sign-in failed: No user data returned.";
          });
        }
      }
    } catch (e, s) {
      // Catching both exception and stack trace
      print("SIGN_IN_ERROR: $e");
      print("SIGN_IN_STACK_TRACE: $s");
      String tempErrorMsg = "An unexpected error occurred."; // Default message

      if (e is FirebaseAuthException) {
        print("Firebase Auth Exception Code: ${e.code}");
        if (e.code == "wrong-password" ||
            e.code == "invalid-credential" ||
            e.code == "INVALID_LOGIN_CREDENTIALS") {
          tempErrorMsg = "Invalid email or password.";
        } else if (e.code == "invalid-email") {
          tempErrorMsg = "The email address is badly formatted.";
        } else if (e.code == "user-not-found") {
          tempErrorMsg = "No user found with this email.";
        } else if (e.code == "user-disabled") {
          tempErrorMsg = "This user account has been disabled.";
        } else if (e.code == "channel-error" ||
            e.code == "missing-password" ||
            e.code == "missing-email") {
          // Though we check for empty fields above, this can catch other channel issues
          tempErrorMsg = "Please ensure all fields are filled correctly.";
        } else if (e.code == "too-many-requests") {
          tempErrorMsg = "Too many attempts. Please try again later.";
        }
        // You can add more specific Firebase error codes here
        else {
          tempErrorMsg = e.message ??
              "An unknown Firebase error occurred."; // Use Firebase's message if available
        }
      } else {
        // Handle other types of exceptions not from FirebaseAuth
        tempErrorMsg = "An unexpected error occurred: ${e.toString()}";
      }

      if (mounted) {
        // Check if the widget is still in the tree
        setState(() {
          errorMsg = tempErrorMsg;
        });
      }
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() {
      errorMsg = "";
    });

    try {
      // Trigger Google Sign-In flow
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      
      if (googleUser == null) {
        // User canceled the sign-in
        return;
      }

      // Obtain auth details from the request
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credential
      UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      
      if (userCredential.user != null) {
        final user = userCredential.user!;
        print("Google sign-in successful, user UID: ${user.uid}");

        // Check if this is a new user - if so, create Firestore document
        final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        
        if (!userDoc.exists) {
          // New user - create Firestore document
          String? fcmToken = await FirebaseMessaging.instance.getToken();
          
          Map<String, dynamic> userData = {
            'email': user.email ?? '',
            'firstName': user.displayName?.split(' ').first ?? '',
            'lastName': user.displayName?.split(' ').skip(1).join(' ') ?? '',
            'schoolYear': '',
            'company': '',
            'role': '',
            'admin': false,
          };
          
          if (fcmToken != null) {
            userData['fcmToken'] = fcmToken;
          }
          
          await FirebaseFirestore.instance.collection('users').doc(user.uid).set(userData);
        }

        // Google accounts are pre-verified, proceed to main app
        if (mounted) {
          setState(() {
            errorMsg = "";
          });

          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('TOS', true);

          final eventProvider = Provider.of<EventProvider>(context, listen: false);
          await eventProvider.fetchAllEvents();
          
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const MaterialApp(
                home: Scaffold(appBar: GoldAppBar(), body: RenderedPage()),
              ),
            ),
          );
        }
      }
    } catch (e) {
      print("Google Sign-In Error: $e");
      
      String tempErrorMsg = "Failed to sign in with Google.";
      
      if (e is FirebaseAuthException) {
        if (e.code == 'account-exists-with-different-credential') {
          tempErrorMsg = "An account already exists with this email.";
        } else if (e.code == 'invalid-credential') {
          tempErrorMsg = "Invalid credentials. Please try again.";
        } else {
          tempErrorMsg = e.message ?? tempErrorMsg;
        }
      }
      
      if (mounted) {
        setState(() {
          errorMsg = tempErrorMsg;
        });
      }
    }
  }

  void _showForgotPasswordDialog() {
    final TextEditingController resetEmailController = TextEditingController();
    String dialogErrorMsg = '';
    
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppColors.calPolyGreen,
              title: const Text(
                'Reset Password',
                style: TextStyle(
                  color: AppColors.tanText,
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Enter your email address and we\'ll send you a link to reset your password.',
                    style: TextStyle(
                      color: AppColors.tanText,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Note: Check your spam/junk folder if you don\'t see the email.',
                    style: TextStyle(
                      color: AppColors.yellowButton,
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: resetEmailController,
                    style: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                    decoration: const InputDecoration(
                      hintText: 'Email',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.zero,
                      ),
                      hintStyle: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (dialogErrorMsg.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        dialogErrorMsg,
                        style: const TextStyle(
                          color: Colors.red,
                          fontSize: 12,
                        ),
                      ),
                    ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: AppColors.tanText),
                  ),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final email = resetEmailController.text.trim();
                    
                    if (email.isEmpty) {
                      setDialogState(() {
                        dialogErrorMsg = 'Please enter your email address.';
                      });
                      return;
                    }
                    
                    try {
                      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
                      
                      if (!dialogContext.mounted) return;
                      
                      Navigator.of(dialogContext).pop();
                      
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Password reset email sent to $email\nCheck your spam folder if you don\'t see it.'),
                          backgroundColor: Colors.green,
                          duration: const Duration(seconds: 5),
                        ),
                      );
                    } catch (e) {
                      String errorMessage = 'Failed to send reset email.';
                      
                      if (e is FirebaseAuthException) {
                        if (e.code == 'user-not-found') {
                          errorMessage = 'No account found with this email.';
                        } else if (e.code == 'invalid-email') {
                          errorMessage = 'Invalid email address.';
                        } else if (e.code == 'too-many-requests') {
                          errorMessage = 'Too many attempts. Try again later.';
                        }
                      }
                      
                      setDialogState(() {
                        dialogErrorMsg = errorMessage;
                      });
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.yellowButton,
                  ),
                  child: const Text(
                    'Send Reset Link',
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
