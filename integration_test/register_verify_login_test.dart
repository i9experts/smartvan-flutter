import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:smartvan/main.dart' as app;
import 'package:smartvan/features/auth/screens/login_screen.dart';
import 'package:smartvan/features/auth/screens/register_screen.dart';
import 'package:smartvan/features/home/screens/home_screen.dart';

final testEmail =
    'smartvan.qa.${DateTime.now().millisecondsSinceEpoch}@gmail.com';
const testPassword = 'SmartVan#2026';
const testName = 'QA Tester';
const testPhone = '03001234567';

Future<void> _pumpUntil(WidgetTester tester, Finder finder,
    {int maxTries = 30, Duration step = const Duration(milliseconds: 500)}) async {
  for (var i = 0; i < maxTries; i++) {
    await tester.pump(step);
    if (finder.evaluate().isNotEmpty) return;
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('register -> verify OTP auto-logs in and reaches home',
      (tester) async {
    String? capturedOtp;
    final originalDebugPrint = debugPrint;
    debugPrint = (String? message, {int? wrapWidth}) {
      if (message != null) {
        final match = RegExp(r'otp:\s*(\d{6})').firstMatch(message);
        if (match != null) capturedOtp = match.group(1);
      }
      originalDebugPrint(message, wrapWidth: wrapWidth);
    };

    app.main();
    await tester.pump(const Duration(seconds: 1));
    await _pumpUntil(tester, find.byType(LoginScreen),
        maxTries: 20, step: const Duration(milliseconds: 500));

    final loginCta = find.text('Log in or create an account');
    if (loginCta.evaluate().isNotEmpty) {
      await tester.tap(loginCta);
      await _pumpUntil(tester, find.byType(LoginScreen));
    }

    expect(find.byType(LoginScreen), findsOneWidget);
    await tester.tap(find.text('Sign Up'));
    await _pumpUntil(tester, find.byType(RegisterScreen));

    // Confirm the parent/driver role selector is gone.
    expect(find.text('I am registering as'), findsNothing);
    expect(find.text('Driver'), findsNothing);

    final fields = find.byType(TextFormField);
    expect(fields, findsNWidgets(5));
    await tester.enterText(fields.at(0), testName);
    await tester.enterText(fields.at(1), testEmail);
    await tester.enterText(fields.at(2), testPhone);
    await tester.enterText(fields.at(3), testPassword);
    await tester.enterText(fields.at(4), testPassword);

    await tester.tap(find.byType(Checkbox));
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.widgetWithText(ElevatedButton, 'Create Account'));
    await _pumpUntil(tester, find.text('OTP Verification'));

    expect(find.text('OTP Verification'), findsOneWidget);
    expect(capturedOtp, isNotNull,
        reason: 'Expected to capture OTP from the registration response');

    await tester.enterText(find.byType(TextFormField).first, capturedOtp!);
    await tester.pump(const Duration(milliseconds: 500));
    await tester.tap(find.widgetWithText(ElevatedButton, 'Verify OTP'));
    // Verifying OTP after registration should log the user straight into
    // the app — no separate login step required.
    await _pumpUntil(tester, find.byType(HomeScreen),
        maxTries: 30, step: const Duration(milliseconds: 500));

    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.byType(LoginScreen), findsNothing);
  });
}
