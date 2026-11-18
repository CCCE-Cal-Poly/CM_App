import 'package:ccce_application/common/collections/calevent.dart';
import 'package:ccce_application/common/collections/interview.dart';
import 'package:flutter_test/flutter_test.dart';

CalEvent _block(String id,
    {required DateTime start,
    String? companyId,
    String? company,
    String? linkedInfoSessionId}) {
  return CalEvent(
    id: id,
    eventName: '${company ?? ''} Interviews',
    startTime: start,
    endTime: start.add(const Duration(hours: 2)),
    eventLocation: 'Bldg 186',
    eventType: kInterviewBlockEventType,
    companyId: companyId,
    companyName: company,
    ibd: InterviewBlockData(
      slotMinutes: 30,
      interviewersPerSlot: 1,
      signupsOpen: true,
      linkedInfoSessionId: linkedInfoSessionId,
    ),
  );
}

void main() {
  group('generateSlotStarts', () {
    test('splits a block into full slots only', () {
      final start = DateTime(2026, 11, 12, 9);
      final slots = generateSlotStarts(
          start, start.add(const Duration(minutes: 100)), 30);
      expect(slots, [
        start,
        start.add(const Duration(minutes: 30)),
        start.add(const Duration(minutes: 60)),
      ]);
    });

    test('returns nothing for empty or invalid blocks', () {
      final start = DateTime(2026, 11, 12, 9);
      expect(generateSlotStarts(start, start, 30), isEmpty);
      expect(
          generateSlotStarts(
              start, start.add(const Duration(minutes: 20)), 30),
          isEmpty);
      expect(generateSlotStarts(start, start.add(const Duration(hours: 1)), 0),
          isEmpty);
    });
  });

  group('InterviewBlockData', () {
    test('defaults and deadline handling', () {
      final data = InterviewBlockData.fromMap({});
      expect(data.slotMinutes, 30);
      expect(data.interviewersPerSlot, 1);
      expect(data.signupsOpen, isTrue);
      expect(data.acceptingSignups(DateTime(2026)), isTrue);

      final deadline = DateTime(2026, 11, 11, 17);
      final closed = InterviewBlockData(
          slotMinutes: 30,
          interviewersPerSlot: 1,
          signupsOpen: true,
          signupDeadline: deadline);
      expect(closed.acceptingSignups(deadline.subtract(const Duration(minutes: 1))),
          isTrue);
      expect(closed.acceptingSignups(deadline.add(const Duration(minutes: 1))),
          isFalse);
    });
  });

  group('upcomingInterviewBlocksFor', () {
    final now = DateTime(2026, 11, 10, 12);
    final session = CalEvent(
      id: 'session1',
      eventName: 'Dome Construction',
      startTime: DateTime(2026, 11, 11, 18),
      endTime: DateTime(2026, 11, 11, 19),
      eventLocation: '',
      eventType: 'infoSession',
      companyId: 'dome',
    );

    test('matches by companyId, linked session, or name; skips past blocks', () {
      final byId = _block('a',
          start: DateTime(2026, 11, 13, 9), companyId: 'dome', company: 'Dome Construction');
      final linked = _block('b',
          start: DateTime(2026, 11, 14, 9),
          companyId: 'other',
          company: 'Other',
          linkedInfoSessionId: 'session1');
      final byName = _block('c',
          start: DateTime(2026, 11, 12, 9), company: 'Dome Construction');
      final past = _block('d',
          start: DateTime(2026, 11, 1, 9), companyId: 'dome', company: 'Dome Construction');
      final unrelated = _block('e',
          start: DateTime(2026, 11, 12, 9), companyId: 'kiewit', company: 'Kiewit');

      final result = upcomingInterviewBlocksFor(
          session, [byId, linked, byName, past, unrelated, session], now);

      expect(result.map((e) => e.id), ['b', 'c', 'a']); // linked first, then soonest
    });
  });

  group('validation', () {
    test('phone', () {
      expect(validateUsPhone('(805) 555-1234'), isNull);
      expect(validateUsPhone('+1 805 555 1234'), isNull);
      expect(validateUsPhone('555-1234'), isNotNull);
      expect(validateUsPhone(null), isNotNull);
    });

    test('email', () {
      expect(validateEmail('pat@calpoly.edu'), isNull);
      expect(validateEmail('pat@'), isNotNull);
    });
  });

  test('interviewSignupsToCsv sorts by slot and escapes cells', () {
    final early = InterviewSignup(
      uid: 'u1',
      fullName: 'Pat "PJ" Mustang',
      major: 'Construction Management',
      minor: '',
      gradTerm: 'Spring',
      gradYear: 2027,
      localPhone: '(805) 555-1234',
      email: 'pat@calpoly.edu',
      slotStart: DateTime(2026, 11, 12, 9),
    );
    final late = InterviewSignup(
      uid: 'u2',
      fullName: 'Sam Lee',
      major: 'CM',
      minor: 'Business, Law',
      gradTerm: 'Fall',
      gradYear: 2026,
      localPhone: '(805) 555-0000',
      email: 'sam@calpoly.edu',
      slotStart: DateTime(2026, 11, 12, 9, 30),
    );
    final csv = interviewSignupsToCsv([late, early], (t) => '${t.hour}:${t.minute}');
    final lines = csv.split('\n');
    expect(lines.first,
        'Time,Full Name,Major,Minor,Graduation,Local Phone,Email');
    expect(lines[1],
        '9:0,"Pat ""PJ"" Mustang",Construction Management,,Spring 2027,(805) 555-1234,pat@calpoly.edu');
    expect(lines[2], startsWith('9:30,Sam Lee,CM,"Business, Law",Fall 2026'));
  });
}
