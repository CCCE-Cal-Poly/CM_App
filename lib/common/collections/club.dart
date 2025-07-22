import 'package:auto_size_text/auto_size_text.dart';
import 'package:ccce_application/common/theme/theme.dart';
import 'package:ccce_application/main.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class Club implements Comparable<Club> {
  dynamic name;
  dynamic aboutMsg;
  dynamic email;
  dynamic acronym;
  dynamic instagram;
  String? logo;
  Club(this.name, this.aboutMsg, this.email, this.acronym, this.instagram, this.logo);

  @override
  int compareTo(Club other) {
    return (name.toLowerCase().compareTo(other.name.toLowerCase()));
  }
}

class ClubItem extends StatelessWidget {
  /// Returns a widget that displays the club logo image.
  /// If the URL is null or empty, it returns a broken image icon.
  Widget clubLogoImage(String? url, double width, double height) {
  if (url == null || url.isEmpty) {
    return Icon(Icons.broken_image, size: height, color: Colors.grey);
  }
  return ClipOval(
    child: Image.network(
      url,
      width: width,
      height: height,
      fit: BoxFit.cover, // Ensures the image fills the circle
    ),
  );
}

  final Club club;

  const ClubItem(this.club, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;
    double screenWidth = MediaQuery.of(context).size.width;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.transparent),
          borderRadius: BorderRadius.zero,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(
                alpha: 0.2, // Adjust the alpha value for shadow intensity
              ),
              spreadRadius: 1,
              blurRadius: 2,
              offset: const Offset(0, 2), // changes position of shadow
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: screenHeight * .005, horizontal: screenWidth * 0.01),
          child: Column(
            children: [
              ListTile(
                leading: clubLogoImage(club.logo, screenWidth * .1, screenWidth * .1),
                title: AutoSizeText(club.name + " (" + club.acronym + ")",
                    style: const TextStyle(color: Colors.black, fontSize: 13.0, fontWeight: FontWeight.w600),
                    minFontSize: 11,
                    maxLines: 2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ClubPopUp extends StatefulWidget {
  final Club club;

  final VoidCallback onClose;

  const ClubPopUp({required this.club, required this.onClose, Key? key})
      : super(key: key);

  @override
  _ClubPopUpState createState() => _ClubPopUpState();
}
  

  Widget clubLogoImage(String? url, double width, double height) {
  if (url == null || url.isEmpty) {
    return Icon(Icons.broken_image, size: height, color: Colors.grey);
  }
  return ClipOval(
    child: Image.network(
      url,
      width: width,
      height: height,
      fit: BoxFit.cover, // Ensures the image fills the circle
    ),
  );
}
class _ClubPopUpState extends State<ClubPopUp> {

  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;
    double screenWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      backgroundColor: AppColors.calPolyGreen,
      body: ListView(
        children: [
          Stack(
            // Use Stack within Column for content positioning
            children: [
              Center(
                child: Container(
                  // Container for popup content
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.zero
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Close button with arrow
                      Padding(
                        padding: EdgeInsets.only(left: screenWidth * .02, top: screenHeight * .012),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            SizedBox(
                              height: screenHeight * .03,
                              child: IconButton(
                                icon: const Icon(
                                  Icons.arrow_back,
                                  color: Colors.black,
                                ),
                                onPressed: widget.onClose,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Circle near the top of the page in the middle
                      Padding(
                        padding: EdgeInsets.all(screenWidth * 0.015),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: screenHeight * 0.14,
                              height: screenHeight * 0.14,
                              child:  clubLogoImage(widget.club.logo, screenHeight * 0.1, screenHeight * 0.1),
                            ),
                          ],
                        ),
                      ),
                      // Your existing club details here
                      Padding(
                        padding: EdgeInsets.all(screenHeight * 0.015),
                        child: Column(
                          children: [
                            SizedBox(
                              width: screenWidth * 0.7,
                              child: AutoSizeText(
                                widget.club.name,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize:
                                      19, // Adjust the font size as needed
                                  fontWeight:
                                      FontWeight.bold, // Make the text bold
                                ),
                                minFontSize: 16,
                                maxLines: 2,
                              ),
                            ),
                            Text(
                              "(" + widget.club.acronym + ")",
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize:
                                    15.0, // Adjust the font size as needed
                              ),
                            ),
                            SizedBox(height: screenHeight * .0015),
                            Padding(
                              padding: EdgeInsets.symmetric(vertical: screenHeight * 0.015),
                              child: ElevatedButton(
                                onPressed: () {
                                  setState(() {
                                    if (context.read<AppState>().isJoined(widget.club)) {
                                    context.read<AppState>().removeJoinedClub(widget.club);
                                    } else {
                                    context.read<AppState>().addJoinedClub(widget.club);
                                    }
                                  });
                                },
                                style: ElevatedButton.styleFrom(
                                  fixedSize: Size(screenWidth * 0.5, screenHeight * 0.05),
                                  backgroundColor: context.read<AppState>().isJoined(widget.club)
                                    ?Colors.grey
                                    : AppColors.calPolyGreen,
                                  shape: const RoundedRectangleBorder(
                                    borderRadius: BorderRadius.zero, // Sharp corners
                                  ),
                                  padding: EdgeInsets.symmetric(horizontal: screenWidth*.03, vertical: screenHeight * .008),
                                ),
                                child: context.read<AppState>().isJoined(widget.club)
                                    ? const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.check, color: Colors.black),
                                          SizedBox(width: 6),
                                          Text(
                                            'JOINED',
                                            style: TextStyle(
                                              color: Colors.black,
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      )
                                    : const Text(
                                        'JOIN CLUB',
                                        style: TextStyle(
                                          color: AppColors.welcomeLightYellow,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                              ),
                            ),
                            // ... additional content
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
                // First Section
                // Second Section (Upcoming Events)
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Upcoming Events",
                      style: TextStyle(
                        color: AppColors.lightGold,
                        fontSize: 22.0,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    SizedBox(
                      height: 5,
                    ), // Add space between text elements
                    Text(
                      "This is a Placeholder.",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16.0,
                      ),
                    ),
                  ],
                ),
                // Divider between the second and third sections
                const Divider(),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
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
                              widget.club.email ?? 'No Email',
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
                    Container(
                      height: 24,
                      width: 24,
                      decoration: BoxDecoration( 
                        borderRadius: BorderRadius.circular(6.0),
                        color: Colors.transparent, 
                        border: Border.all(
                          color: Colors.white
                        ),
                      ),
                      child: const Icon(
                        Icons.camera_alt,
                        size: 16,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(
                      width: 10,
                    ), // Add space between icon and text
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          (widget.club.instagram!=null) ? '@' + widget.club.instagram : 'No Instagram',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18.0,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                ],
                ),
                // Third Section (About)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "About",
                      style: TextStyle(
                        color: AppColors.lightGold,
                        fontSize: 22.0,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(
                      height: 5,
                    ), // Add space between text elements
                    Text(
                      widget.club.aboutMsg,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14.0,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
