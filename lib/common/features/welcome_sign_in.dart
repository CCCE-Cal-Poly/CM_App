import 'package:ccce_application/common/widgets/gold_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:ccce_application/common/theme/theme.dart';
import 'package:ccce_application/common/features/sign_in.dart';
import 'package:ccce_application/common/features/sign_up.dart';

class WelcomeSignIn extends StatelessWidget {
  const WelcomeSignIn({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final smallerSide = screenWidth < screenHeight ? screenWidth : screenHeight;

    return Scaffold(
      appBar: const GoldAppBar(),
      backgroundColor: AppColors.calPolyGreen,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget>[
              Padding(
                    padding: EdgeInsets.only(
                        top: screenHeight * 0.10, bottom: screenHeight * 0.075),
                    child: Image.asset(
                      'assets/icons/cal_poly_white.png',
                      scale: 0.8,
                      height: smallerSide * 0.1,
                      width: smallerSide * 0.9,
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(bottom: screenHeight * 0.045),
                    child: Image.asset('assets/icons/hardhat.png'),
                  ),
                  Padding(
                    padding: EdgeInsets.only(top: screenHeight * 0.045),
                    child: Text(
                      'Welcome',
                      style: TextStyle(
                          color: AppColors.tanText,
                          fontSize: screenHeight*.06,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'SansSerifPro'),
                    ),
                  ),
              Padding(
                padding: EdgeInsets.only(top: screenHeight * 0.015),
                child: const Text(
                  'Cal Poly Construction\nManagement',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
              SizedBox(height: screenHeight * 0.03),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => SignIn()),
                    (Route<dynamic> route) => false,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.lightGold,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(
                      horizontal: screenWidth * .27,
                      vertical: screenHeight * 0.01),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.zero,
                  ),
                ),
                child: const Text(
                  'Sign In',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                      fontFamily: 'SansSerifPro'),
                ),
              ),
              SizedBox(height: screenHeight * .018),
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
            ],
          ),
        ),
      ),
    );
  }
}
