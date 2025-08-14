import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:ccce_application/common/theme/theme.dart';
import 'package:ccce_application/common/providers/app_state.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

Widget eventLogoImage(String? url, double width, double height) {
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

class CalEvent {
  String id;
  String eventName;
  DateTime startTime;
  DateTime endTime;
  String eventLocation;
  String eventType;
  String? logo;
  InfoSessionData? isd;

  CalEvent(
      {required this.id,
      required this.eventName,
      required this.startTime,
      required this.endTime,
      required this.eventLocation,
      required this.eventType,
      this.logo,
      this.isd});

  @override
  String toString() {
    return eventName;
  }

  factory CalEvent.fromSnapshot(DocumentSnapshot doc) {
    String eventName = doc.get("company");
    String openPositions =
        doc.get("isHiring") == "No" ? "" : doc.get("position");
    DateTime startTime = doc.get("startTime").toDate();

    // Extract data from the snapshot
    return CalEvent(
        id: doc.id,
        eventName: eventName,
        startTime: startTime,
        endTime: startTime.add(const Duration(hours: 1)),
        eventLocation: doc.get("mainLocation"),
        eventType: doc.get("eventType"),
        logo: doc.get("logo"),
        isd: InfoSessionData(
            doc.get("website"),
            doc.get("interviewLocation"),
            doc.get("contactName"),
            doc.get("contactEmail"),
            openPositions,
            doc.get("jobLocations"),
            doc.get("interviewLink")));
  }
}

class InfoSessionData {
  String? website = "";
  String? interviewLocation = "";
  String? recruiterName = "";
  String? recruiterEmail = "";
  String? openPositions = "";
  String? jobLocations = "";
  String? interviewLink = "";

  InfoSessionData(
      this.website,
      this.interviewLocation,
      this.recruiterName,
      this.recruiterEmail,
      this.openPositions,
      this.jobLocations,
      this.interviewLink);
}

class InfoSessionItem extends StatelessWidget {
  final CalEvent infoSession;

  const InfoSessionItem(this.infoSession, {Key? key}) : super(key: key);

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
          padding: EdgeInsets.symmetric(
              vertical: screenHeight * .005, horizontal: screenWidth * 0.01),
          child: Column(
            children: [
              ListTile(
                leading: eventLogoImage(
                    infoSession.logo, screenWidth * .1, screenWidth * .1),
                title: AutoSizeText(
                  infoSession.eventName ?? 'No Company Name',
                  style: const TextStyle(
                      color: Colors.black,
                      fontSize: 13.0,
                      fontWeight: FontWeight.w600),
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

class InfoSessionPopUp extends StatefulWidget {
  final CalEvent infoSession;

  final VoidCallback onClose;

  const InfoSessionPopUp(
      {required this.infoSession, required this.onClose, Key? key})
      : super(key: key);

  @override
  _InfoSessionPopUpState createState() => _InfoSessionPopUpState();
}

class _InfoSessionPopUpState extends State<InfoSessionPopUp> {
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
                      color: Colors.white, borderRadius: BorderRadius.zero),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Close button with arrow
                      Padding(
                        padding: EdgeInsets.only(
                            left: screenWidth * .02, top: screenHeight * .012),
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
                              child: eventLogoImage(widget.infoSession.logo,
                                  screenHeight * 0.1, screenHeight * 0.1),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.all(screenHeight * 0.015),
                        child: Column(
                          children: [
                            SizedBox(
                              width: screenWidth * 0.7,
                              child: AutoSizeText(
                                widget.infoSession.eventName ??
                                    'No Company Name',
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
                            SizedBox(height: screenHeight * .0015),
                            Padding(
                              padding:
                                  EdgeInsets.only(top: screenHeight * 0.015),
                              child: ElevatedButton(
                                onPressed: () {
                                  setState(() {
                                    if (context
                                        .read<AppState>()
                                        .isCheckedIn(widget.infoSession)) {
                                      context
                                          .read<AppState>()
                                          .checkOutOf(widget.infoSession);
                                    } else {
                                      context
                                          .read<AppState>()
                                          .checkInto(widget.infoSession);
                                    }
                                  });
                                },
                                style: ElevatedButton.styleFrom(
                                  fixedSize: Size(
                                      screenWidth * 0.5, screenHeight * 0.05),
                                  backgroundColor: context
                                          .read<AppState>()
                                          .isCheckedIn(widget.infoSession)
                                      ? Colors.grey
                                      : AppColors.calPolyGreen,
                                  shape: const RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.zero, // Sharp corners
                                  ),
                                  padding: EdgeInsets.symmetric(
                                      horizontal: screenWidth * .03,
                                      vertical: screenHeight * .008),
                                ),
                                child: context
                                        .read<AppState>()
                                        .isCheckedIn(widget.infoSession)
                                    ? const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.check,
                                              color: Colors.black),
                                          SizedBox(width: 6),
                                          Text(
                                            'CHECKED IN',
                                            style: TextStyle(
                                              color: Colors.black,
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      )
                                    : const Text(
                                        'CHECK IN',
                                        style: TextStyle(
                                          color: AppColors.welcomeLightYellow,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.symmetric(
                                  vertical: screenHeight * 0.01),
                              child: ElevatedButton(
                                onPressed: () {
                                  setState(() {
                                    if (context
                                        .read<AppState>()
                                        .isInCalendar(widget.infoSession)) {
                                      context
                                          .read<AppState>()
                                          .removeFromCalendar(
                                              widget.infoSession);
                                    } else {
                                      context
                                          .read<AppState>()
                                          .addToCalendar(widget.infoSession);
                                    }
                                  });
                                },
                                style: ElevatedButton.styleFrom(
                                  fixedSize: Size(
                                      screenWidth * 0.5, screenHeight * 0.05),
                                  backgroundColor: context
                                          .read<AppState>()
                                          .isInCalendar(widget.infoSession)
                                      ? Colors.grey
                                      : AppColors.calPolyGreen,
                                  shape: const RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.zero, // Sharp corners
                                  ),
                                  padding: EdgeInsets.symmetric(
                                      horizontal: screenWidth * .03,
                                      vertical: screenHeight * .008),
                                ),
                                child: context
                                        .read<AppState>()
                                        .isInCalendar(widget.infoSession)
                                    ? const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.check,
                                              color: Colors.black),
                                          SizedBox(width: 6),
                                          Text(
                                            'ADDED TO CALENDAR',
                                            style: TextStyle(
                                              color: Colors.black,
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      )
                                    : const Text(
                                        'ADD TO CALENDAR',
                                        style: TextStyle(
                                          color: AppColors.welcomeLightYellow,
                                          fontSize: 14,
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
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Contacts",
                      style: TextStyle(
                        color: AppColors.lightGold,
                        fontSize: 22.0,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16.0, vertical: 6.0),
                      child: Container(
                        width: screenWidth * .85,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: Colors.black),
                          borderRadius: BorderRadius.zero,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: 2.0, horizontal: 6.0),
                          child: Padding(
                            padding: const EdgeInsets.only(
                                left: 18.0, top: 4.0, bottom: 8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.infoSession.isd?.recruiterName ??
                                      'No Listed Contact Name',
                                  style: const TextStyle(
                                      color: Colors.black,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14),
                                ),
                                Text(
                                    widget.infoSession.isd?.recruiterEmail ??
                                        'No Listed Contact Email',
                                    style: const TextStyle(
                                        color: AppColors.darkGoldText,
                                        fontWeight: FontWeight.w400,
                                        fontSize: 11)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    )
                  ],
                ),
                // Divider between the second and third sections
                const Divider(),
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
                    ),
                    Text(
                      widget.infoSession.isd?.openPositions ??
                          'No Position Info',
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
