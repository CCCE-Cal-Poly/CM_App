import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ccce_application/rendered_page.dart';
import 'package:ccce_application/common/features/sign_up.dart';
import 'package:ccce_application/common/widgets/gold_app_bar.dart';
import 'package:ccce_application/common/theme/colors.dart';

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

                  Text(
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
                      style: TextStyle(
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
                    decoration: BoxDecoration(
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
                        hintStyle: TextStyle(
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
                    decoration: BoxDecoration(
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
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.zero, // No rounded corners
                        ),
                        elevation: 0, // No shadow
                      ),
                      child: Text(
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
                    onTap: () {
                      // Handle the tap event (e.g., navigate to sign-up page)
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => SignUp()),
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
                      Text(
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
                      onPressed: _signInFunc,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.tanText,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.zero, // No rounded corners
                        ),
                        elevation: 0, // No shadow
                      ),
                      child: Text(
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
        // User is confirmed to be non-null, proceed with navigation
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
}
