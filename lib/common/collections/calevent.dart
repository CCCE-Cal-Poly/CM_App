import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

enum EventType { infoSession, club }

class CalEvent {
  String id;
  EventType eventType;
  String eventName;
  DateTime startTime;
  DateTime endTime;
  String eventLocation;

  InfoSessionData? isd;

  CalEvent(
      {required this.id,
      required this.eventType,
      required this.eventName,
      required this.startTime,
      required this.endTime,
      required this.eventLocation,
      this.isd});

  @override
  String toString() {
    return eventName;
  }

  factory CalEvent.fromSnapshot(DocumentSnapshot doc) {
    EventType eventType = EventType.values.firstWhere(
      (e) => e.toString().split('.').last == doc.get("eventType"),
      orElse: () => EventType.infoSession,
    );
    InfoSessionData? isd = null;
    String eventName = "";

    switch (eventType) {
      case EventType.infoSession:
        eventName = doc.get("company") + " - Info Session";
        String openPositions =
            doc.get("isHiring") == "No" ? "" : doc.get("position");
        isd = InfoSessionData(
            doc.get("company"),
            doc.get("website"),
            doc.get("interviewLocation"),
            doc.get("contactName"),
            doc.get("contactEmail"),
            openPositions,
            doc.get("jobLocations"),
            doc.get("interviewLink"));
        break;
      case EventType.club:
        eventName = '${doc.get("hostAcronym")} - ${doc.get("title")}';

        break;
    }

    DateTime startTime = doc.get("startTime").toDate();

    // Extract data from the snapshot
    return CalEvent(
        id: doc.id,
        eventType: eventType,
        eventName: eventName,
        startTime: startTime,
        endTime: startTime.add(const Duration(hours: 1)),
        eventLocation: doc.get("mainLocation"),
        isd: isd);
  }
}

class InfoSessionData {
  String? companyName = "";
  String? website = "";
  String? interviewLocation = "";
  String? recruiterName = "";
  String? recruiterEmail = "";
  String? openPositions = "";
  String? jobLocations = "";
  String? interviewLink = "";

  InfoSessionData(
      this.companyName,
      this.website,
      this.interviewLocation,
      this.recruiterName,
      this.recruiterEmail,
      this.openPositions,
      this.jobLocations,
      this.interviewLink);
}
