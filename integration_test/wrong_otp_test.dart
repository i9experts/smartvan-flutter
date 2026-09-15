import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:smartvan/main.dart' as app;
import 'package:smartvan/features/auth/screens/login_screen.dart';
import 'package:smartvan/features/auth/screens/register_screen.dart';

final testEmail =
    'smartvan.qa.wrongotp.${DateTime.now().millisecondsSinceEpoch}@gmail.com';
const testPassword = 'SmartVan#2026';
const testName = 'QA Wrong OTP Tester';
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

  testWidgets('wrong OTP shows an error instead of doing nothing',
      (tester) async {
    app.main();
    await tester.pump(const Duration(seconds: 1));
    await _pumpUntil(tester, find.byType(LoginScreen),
        maxTries: 20, step: const Duration(milliseconds: 500));

    final loginCta = find.text('Log in or create an account');
    if (loginCta.evaluate().isNotEmpty) {
      await tester.tap(loginCta);
      await _pumpUntil(tester, find.byType(LoginScreen));
    }

    await tester.tap(find.text('Sign Up'));
    await _pumpUntil(tester, find.byType(RegisterScreen));

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

    // Deliberately wrong code.
    await tester.enterText(find.byType(TextFormField).first, '000000');
    await tester.pump(const Duration(milliseconds: 500));
    await tester.tap(find.widgetWithText(ElevatedButton, 'Verify OTP'));

    // Before the fix, this would hang forever with no feedback: the button
    // just re-enables with nothing shown. Now it should surface an error
    // via SnackBar and stay on the OTP screen.
    await _pumpUntil(tester, find.byType(SnackBar), maxTries: 20);
    expect(find.byType(SnackBar), findsOneWidget,
        reason: 'Expected an error SnackBar for the invalid OTP');
    expect(find.text('OTP Verification'), findsOneWidget,
        reason: 'Should remain on the OTP screen after a failed verify');
  });
}
