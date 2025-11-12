import 'package:auto_size_text/auto_size_text.dart';
import 'package:ccce_application/common/collections/company.dart';
import 'package:ccce_application/common/collections/favoritable.dart';
import 'package:ccce_application/common/providers/app_state.dart';
import 'package:ccce_application/common/theme/theme.dart';
import 'package:ccce_application/common/widgets/resilient_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

Widget jobLogoImage(String? url, double width, double height) {
  return ResilientCircleImage(
    imageUrl: url,
    placeholderAsset: 'assets/icons/default_company.png',
    size: width,
  );
}

class Job extends Favoritable {
  final String id;
  final Company company;
  final String title;
  final String description;
  final String contactName;
  final String contactEmail;
  final String contactPhone;
  final String contactTitle;
  final String location;
  final String? logo;
  final bool partTime;
  final bool internship;

  Job({
    required this.id,
    required this.company,
    required this.title,
    required this.description,
    required this.contactName,
    required this.contactEmail,
    required this.contactPhone,
    required this.contactTitle,
    required this.location,
    this.logo,
    this.partTime = false,
    this.internship = false,
  });
}

class JobItem extends StatelessWidget {
  final Job job;

  const JobItem(this.job, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;
    double screenWidth = MediaQuery.of(context).size.width;
    return Card(
      color: Colors.white,
      shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.zero,
            ),
      elevation: 2,
      margin: const EdgeInsets.all(12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left: Logo
            jobLogoImage(
              job.logo, screenWidth*.1, screenWidth*.1
            ),
            const SizedBox(width: 12),
    
            // Center: Job Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top row: Title and arrow
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        job.title,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const Icon(Icons.arrow_forward),
                    ],
                  ),
                  const SizedBox(height: 4),
                  
                  // Pay + Location
                  const Text(
                    "\$20–25/hr | Austin, TX",
                   style: TextStyle(
                      color: AppColors.darkGoldText,
                      fontSize: 12,
                      fontFamily: AppFonts.sansProSemiBold,
                    ),
                  ),
                  const SizedBox(height: 8),
    
