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
      fit: BoxFit.cover,
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
  String? status;
  InfoSessionData? isd;

  CalEvent({
    required this.id,
    required this.eventName,
    required this.startTime,
    required this.endTime,
    required this.eventLocation,
    required this.eventType,
    this.logo,
    this.status,
    this.isd,
  });

  @override
  String toString() {
    return eventName;
  }

  factory CalEvent.fromSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    String openPositions = data["isHiring"] == "No" ? "" : data["position"];
    String? theLogo = data.containsKey("logo") ? data["logo"] : null;
    return CalEvent(
      id: doc.id,
      eventName: data["company"],
      startTime: data["startTime"].toDate(),
      endTime: data["startTime"].toDate().add(const Duration(hours: 1)),
      eventLocation: data["mainLocation"],
      eventType: data["eventType"],
      logo: theLogo,
      status: data["Status"] ?? "pending",
      isd: InfoSessionData(
        data["website"],
        data["interviewLocation"],
        data["contactName"],
        data["contactEmail"],
        openPositions,
        data["jobLocations"],
        data["interviewLink"],
      ),
    );
  }

  factory CalEvent.clubEventfromMap(Map<String, dynamic> data) {
    return CalEvent(
      id: data['id'] ?? '',
      eventName: data['eventName'] ?? '',
      startTime: (data['startTime']).toDate(),
      endTime: (data['endTime']).toDate(),
      eventLocation: data['eventLocation'] ?? '',
      eventType: data['eventType'] ?? '',
      logo: data['Logo'],
      status: data['Status'] ?? 'pending',
    );
  }

  factory CalEvent.infoSessionfromMap(Map<String, dynamic> data) {
    return CalEvent(
      id: data['id'] ?? '',
      eventName: data['eventName'] ?? '',
      startTime: (data['startTime']).toDate(),
      endTime: (data['endTime']).toDate(),
      eventLocation: data['eventLocation'] ?? '',
      eventType: data['eventType'] ?? '',
      logo: data['Logo'],
      status: data['Status'] ?? 'approved',
      isd: InfoSessionData(
        data["website"],
        data["interviewLocation"],
        data["recruiterName"],
        data["recruiterEmail"],
        data["openPositions"],
        data["jobLocations"],
        data["interviewLink"],
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'eventName': eventName,
      'startTime': startTime,
      'endTime': endTime,
      'eventLocation': eventLocation,
      'eventType': eventType,
      'logo': logo,
      'status': status,
      'isd': isd != null
          ? {
              'website': isd!.website,
              'interviewLocation': isd!.interviewLocation,
              'recruiterName': isd!.recruiterName,
              'recruiterEmail': isd!.recruiterEmail,
              'openPositions': isd!.openPositions,
              'jobLocations': isd!.jobLocations,
              'interviewLink': isd!.interviewLink,
            }
          : null,
    };
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
    this.interviewLink,
  );
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
                alpha: 0.2,
              ),
              spreadRadius: 1,
              blurRadius: 2,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(
            vertical: screenHeight * .005,
            horizontal: screenWidth * 0.01,
          ),
          child: Column(
            children: [
              ListTile(
                leading: eventLogoImage(
                  infoSession.logo,
                  screenWidth * .1,
                  screenWidth * .1,
                ),
                title: AutoSizeText(
                  infoSession.eventName ?? 'No Company Name',
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 13.0,
                    fontWeight: FontWeight.w600,
                  ),
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

  const InfoSessionPopUp({
    required this.infoSession,
    required this.onClose,
    Key? key,
  }) : super(key: key);

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
                      Padding(
                        padding: EdgeInsets.only(
                          left: screenWidth * .02,
                          top: screenHeight * .012,
                        ),
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
                      Padding(
                        padding: EdgeInsets.all(screenWidth * 0.015),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: screenHeight * 0.14,
                              height: screenHeight * 0.14,
                              child: eventLogoImage(
                                widget.infoSession.logo,
                                screenHeight * 0.1,
                                screenHeight * 0.1,
                              ),
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
                                widget.infoSession.eventName ?? 'No Company Name',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 19,
                                  fontWeight: FontWeight.bold,
                                ),
                                minFontSize: 16,
                                maxLines: 2,
                              ),
                            ),
                            SizedBox(height: screenHeight * .0015),
                            Padding(
                              padding: EdgeInsets.only(top: screenHeight * 0.015),
                              child: ElevatedButton(
                                onPressed: () {
                                  setState(() {
                                    if (context.read<AppState>().isCheckedIn(widget.infoSession)) {
                                      context.read<AppState>().checkOutOf(widget.infoSession);
                                    } else {
                                      context.read<AppState>().checkInto(widget.infoSession);
                                    }
                                  });
                                },
                                style: ElevatedButton.styleFrom(
                                  fixedSize: Size(
                                    screenWidth * 0.5,
                                    screenHeight * 0.05,
                                  ),
                                  backgroundColor: context.read<AppState>().isCheckedIn(widget.infoSession)
                                      ? Colors.grey
                                      : AppColors.calPolyGreen,
                                  shape: const RoundedRectangleBorder(
                                    borderRadius: BorderRadius.zero,
                                  ),
                                  padding: EdgeInsets.symmetric(
                                    horizontal: screenWidth * .03,
                                    vertical: screenHeight * .008,
                                  ),
                                ),
                                child: context.read<AppState>().isCheckedIn(widget.infoSession)
                                    ? const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.check, color: Colors.black),
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
                                vertical: screenHeight * 0.01,
                              ),
                              child: ElevatedButton(
                                onPressed: () {
                                  setState(() {
                                    if (context.read<AppState>().isInCalendar(widget.infoSession)) {
                                      context.read<AppState>().removeFromCalendar(widget.infoSession);
                                    } else {
                                      context.read<AppState>().addToCalendar(widget.infoSession);
                                    }
                                  });
                                },
                                style: ElevatedButton.styleFrom(
                                  fixedSize: Size(
                                    screenWidth * 0.5,
                                    screenHeight * 0.05,
                                  ),
                                  backgroundColor: context.read<AppState>().isInCalendar(widget.infoSession)
                                      ? Colors.grey
                                      : AppColors.calPolyGreen,
                                  shape: const RoundedRectangleBorder(
                                    borderRadius: BorderRadius.zero,
                                  ),
                                  padding: EdgeInsets.symmetric(
                                    horizontal: screenWidth * .03,
                                    vertical: screenHeight * .008,
                                  ),
                                ),
                                child: context.read<AppState>().isInCalendar(widget.infoSession)
                                    ? const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.check, color: Colors.black),
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
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          Container(
            color: AppColors.calPolyGreen,
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                        horizontal: 16.0,
                        vertical: 6.0,
                      ),
                      child: Container(
                        width: screenWidth * .85,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: Colors.black),
                          borderRadius: BorderRadius.zero,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 2.0,
                            horizontal: 6.0,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.only(
                              left: 18.0,
                              top: 4.0,
                              bottom: 8.0,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.infoSession.isd?.recruiterName ?? 'No Listed Contact Name',
                                  style: const TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  widget.infoSession.isd?.recruiterEmail ?? 'No Listed Contact Email',
                                  style: const TextStyle(
                                    color: AppColors.darkGoldText,
                                    fontWeight: FontWeight.w400,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const Divider(),
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
                    const SizedBox(height: 5),
                    Text(
                      widget.infoSession.isd?.openPositions ?? 'No Position Info',
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