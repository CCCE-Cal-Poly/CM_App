import 'package:cloud_firestore/cloud_firestore.dart';

class ConferenceSession {
  final String id;
  final int sessionNumber;
  final String title;
  final DateTime startTime;
  final DateTime endTime;
  final String location;
  final List<String> moderators;
  final String presentationStatus;
  final String paperStatus;
  final String? notes;
  final String? presentationStoragePath;
  final String? paperStoragePath;
  final String? presentationUrl;
  final String? paperUrl;
  final DateTime? updatedAt;

  const ConferenceSession({
    required this.id,
    required this.sessionNumber,
    required this.title,
    required this.startTime,
    required this.endTime,
    required this.location,
    required this.moderators,
    required this.presentationStatus,
    required this.paperStatus,
    this.notes,
    this.presentationStoragePath,
    this.paperStoragePath,
    this.presentationUrl,
    this.paperUrl,
    this.updatedAt,
  });

  bool get hasPresentationAsset {
    return presentationStatus.toLowerCase() == 'uploaded' &&
        ((presentationStoragePath != null &&
                presentationStoragePath!.isNotEmpty) ||
            (presentationUrl != null && presentationUrl!.isNotEmpty));
  }

  bool get hasPaperAsset {
    return paperStatus.toLowerCase() == 'uploaded' &&
        ((paperStoragePath != null && paperStoragePath!.isNotEmpty) ||
            (paperUrl != null && paperUrl!.isNotEmpty));
  }

  bool get isPresentationMissing {
    final status = presentationStatus.toLowerCase();
    return status == 'missing' ||
        status == 'pending_author' ||
        status == 'not_attending';
  }

  factory ConferenceSession.fromSnapshot(DocumentSnapshot doc) {
    final raw = doc.data();
    if (raw == null) {
      throw Exception('Conference session ${doc.id} has no data');
    }

    final data = raw as Map<String, dynamic>;

    int parseSessionNumber(dynamic value) {
      if (value is int) {
        return value;
      }
      if (value is String) {
        return int.tryParse(value) ?? 0;
      }
      return 0;
    }

    DateTime parseTime(dynamic value) {
      if (value is Timestamp) {
        return value.toDate();
      }
      return DateTime.now();
    }

    List<String> parseModerators(dynamic value) {
      if (value is List) {
        return value
            .map((e) => e.toString())
            .where((e) => e.isNotEmpty)
            .toList();
      }
      if (value is String && value.trim().isNotEmpty) {
        return value
            .split(',')
            .map((name) => name.trim())
            .where((name) => name.isNotEmpty)
            .toList();
      }
      return const [];
    }

    return ConferenceSession(
      id: doc.id,
      sessionNumber: parseSessionNumber(data['sessionNumber']),
      title: (data['title'] ?? data['eventName'] ?? '').toString(),
      startTime: parseTime(data['startTime']),
      endTime: parseTime(data['endTime']),
      location: (data['location'] ?? '').toString(),
      moderators: parseModerators(data['moderators']),
      presentationStatus: (data['presentationStatus'] ?? 'missing').toString(),
      paperStatus: (data['paperStatus'] ?? 'missing').toString(),
      notes: data['notes']?.toString(),
      presentationStoragePath: data['presentationStoragePath']?.toString(),
      paperStoragePath: data['paperStoragePath']?.toString(),
      presentationUrl: data['presentationUrl']?.toString(),
      paperUrl: data['paperUrl']?.toString(),
      updatedAt: data['updatedAt'] is Timestamp
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
    );
  }
}