                  // Description (truncated)
                  Padding(
                    padding: const EdgeInsets.only(right: 16, bottom: 6),
                    child: Text(
                      job.description,
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 14,
                        fontFamily: AppFonts.sansProSemiBold,
                        fontWeight: FontWeight.w500
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 3,
                    ),
                  ),
                   job.internship ? Padding(
                     padding: const EdgeInsets.symmetric(vertical: 6.0),
                     child: Container(
                       color: AppColors.kennedyGreen,
                       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 1),
                       child: const Text('Internship',
                       style: TextStyle(
                         color: Colors.black,
                         fontSize: 11,
                         fontWeight: FontWeight.w500,
                         fontFamily: AppFonts.sansProSemiBold
                       ),
                       ),
                     ),
                   ) : const SizedBox.shrink(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class JobPopUp extends StatefulWidget {
  final Job job;

  final VoidCallback onClose;

  const JobPopUp({required this.job, required this.onClose, Key? key})
      : super(key: key);
  
  @override
  JobPopUpState createState() => JobPopUpState();
}

class JobPopUpState extends State<JobPopUp>{

  @override
  Widget build(BuildContext context) {
    final job = widget.job;
    double screenHeight = MediaQuery.of(context).size.height;
    double screenWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      backgroundColor: AppColors.calPolyGreen,
      body: ListView(
        children: [
          Stack(
            children: [
              Center(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.zero,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Close button with arrow
                      Padding(
                        padding: EdgeInsets.all(screenHeight * 0.01),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.arrow_back,
                                  color: Colors.black),
                              onPressed: () {Navigator.of(context).pop();},
                            ),
                          ],
                        ),
                      ),
                      // Circle near the top of the page in the middle
                      Padding(
                        padding: EdgeInsets.all(screenHeight * 0.01),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: screenHeight * .1,
                              height: screenHeight * .1,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white,
                                border:
                                    Border.all(color: Colors.black, width: 1),
                              ),
                              child: Center(
                                child: jobLogoImage(job.logo,
                                    screenWidth * .1, screenWidth * .1),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Company details
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            Text(
                              job.company.name,
                              style: const TextStyle(
                                fontSize: 24.0,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                            Text(
                              job.title,
                              style: const TextStyle(
                                fontSize: 16.0,
                                color: AppColors.darkGoldText,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: SizedBox(
                                width: screenWidth * .5,
                                height: screenHeight * .05,
                                child: Consumer<AppState>(
                                  builder: (context, appState, child) {
                                  final isFavorite = appState.isFavorite(job);
                                  return ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: isFavorite
                                        ? Colors.grey
                                        : AppColors.calPolyGreen,
                                    shape: const RoundedRectangleBorder(
                                      borderRadius: BorderRadius.zero,
                                    ),
                                    elevation: 0,
                                  ),
                                  onPressed: () {
                                    if (isFavorite) {
                                        context
                                            .read<AppState>()
                                            .removeFavorite(job);
                                      } else {
                                        context
                                            .read<AppState>()
                                            .addFavorite(job);
                                      }
                                },
                                child: isFavorite
                                      ? const Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.check,
                                                color: Colors.black, size: 18),
                                            SizedBox(width: 6),
                                            AutoSizeText(
                                              "ADDED",
                                              style: TextStyle(
                                                color: Colors.black,
                                                fontFamily:
                                                    AppFonts.sansProSemiBold,
                                                fontSize: 16.0,
                                                fontWeight: FontWeight.w500,
                                              ),
                                              minFontSize: 10,
                                              maxLines: 1,
                                            ),
                                          ],
                                        )
                                      : const AutoSizeText(
                                          "ADD TO FAVORITES",
                                          style: TextStyle(
                                            color: AppColors.welcomeLightYellow,
                                            fontFamily:
                                                AppFonts.sansProSemiBold,
                                            fontSize: 16.0,
                                            fontWeight: FontWeight.w400,
                                          ),
                                          minFontSize: 10,
                                          maxLines: 1,
                                        ),
                                  );
                                  }
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => CompanyPopup(company: job.company, onClose: () {Navigator.of(context).pop();},),
                                  ),
                                );
                              },
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero, // Removes extra padding
                                minimumSize: const Size(0, 0),  // Prevents fixed height
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap, // Shrinks hitbox
                              ),
                              child: const Text(
                                'View Company',
                                style: TextStyle(
                                  decoration: TextDecoration.underline,
                                  color: Color.fromARGB(255, 149, 188, 220), // Or any color you want
                                  fontSize: 14,
                                ),
                              ),
                            )
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          // Bottom section with text
          Container(
            color: AppColors.calPolyGreen,
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(
                      bottom: 12.0, top: 8, left: 8, right: 8),
                  child: Container(
                    decoration: const BoxDecoration(
                      borderRadius: BorderRadius.zero,
                      color: Colors.white,
                    ),
                    child: Row(
                      children: [
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16.0),
                          child: Center(
                            child: Padding(
                              padding: EdgeInsets.symmetric(vertical: 12.0),
                              child: CircleAvatar(
                                radius: 20,
                                backgroundColor: Colors.grey,
                                child: Icon(
                                  Icons.person,
                                  size: 32,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Container(
                          width: 2,
                          height: 64,
                          color: AppColors.calPolyGreen,
                        ),
                        Padding(
                          padding: const EdgeInsets.only(left: 16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              AutoSizeText(
                                job.contactName,
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontSize: 18.0,
                                  fontWeight: FontWeight.w600,
                                ),
                                minFontSize: 14,
                                maxLines: 1,
                              ),
                              AutoSizeText(
                                job.contactTitle,
                                style: const TextStyle(
                                  color: AppColors.darkGoldText,
                                  fontSize: 14.0,
                                  fontWeight: FontWeight.w400,
                                ),
                                minFontSize: 8,
                                maxLines: 1,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.mail,
                          size: 24, // Adjust the size of the icon as needed
                          color: Colors.white, // Add your desired icon color
                        ),
                        const SizedBox(
                          width: 10,
                        ), // Add space between icon and text
                        Text(
                          job.contactEmail ?? 'No Email',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18.0,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.phone,
                          size: 24, // Adjust the size of the icon as needed
                          color: Colors.white, // Add your desired icon color
                        ),
                        const SizedBox(
                          width: 10,
                        ), // Add space between icon and text
                        Text(
                          job.contactPhone ?? 'No Phone Number',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18.0,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                // Second Section (About)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        "Description",
                        style: TextStyle(
                          color: AppColors.lightGold,
                          fontSize: 22.0,
                          fontWeight: FontWeight.w400,
                          fontFamily: AppFonts.sansProSemiBold,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        job.description,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16.0,
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(
                  color: Colors.white,
                  thickness: 1.1,
                ),
                // Third Section (Message)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Company Message",
                        style: TextStyle(
                          color: AppColors.lightGold,
                          fontSize: 22.0,
                          fontWeight: FontWeight.w400,
                          fontFamily: AppFonts.sansProSemiBold,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        job.company.msg,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16.0,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}