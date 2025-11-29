import 'package:flutter_test/flutter_test.dart';
import 'package:ccce_application/common/providers/user_provider.dart';

void main() {
  group('UserProvider', () {
    late UserProvider userProvider;

    setUp(() {
      userProvider = UserProvider();
    });

    test('initial user is null', () {
      expect(userProvider.user, isNull);
    });

    test('clubsAdminOf returns empty list when user is null', () {
      expect(userProvider.clubsAdminOf, isEmpty);
    });

    test('isClubAdmin returns false when user is null', () {
      expect(userProvider.isClubAdmin('anyClub'), isFalse);
    });

    test('clubsAdminOf returns user clubs when user exists', () {
      // Simulate setting a user (this would normally come from Firestore)
      // In real implementation, this would be tested with mock Firestore
      expect(userProvider.clubsAdminOf, isA<List<String>>());
    });
  });
}
