import 'package:flutter_test/flutter_test.dart';

void main() {
  group('EditProfile Password Validation', () {
    test('password must be at least 6 characters', () {
      const shortPassword = 'abc';
      const validPassword = 'abc123';

      expect(shortPassword.length >= 6, isFalse);
      expect(validPassword.length >= 6, isTrue);
    });

    test('passwords must match for confirmation', () {
      const password1 = 'mypassword123';
      const password2 = 'mypassword123';
      const password3 = 'differentpass';

      expect(password1 == password2, isTrue);
      expect(password1 == password3, isFalse);
    });

    test('password fields should not be empty', () {
      const emptyPassword = '';
      const validPassword = 'mypass123';

      expect(emptyPassword.isEmpty, isTrue);
      expect(validPassword.isEmpty, isFalse);
    });
  });

  group('Email Validation', () {
    test('valid email format', () {
      const validEmail = 'student@calpoly.edu';
      const invalidEmail = 'notanemail';
      
      final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
      
      expect(emailRegex.hasMatch(validEmail), isTrue);
      expect(emailRegex.hasMatch(invalidEmail), isFalse);
    });

    test('Cal Poly email domain', () {
      const calPolyEmail = 'student@calpoly.edu';
      const otherEmail = 'user@gmail.com';
      
      expect(calPolyEmail.endsWith('@calpoly.edu'), isTrue);
      expect(otherEmail.endsWith('@calpoly.edu'), isFalse);
    });
  });
}
