import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ccce_application/common/features/legal_document_screen.dart';

void main() {
  group('LegalDocumentScreen', () {
    testWidgets('displays loading indicator initially', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: LegalDocumentScreen(
            title: 'Test Document',
            assetPath: 'assets/terms_and_conditions.txt',
          ),
        ),
      );

      // Initially should show loading
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('displays title in app bar', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: LegalDocumentScreen(
            title: 'Privacy Policy',
            assetPath: 'assets/privacy_policy.txt',
          ),
        ),
      );

      expect(find.text('Privacy Policy'), findsOneWidget);
    });
  });
}
