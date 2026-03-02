import 'package:ccce_application/common/theme/theme.dart';
import 'package:ccce_application/common/widgets/cal_poly_menu_bar.dart';
import 'package:flutter/material.dart';

class Asc2026Screen extends StatelessWidget {
  final GlobalKey<ScaffoldState> scaffoldKey;
  const Asc2026Screen({super.key, required this.scaffoldKey});

  Widget _sectionCard({
    required BuildContext context,
    required String title,
    required String body,
    required String buttonLabel,
    required VoidCallback onPressed,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Container(
      width: screenWidth * 0.88,
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'SansSerifProSemiBold',
              fontSize: 20,
              color: AppColors.calPolyGreen,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: const TextStyle(
              fontFamily: 'SansSerifPro',
              fontSize: 14,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.lightGold,
                elevation: 0,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.zero,
                ),
              ),
              child: Text(
                buttonLabel,
                style: const TextStyle(
                  color: Colors.black,
                  fontFamily: 'SansSerifProSemiBold',
                  fontSize: 15,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showComingSoon(BuildContext context, String label) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label details will be posted soon.'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      color: AppColors.calPolyGreen,
      child: SafeArea(
        child: Column(
          children: [
            CalPolyMenuBar(scaffoldKey: scaffoldKey),
            Expanded(
              child: SingleChildScrollView(
                child: Center(
                  child: Column(
                    children: [
                      SizedBox(height: screenHeight * 0.03),
                      const Text(
                        'ASC 2026',
                        style: TextStyle(
                          fontFamily: 'SansSerifProSemiBold',
                          fontSize: 30,
                          color: AppColors.tanText,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Conference Hub',
                        style: TextStyle(
                          fontFamily: 'SansSerifPro',
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: screenHeight * 0.025),
                      _sectionCard(
                        context: context,
                        title: 'Agenda',
                        body:
                            'View conference sessions, keynotes, and timing updates in one place.',
                        buttonLabel: 'View Agenda',
                        onPressed: () => _showComingSoon(context, 'Agenda'),
                      ),
                      const SizedBox(height: 12),
                      _sectionCard(
                        context: context,
                        title: 'Map',
                        body:
                            'Find buildings, rooms, and event locations around campus quickly.',
                        buttonLabel: 'Open Map',
                        onPressed: () => _showComingSoon(context, 'Map'),
                      ),
                      const SizedBox(height: 12),
                      _sectionCard(
                        context: context,
                        title: 'Sponsors',
                        body:
                            'See sponsor companies, booths, and featured opportunities during ASC 2026.',
                        buttonLabel: 'View Sponsors',
                        onPressed: () => _showComingSoon(context, 'Sponsors'),
                      ),
                      const SizedBox(height: 12),
                      _sectionCard(
                        context: context,
                        title: 'Check-In',
                        body:
                            'Use this section for attendee check-in and on-site conference QR details.',
                        buttonLabel: 'Open Check-In',
                        onPressed: () => _showComingSoon(context, 'Check-In'),
                      ),
                      SizedBox(height: screenHeight * 0.05),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
