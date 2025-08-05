import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:ccce_application/common/theme/theme.dart';

class WelcomePage2 extends StatelessWidget {
  const WelcomePage2({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final smallerSide = screenWidth < screenHeight ? screenWidth : screenHeight;

    return Scaffold(
      backgroundColor: AppColors.calPolyGreen,
      body: SafeArea(
        child: Stack(
          alignment: Alignment.center,
          children: [
            Center(
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
                    child: const AutoSizeText.rich(
                      TextSpan(
                        style: TextStyle(fontSize: 18, color: Colors.white),
                        children: [
                          TextSpan(
                            text:
                                'Cal Poly Construction Management\'s hub\nfor ',
                          ),
                          TextSpan(
                            text: 'industry connections, club meetings,\n',
                            style: TextStyle(color: AppColors.tanText),
                          ),
                          TextSpan(
                            text: 'event reminders, ',
                            style: TextStyle(color: AppColors.tanText),
                          ),
                          TextSpan(
                            text: 'and more!',
                          ),
                        ],
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 3,
                      minFontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              bottom: screenHeight * 0.10,
              child: Column(children: [
                Image.asset(
                  'assets/icons/two_of_three_dots.png',
                ),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}
