import 'package:ccce_application/common/collections/calevent.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Event type for admin-created interview blocks (replaces Microsoft Bookings).
const String kInterviewBlockEventType = 'interviewBlock';

/// Graduation terms offered on the sign-up form (semester system).
const List<String> kGradTerms = ['Fall', 'Spring', 'Summer'];

/// Students can cancel until this long before their slot (enforced server-side too).
const Duration kStudentCancelCutoff = Duration(hours: 2);

const List<int> kSlotLengthOptions = [15, 20, 30, 45, 60];

DateTime? _toDate(dynamic v) => v is Timestamp ? v.toDate() : null;

/// Interview-specific fields stored on an `events/{id}` doc with
/// eventType == [kInterviewBlockEventType].
class InterviewBlockData {
  final int slotMinutes;
  final int interviewersPerSlot;
  final bool signupsOpen;
  final DateTime? signupDeadline;
  final String? linkedInfoSessionId;

  const InterviewBlockData({
    required this.slotMinutes,
    required this.interviewersPerSlot,
    required this.signupsOpen,
    this.signupDeadline,
    this.linkedInfoSessionId,
  });

  factory InterviewBlockData.fromMap(Map<String, dynamic> data) {
    final slot = data['slotMinutes'];
    final cap = data['interviewersPerSlot'];
    return InterviewBlockData(
      slotMinutes: slot is int && slot > 0 ? slot : 30,
      interviewersPerSlot: cap is int && cap > 0 ? cap : 1,
      signupsOpen: data['signupsOpen'] != false,
      signupDeadline: _toDate(data['signupDeadline']),
      linkedInfoSessionId: data['linkedInfoSessionId'] as String?,
    );
  }

  bool acceptingSignups(DateTime now) =>
      signupsOpen && (signupDeadline == null || now.isBefore(signupDeadline!));
}

/// Start times of every full slot in [start, end). Must match the grid the
/// signUpForInterview Cloud Function validates against.
List<DateTime> generateSlotStarts(
    DateTime start, DateTime end, int slotMinutes) {
  if (slotMinutes <= 0 || !end.isAfter(start)) return const [];
  final slot = Duration(minutes: slotMinutes);
  final slots = <DateTime>[];
  for (var t = start; !t.add(slot).isAfter(end); t = t.add(slot)) {
    slots.add(t);
  }
  return slots;
}

String _normalizeName(String s) =>
    s.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');

/// Upcoming interview blocks for the company that hosted [infoSession],
/// soonest first. Blocks explicitly linked to this session come first.
List<CalEvent> upcomingInterviewBlocksFor(
    CalEvent infoSession, List<CalEvent> events, DateTime now) {
  final sessionCompanyId = infoSession.companyId;
  final sessionName = _normalizeName(infoSession.eventName);
  final blocks = events.where((e) {
    if (e.eventType != kInterviewBlockEventType || !e.endTime.isAfter(now)) {
      return false;
    }
    if (e.ibd?.linkedInfoSessionId == infoSession.id) return true;
    if (sessionCompanyId != null &&
        sessionCompanyId.isNotEmpty &&
        e.companyId == sessionCompanyId) {
      return true;
    }
    return sessionName.isNotEmpty &&
        _normalizeName(e.companyName ?? '') == sessionName;
  }).toList();

  blocks.sort((a, b) {
    final aLinked = a.ibd?.linkedInfoSessionId == infoSession.id ? 0 : 1;
    final bLinked = b.ibd?.linkedInfoSessionId == infoSession.id ? 0 : 1;
    if (aLinked != bLinked) return aLinked - bLinked;
    return a.startTime.compareTo(b.startTime);
  });
  return blocks;
}

/// Client-side check mirroring the server's US phone validation.
String? validateUsPhone(String? value) {
  var digits = (value ?? '').replaceAll(RegExp(r'\D'), '');
  if (digits.length == 11 && digits.startsWith('1')) digits = digits.substring(1);
  if (digits.length != 10) return 'Enter a 10-digit US phone number';
  return null;
}

String? validateEmail(String? value) {
  final email = (value ?? '').trim();
  if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email)) {
    return 'Enter a valid email';
  }
  return null;
}

/// One student's sign-up, from `events/{blockId}/interviewSignups/{uid}`.
class InterviewSignup {
  final String uid;
  final String fullName;
  final String major;
  final String minor;
  final String gradTerm;
  final int gradYear;
  final String localPhone;
  final String email;
  final DateTime slotStart;
  final DateTime? slotEnd;

  const InterviewSignup({
    required this.uid,
    required this.fullName,
    required this.major,
    required this.minor,
    required this.gradTerm,
    required this.gradYear,
    required this.localPhone,
    required this.email,
    required this.slotStart,
    this.slotEnd,
  });

  factory InterviewSignup.fromMap(String uid, Map<String, dynamic> data) {
    return InterviewSignup(
      uid: uid,
      fullName: (data['fullName'] ?? '').toString(),
      major: (data['major'] ?? '').toString(),
      minor: (data['minor'] ?? '').toString(),
      gradTerm: (data['gradTerm'] ?? '').toString(),
      gradYear: data['gradYear'] is int ? data['gradYear'] as int : 0,
      localPhone: (data['localPhone'] ?? '').toString(),
      email: (data['email'] ?? '').toString(),
      slotStart: _toDate(data['slotStart']) ?? DateTime.fromMillisecondsSinceEpoch(0),
      slotEnd: _toDate(data['slotEnd']),
    );
  }

  factory InterviewSignup.fromSnapshot(DocumentSnapshot doc) =>
      InterviewSignup.fromMap(doc.id, (doc.data() as Map<String, dynamic>?) ?? {});

  String get graduation => '$gradTerm $gradYear';
}

/// A student's own copy of a sign-up, from `users/{uid}/interviewSignups/{blockId}`.
class MyInterview {
  final String blockId;
  final String company;
  final String location;
  final DateTime slotStart;
  final DateTime? slotEnd;

  const MyInterview({
    required this.blockId,
    required this.company,
    required this.location,
    required this.slotStart,
    this.slotEnd,
  });

  factory MyInterview.fromSnapshot(DocumentSnapshot doc) {
    final data = (doc.data() as Map<String, dynamic>?) ?? {};
    return MyInterview(
      blockId: doc.id,
      company: (data['company'] ?? '').toString(),
      location: (data['location'] ?? '').toString(),
      slotStart: _toDate(data['slotStart']) ?? DateTime.fromMillisecondsSinceEpoch(0),
      slotEnd: _toDate(data['slotEnd']),
    );
  }
}

String _csvCell(String value) {
  if (value.contains(RegExp(r'[",\n\r]'))) {
    return '"${value.replaceAll('"', '""')}"';
  }
  return value;
}

/// Roster as CSV (sorted by slot) for sharing with recruiters.
String interviewSignupsToCsv(
    List<InterviewSignup> signups, String Function(DateTime) formatTime) {
  final sorted = [...signups]..sort((a, b) => a.slotStart.compareTo(b.slotStart));
  final rows = <List<String>>[
    ['Time', 'Full Name', 'Major', 'Minor', 'Graduation', 'Local Phone', 'Email'],
    ...sorted.map((s) => [
          formatTime(s.slotStart),
          s.fullName,
          s.major,
          s.minor,
          s.graduation,
          s.localPhone,
          s.email,
        ]),
  ];
  return rows.map((r) => r.map(_csvCell).join(',')).join('\n');
}
