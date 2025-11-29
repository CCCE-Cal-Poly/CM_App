import 'package:flutter_test/flutter_test.dart';
import 'package:ccce_application/common/collections/user_data.dart';

void main() {
  group('UserData', () {
    test('creates UserData with required fields', () {
      final userData = UserData(
        uid: 'test123',
        name: 'John Doe',
        email: 'john@calpoly.edu',
        clubsAdminOf: [],
        role: UserRole.student,
      );

      expect(userData.uid, 'test123');
      expect(userData.name, 'John Doe');
      expect(userData.email, 'john@calpoly.edu');
      expect(userData.role, UserRole.student);
      expect(userData.clubsAdminOf, isEmpty);
    });

    test('isClubAdmin returns true when club is in list', () {
      final userData = UserData(
        uid: 'test123',
        name: 'John Doe',
        email: 'john@calpoly.edu',
        clubsAdminOf: ['club1', 'club2'],
        role: UserRole.clubAdmin,
      );

      expect(userData.isClubAdmin('club1'), isTrue);
      expect(userData.isClubAdmin('club2'), isTrue);
      expect(userData.isClubAdmin('club3'), isFalse);
    });

    test('isClubAdmin returns false for empty list', () {
      final userData = UserData(
        uid: 'test123',
        name: 'John Doe',
        email: 'john@calpoly.edu',
        clubsAdminOf: [],
        role: UserRole.student,
      );

      expect(userData.isClubAdmin('anyClub'), isFalse);
    });
  });

  group('UserRole', () {
    test('enumToString returns correct strings', () {
      expect(UserRole.admin.enumToString(), 'Admin');
      expect(UserRole.clubAdmin.enumToString(), 'Club Admin');
      expect(UserRole.student.enumToString(), 'Student');
      expect(UserRole.faculty.enumToString(), 'Faculty');
    });

    test('all enum values have string representation', () {
      for (final role in UserRole.values) {
        expect(role.enumToString(), isNotEmpty);
      }
    });
  });
}
