import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:smartvan/main.dart' as app;

const testEmail = 'jamiraza359@gmail.com';
const testPassword = 'SmartVan#2026';
const testName = 'Jami Raza';
const testPhone = '03001234567';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('register a new parent account and reach OTP screen',
      (tester) async {
    app.main();
    await tester.pumpAndSettle(const Duration(seconds: 3));

    // Onboarding -> tap "Log in or create an account"
    final loginCta = find.text('Log in or create an account');
    if (loginCta.evaluate().isNotEmpty) {
      await tester.tap(loginCta);
      await tester.pumpAndSettle(const Duration(seconds: 1));
    }

    // Login screen -> go to Sign Up
    final signUp = find.textContaining('Sign Up');
    expect(signUp, findsWidgets);
    await tester.tap(signUp.first);
    await tester.pumpAndSettle(const Duration(seconds: 1));

    // Confirm role selector ("I am registering as") is gone.
    expect(find.text('I am registering as'), findsNothing);
    expect(find.text('Driver'), findsNothing);

    // Fill registration form: name, email, phone, password, confirm password.
    final fields = find.byType(TextFormField);
    expect(fields, findsNWidgets(5));
    await tester.enterText(fields.at(0), testName);
    await tester.enterText(fields.at(1), testEmail);
    await tester.enterText(fields.at(2), testPhone);
    await tester.enterText(fields.at(3), testPassword);
    await tester.enterText(fields.at(4), testPassword);

    await tester.tap(find.byType(Checkbox));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(ElevatedButton, 'Create Account'));
    await tester.pumpAndSettle(const Duration(seconds: 5));

    // Should now be on the OTP screen.
    expect(find.text('OTP Verification'), findsOneWidget);
  });
}
