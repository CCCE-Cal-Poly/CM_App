import 'package:ccce_application/common/features/asc_2026_maps.dart';
import 'package:ccce_application/common/features/asc_2026_sponsors_directory.dart';
import 'package:ccce_application/common/features/asc_2026_agenda.dart';
import 'package:ccce_application/common/features/my_info_sessions.dart';
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
    required List<String> buttonLabels,
    required List<VoidCallback> onPressedFunctions,
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
          ...List.generate(
            buttonLabels.length,
            (index) => Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: onPressedFunctions[index],
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.lightGold,
                      elevation: 0,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.zero,
                      ),
                    ),
                    child: Text(
                      buttonLabels[index],
                      style: const TextStyle(
                        color: Colors.black,
                        fontFamily: 'SansSerifProSemiBold',
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
                if (index < buttonLabels.length - 1) const SizedBox(height: 8),
              ],
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
      child: Padding(
        padding: const EdgeInsets.only(right: 16.0, left: 16.0, top: 16.0),
        child: Column(
          children: [
            Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: CalPolyMenuBar(scaffoldKey: scaffoldKey)),
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
                        buttonLabels: const ['View Agenda', 'My Agenda'],
                        onPressedFunctions: [
                          () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const Asc2026Agenda(),
                            ),
                          ),
                          () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => Scaffold(
                                appBar: AppBar(
                                  title: const Text("My Agenda",
                                      style: TextStyle(
                                          fontFamily: AppFonts.sansProSemiBold,
                                          color: AppColors.welcomeLightYellow,
                                          fontWeight: FontWeight.w600)),
                                  backgroundColor: AppColors.calPolyGreen,
                                  foregroundColor: Colors.white,
                                ),
                                backgroundColor: AppColors.calPolyGreen,
                                body: buildInfoSessionDisplay(context, "asc2026"),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _sectionCard(
                        context: context,
                        title: 'Map',
                        body:
                            'Find buildings, rooms, and event locations around campus quickly.',
                        buttonLabels: const ['Open Map'],
                        onPressedFunctions: [
                          () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const Asc2026Maps(),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _sectionCard(
                        context: context,
                        title: 'Sponsors',
                        body:
                            'See sponsor companies, booths, and featured opportunities during ASC 2026.',
                        buttonLabels: const ['View Sponsors'],
                        onPressedFunctions: [
                          () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) =>
                                  const Asc2026SponsorsDirectory(),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: screenHeight * 0.05),                    ],
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
