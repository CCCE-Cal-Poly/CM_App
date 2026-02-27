// sign_up.dart:

import 'package:ccce_application/common/features/verification_screen.dart';
import 'package:ccce_application/common/constants/app_constants.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ccce_application/common/features/sign_in.dart';
import 'package:ccce_application/common/widgets/gold_app_bar.dart';
import 'package:ccce_application/common/theme/theme.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:ccce_application/services/error_logger.dart';

class SignUp extends StatefulWidget {
  const SignUp({super.key});

  @override
  _SignUpState createState() => _SignUpState();
}

class _SignUpState extends State<SignUp> {
  static dynamic errorMsg = '';
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
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

                  // First Name Field
                  Container(
                    width: screenWidth * 0.75,
                    height: screenHeight * 0.065,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                    ),
                    child: TextField(
                      controller: _firstNameController,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlignVertical: TextAlignVertical.center,
                      decoration: InputDecoration(
                        isDense: true,
                        hintText: 'First Name',
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

                  // Last Name Field
                  Container(
                    width: screenWidth * 0.75,
                    height: screenHeight * 0.065,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                    ),
                    child: TextField(
                      controller: _lastNameController,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlignVertical: TextAlignVertical.center,
                      decoration: InputDecoration(
                        isDense: true,
                        hintText: 'Last Name',
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

                  // Email Field
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

                  // Password Field
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
                  SizedBox(height: screenHeight * 0.020),

                  // Confirm Password Field
                  Container(
                    width: screenWidth * 0.75,
                    height: screenHeight * 0.065,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                    ),
                    child: TextField(
                      controller: _confirmPasswordController,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.black,
                        fontWeight:
                            FontWeight.bold, // This makes the typed text bold
                      ),
                      obscureText: true,
                      decoration: const InputDecoration(
                        hintText: 'Confirm Password',
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
                  SizedBox(height: screenHeight * 0.030),

                  // Sign Up Button
                  SizedBox(
                    width: screenWidth * 0.75,
                    height: screenHeight * 0.065,
                    child: ElevatedButton(
                      onPressed: _signUpFunc,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.lightGold,
                        shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.zero),
                      ),
                      child: const Text(
                        'Sign Up',
                        style: TextStyle(
                          fontSize: 20,
                          color: Colors.black,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.020),
                  GestureDetector(
                    onTap: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => const SignIn()),
                      );
                    },
                    child: const Text(
                      "Already have an account? Sign In",
                      style: TextStyle(
                          color: AppColors.tanText,
                          fontSize: 14,
                          decoration: TextDecoration.underline,
                          decorationColor: AppColors.tanText),
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

  Future<void> _signUpFunc() async {
    ErrorLogger.logInfo('SignUp',
        'Attempting to sign up user with email: ${_emailController.text.trim()}');
    try {
      String firstName = _firstNameController.text.trim();
      String lastName = _lastNameController.text.trim();
      String email = _emailController.text.trim();
      String password = _passwordController.text.trim();
      String confirmPassword = _confirmPasswordController.text.trim();

      if (firstName.isEmpty) {
        ErrorLogger.logWarning(
            'SignUp', 'First name is empty during signup attempt');
        setState(() {
          errorMsg = AppConstants.errorFirstNameRequired;
        });
        return;
      }

      if (lastName.isEmpty) {
        ErrorLogger.logWarning(
            'SignUp', 'Last name is empty during signup attempt');
        setState(() {
          errorMsg = AppConstants.errorLastNameRequired;
        });
        return;
      }

      if (password.length < AppConstants.minPasswordLength) {
        ErrorLogger.logWarning('SignUp',
            'Password does not meet length requirement during signup attempt');
        setState(() {
          errorMsg = AppConstants.errorPasswordRequirementNotMet;
        });
        return;
      }

      if (password != confirmPassword) {
        ErrorLogger.logWarning('SignUp',
            'Password and confirm password do not match during signup attempt');
        setState(() {
          errorMsg = AppConstants.errorPasswordMismatch;
        });
        return;
      }

      ErrorLogger.logInfo('SignUp',
          'Input validation passed for email: $email, proceeding with Firebase signup');

      try {
        await FirebaseAuth.instance
            .createUserWithEmailAndPassword(email: email, password: password);
      } catch (e) {
        if (e is FirebaseAuthException) {
          String errorMessage = ErrorLogger.getAuthErrorMessage(e);
          ErrorLogger.logError('SignUp',
              'FirebaseAuthException during user creation: $errorMessage',
              error: e);
          setState(() {
            errorMsg = errorMessage;
          });
        } else {
          ErrorLogger.logError(
              'SignUp', 'Unexpected error during user creation',
              error: e);
          setState(() {
            errorMsg = AppConstants.errorUnexpected;
          });
        }
        return; // Exit the function if user creation fails
      }
      ErrorLogger.logInfo('SignUp', 'User created with email: $email');

      User? user = FirebaseAuth.instance.currentUser;
      String? userID = user?.uid;
      if (userID == null) {
        setState(() {
          errorMsg = AppConstants.errorFailedCreateUser;
        });
        return;
      }
      // 3. Get FCM Token and add to user document in Firestore
      String? fcmToken = await FirebaseMessaging.instance.getToken();

      ErrorLogger.logInfo('SignUp',
          'Retrieved FCM token during signup: $fcmToken for user: $userID');

      ErrorLogger.logInfo('SignUp', 'FCM Token on signup: $fcmToken');
      // Prepare user data map
      Map<String, dynamic> userData = {
        'email': email,
        'firstName': firstName,
        'lastName': lastName,
        'schoolYear': "",
        'company': "",
        'role': "",
        'admin': false
      };
      // Add FCM token if available
      if (fcmToken != null) {
        userData['fcmToken'] = fcmToken;
      } else {
        ErrorLogger.logWarning(
            'SignUp', 'FCM token was null during signup for user: $userID');
        // Consider if you want to handle this more robustly, e.g.,
        // retrying token retrieval later or logging to an error reporting service.
      }

      ErrorLogger.logInfo('SignUp',
          'Storing user data in Firestore for user: $userID with data: $userData');
      // Store user data in Firestore
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userID)
            .set(userData);
      } catch (e) {
        ErrorLogger.logError(
            'SignUp', 'Error storing user data in Firestore for user: $userID',
            error: e);
        // You might want to decide how to handle this case. For example, you could choose to continue with the signup process even if Firestore storage fails, or you could set an error message and return.
      }

      ErrorLogger.logInfo(
          'SignUp', 'User data stored in Firestore for user: $userID');

      // Send verification email and navigate to verification screen.
      // Even if the StreamBuilder in main.dart catches the auth state change
      // and renders the verification screen, this explicit navigation ensures
      // the user sees it immediately.
      if (user != null) {
        setState(() {
          errorMsg = "";
        });

        await user.sendEmailVerification();

        ErrorLogger.logInfo(
            'SignUp', 'Verification email sent to: $email for user: $userID');

        ErrorLogger.logInfo('SignUp',
            'User signed up with email: $email, verification email sent');
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const EmailVerificationScreen()),
        );
      }
    } catch (e) {
      String errorMessage = AppConstants.errorUnexpected;
      if (e is FirebaseAuthException) {
        errorMessage = ErrorLogger.getAuthErrorMessage(e);
      } else {
        ErrorLogger.logError('SignUp', 'Unexpected signup error', error: e);
      }
      setState(() {
        errorMsg = errorMessage;
      });
    }
  }
}
 










// import 'package:ccce_application/common/features/verification_screen.dart';
// import 'package:ccce_application/common/constants/app_constants.dart';
// import 'package:flutter/material.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:ccce_application/common/features/sign_in.dart';
// import 'package:ccce_application/common/widgets/gold_app_bar.dart';
// import 'package:ccce_application/common/theme/theme.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_messaging/firebase_messaging.dart';
// import 'package:ccce_application/services/error_logger.dart';

// class SignUp extends StatefulWidget {
//   const SignUp({super.key});

//   @override
//   _SignUpState createState() => _SignUpState();
// }

// class _SignUpState extends State<SignUp> {
//   static dynamic errorMsg = '';
//   final TextEditingController _firstNameController = TextEditingController();
//   final TextEditingController _lastNameController = TextEditingController();
//   final TextEditingController _emailController = TextEditingController();
//   final TextEditingController _passwordController = TextEditingController();
//   final TextEditingController _confirmPasswordController =
//       TextEditingController();

//   @override
//   void initState() {
//     super.initState();
//   }

//   @override
//   void dispose() {
//     _firstNameController.dispose();
//     _lastNameController.dispose();
//     _emailController.dispose();
//     _passwordController.dispose();
//     _confirmPasswordController.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     final screenHeight = MediaQuery.of(context).size.height;
//     final screenWidth = MediaQuery.of(context).size.width;

//     return Scaffold(
//       appBar: const GoldAppBar(),
//       backgroundColor: AppColors.calPolyGreen,
//       body: SingleChildScrollView(
//         child: Center(
//           child: Stack(
//             alignment: Alignment.center,
//             children: [
//               Column(
//                 crossAxisAlignment: CrossAxisAlignment.center,
//                 children: <Widget>[
//                   SizedBox(height: screenHeight * 0.1),

//                   // 👷 Hardhat logo image
//                   Padding(
//                     padding: EdgeInsets.only(
//                       top: screenHeight * 0.02,
//                       bottom: screenHeight * 0.03,
//                     ),
//                     child: Image.asset(
//                       'assets/icons/hardhat.png',
//                       height: screenHeight * 0.12,
//                     ),
//                   ),

//                   const Text(
//                     'Cal Poly Construction\nManagement',
//                     textAlign: TextAlign.center,
//                     style: TextStyle(
//                       fontSize: 20,
//                       color: AppColors.tanText,
//                       fontWeight: FontWeight.bold,
//                       fontFamily: 'SansSerifPro',
//                     ),
//                   ),
//                   SizedBox(
//                     height: screenHeight * 0.025,
//                     child: Text(
//                       errorMsg,
//                       style: const TextStyle(
//                         color: Colors.red,
//                         fontSize: 16,
//                         fontWeight: FontWeight.w600,
//                       ),
//                     ),
//                   ),

//                   // First Name Field
//                   Container(
//                     width: screenWidth * 0.75,
//                     height: screenHeight * 0.065,
//                     decoration: const BoxDecoration(
//                       color: Colors.white,
//                     ),
//                     child: TextField(
//                       controller: _firstNameController,
//                       style: const TextStyle(
//                         fontSize: 16,
//                         color: Colors.black,
//                         fontWeight: FontWeight.bold,
//                       ),
//                       textAlignVertical: TextAlignVertical.center,
//                       decoration: InputDecoration(
//                         isDense: true,
//                         hintText: 'First Name',
//                         border: InputBorder.none,
//                         contentPadding: EdgeInsets.symmetric(
//                           vertical: screenHeight * 0.015,
//                           horizontal: screenWidth * 0.025,
//                         ),
//                         hintStyle: const TextStyle(
//                           fontSize: 16,
//                           color: Colors.black,
//                           fontWeight: FontWeight.bold,
//                         ),
//                       ),
//                     ),
//                   ),
//                   SizedBox(height: screenHeight * 0.020),

//                   // Last Name Field
//                   Container(
//                     width: screenWidth * 0.75,
//                     height: screenHeight * 0.065,
//                     decoration: const BoxDecoration(
//                       color: Colors.white,
//                     ),
//                     child: TextField(
//                       controller: _lastNameController,
//                       style: const TextStyle(
//                         fontSize: 16,
//                         color: Colors.black,
//                         fontWeight: FontWeight.bold,
//                       ),
//                       textAlignVertical: TextAlignVertical.center,
//                       decoration: InputDecoration(
//                         isDense: true,
//                         hintText: 'Last Name',
//                         border: InputBorder.none,
//                         contentPadding: EdgeInsets.symmetric(
//                           vertical: screenHeight * 0.015,
//                           horizontal: screenWidth * 0.025,
//                         ),
//                         hintStyle: const TextStyle(
//                           fontSize: 16,
//                           color: Colors.black,
//                           fontWeight: FontWeight.bold,
//                         ),
//                       ),
//                     ),
//                   ),
//                   SizedBox(height: screenHeight * 0.020),

//                   // Email Field
//                   Container(
//                     width: screenWidth * 0.75,
//                     height: screenHeight * 0.065,
//                     decoration: const BoxDecoration(
//                       color: Colors.white,
//                     ),
//                     child: TextField(
//                       controller: _emailController,
//                       style: const TextStyle(
//                         fontSize: 16,
//                         color: Colors.black,
//                         fontWeight:
//                             FontWeight.bold, // This makes the typed text bold
//                       ),
//                       textAlignVertical: TextAlignVertical.center,
//                       decoration: InputDecoration(
//                         isDense: true,
//                         hintText: 'Email',
//                         border: InputBorder.none,
//                         contentPadding: EdgeInsets.symmetric(
//                           vertical: screenHeight * 0.015,
//                           horizontal: screenWidth * 0.025,
//                         ),
//                         hintStyle: const TextStyle(
//                           fontSize: 16,
//                           color: Colors.black,
//                           fontWeight: FontWeight.bold,
//                         ),
//                       ),
//                     ),
//                   ),
//                   SizedBox(height: screenHeight * 0.020),

//                   // Password Field
//                   Container(
//                     width: screenWidth * 0.75,
//                     height: screenHeight * 0.065,
//                     decoration: const BoxDecoration(
//                       color: Colors.white,
//                     ),
//                     child: TextField(
//                       controller: _passwordController,
//                       style: const TextStyle(
//                         fontSize: 16,
//                         color: Colors.black,
//                         fontWeight:
//                             FontWeight.bold, // This makes the typed text bold
//                       ),
//                       obscureText: true,
//                       decoration: const InputDecoration(
//                         hintText: 'Password',
//                         border: InputBorder.none,
//                         contentPadding: EdgeInsets.all(10),
//                         hintStyle: TextStyle(
//                           fontSize: 16,
//                           color: Colors.black,
//                           fontWeight: FontWeight.bold,
//                         ),
//                       ),
//                     ),
//                   ),
//                   SizedBox(height: screenHeight * 0.020),

//                   // Confirm Password Field
//                   Container(
//                     width: screenWidth * 0.75,
//                     height: screenHeight * 0.065,
//                     decoration: const BoxDecoration(
//                       color: Colors.white,
//                     ),
//                     child: TextField(
//                       controller: _confirmPasswordController,
//                       style: const TextStyle(
//                         fontSize: 16,
//                         color: Colors.black,
//                         fontWeight:
//                             FontWeight.bold, // This makes the typed text bold
//                       ),
//                       obscureText: true,
//                       decoration: const InputDecoration(
//                         hintText: 'Confirm Password',
//                         border: InputBorder.none,
//                         contentPadding: EdgeInsets.all(10),
//                         hintStyle: TextStyle(
//                           fontSize: 16,
//                           color: Colors.black,
//                           fontWeight: FontWeight.bold,
//                         ),
//                       ),
//                     ),
//                   ),
//                   SizedBox(height: screenHeight * 0.030),

//                   // Sign Up Button
//                   SizedBox(
//                     width: screenWidth * 0.75,
//                     height: screenHeight * 0.065,
//                     child: ElevatedButton(
//                       onPressed: _signUpFunc,
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: AppColors.lightGold,
//                         shape: const RoundedRectangleBorder(
//                             borderRadius: BorderRadius.zero),
//                       ),
//                       child: const Text(
//                         'Sign Up',
//                         style: TextStyle(
//                           fontSize: 20,
//                           color: Colors.black,
//                           fontWeight: FontWeight.w500,
//                         ),
//                       ),
//                     ),
//                   ),
//                   SizedBox(height: screenHeight * 0.020),
//                   GestureDetector(
//                     onTap: () {
//                       Navigator.pushReplacement(
//                         context,
//                         MaterialPageRoute(builder: (context) => const SignIn()),
//                       );
//                     },
//                     child: const Text(
//                       "Already have an account? Sign In",
//                       style: TextStyle(
//                           color: AppColors.tanText,
//                           fontSize: 14,
//                           decoration: TextDecoration.underline,
//                           decorationColor: AppColors.tanText),
//                     ),
//                   ),
//                 ],
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Future<void> _signUpFunc() async {
//     try {
//       String firstName = _firstNameController.text.trim();
//       String lastName = _lastNameController.text.trim();
//       String email = _emailController.text.trim();
//       String password = _passwordController.text.trim();
//       String confirmPassword = _confirmPasswordController.text.trim();

//       if (firstName.isEmpty) {
//         if (mounted) {
//           setState(() {
//             errorMsg = AppConstants.errorFirstNameRequired;
//           });
//         }
//         return;
//       }

//       if (lastName.isEmpty) {
//         if (mounted) {
//           setState(() {
//             errorMsg = AppConstants.errorLastNameRequired;
//           });
//         }
//         return;
//       }

//       if (password.length < AppConstants.minPasswordLength) {
//         if (mounted) {
//           setState(() {
//             errorMsg = AppConstants.errorPasswordRequirementNotMet;
//           });
//         }
//         return;
//       }

//       if (password != confirmPassword) {
//         if (mounted) {
//           setState(() {
//             errorMsg = AppConstants.errorPasswordMismatch;
//           });
//         }
//         return;
//       }
//       await FirebaseAuth.instance
//           .createUserWithEmailAndPassword(email: email, password: password);
//       UserCredential userCredential =
//           await FirebaseAuth.instance.signInWithEmailAndPassword(
//         email: email,
//         password: password,
//       );
//       User? user = FirebaseAuth.instance.currentUser;

//       String? userID = userCredential.user?.uid;
//       if (userID == null) {
//         if (mounted) {
//           setState(() {
//             errorMsg = AppConstants.errorFailedCreateUser;
//           });
//         }
//         return;
//       }
//       // 3. Get FCM Token and add to user document in Firestore
//       String? fcmToken = await FirebaseMessaging.instance.getToken();
//       ErrorLogger.logInfo('SignUp', 'FCM Token on signup: $fcmToken');
//       // Prepare user data map
//       Map<String, dynamic> userData = {
//         'email': email,
//         'firstName': firstName,
//         'lastName': lastName,
//         'schoolYear': "",
//         'company': "",
//         'role': "",
//         'admin': false
//       };
//       // Add FCM token if available
//       if (fcmToken != null) {
//         userData['fcmToken'] = fcmToken;
//       } else {
//         ErrorLogger.logWarning(
//             'SignUp', 'FCM token was null during signup for user: $userID');
//         // Consider if you want to handle this more robustly, e.g.,
//         // retrying token retrieval later or logging to an error reporting service.
//       }

//       // Store user data in Firestore
//       await FirebaseFirestore.instance
//           .collection('users')
//           .doc(userID)
//           .set(userData);

//       // Send verification email and navigate to verification screen.
//       // Even if the StreamBuilder in main.dart catches the auth state change
//       // and renders the verification screen, this explicit navigation ensures
//       // the user sees it immediately.
//       if (user != null) {
//         print("User is not null");
//         if (mounted) {
//           print("Mounted is true");
//           setState(() {
//             errorMsg = "";
//           });
//         }else{
//           print("Mounted is false");
//         }

//         print("SIGN UP CHECKPOINT 1");

//         await userCredential.user!.sendEmailVerification();
 
//         print("SIGN UP CHECKPOINT 2");

//         // Navigator.pushReplacement(
//         //   context,
//         //   MaterialPageRoute(builder: (_) => const EmailVerificationScreen()),
//         // );
//       }
//       print("User signed up with email: $email");
//     } catch (e) {
//       String errorMessage = AppConstants.errorUnexpected;
//       if (e is FirebaseAuthException) {
//         errorMessage = ErrorLogger.getAuthErrorMessage(e);
//       } else {
//         ErrorLogger.logError('SignUp', 'Unexpected signup error', error: e);
//       }
//       if (mounted) {
//         setState(() {
//           errorMsg = errorMessage;
//         });
//       }
//     }
//   }
// }
