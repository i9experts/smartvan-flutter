import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:smartvan/main.dart' as app;
import 'package:smartvan/features/auth/screens/login_screen.dart';
import 'package:smartvan/features/auth/screens/reset_password_screen.dart';
import 'package:smartvan/features/home/screens/home_screen.dart';

const testEmail = 'jamiraza359@gmail.com';
const newPassword = 'SmartVan#2026';

/// The OTP screen runs a 60-second countdown animation, so pumpAndSettle
/// never returns there; pump a bounded number of times instead and check
/// for the expected widget directly.
Future<void> _pumpUntil(WidgetTester tester, Finder finder,
    {int maxTries = 30, Duration step = const Duration(milliseconds: 500)}) async {
  for (var i = 0; i < maxTries; i++) {
    await tester.pump(step);
    if (finder.evaluate().isNotEmpty) return;
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('forgot password -> reset -> login reaches home',
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
    await tester.tap(find.text('Forgot Password?'));
    await tester.pump(const Duration(milliseconds: 500));

    await tester.enterText(find.byType(TextFormField).first, testEmail);
    await tester.tap(find.widgetWithText(ElevatedButton, 'Send Reset OTP'));
    await _pumpUntil(tester, find.text('OTP Verification'));

    expect(find.text('OTP Verification'), findsOneWidget);
    expect(capturedOtp, isNotNull,
        reason: 'Expected to capture OTP from the forgot-password response');

    await tester.enterText(find.byType(TextFormField).first, capturedOtp!);
    await tester.pump(const Duration(milliseconds: 500));
    await tester.tap(find.widgetWithText(ElevatedButton, 'Verify OTP'));
    await _pumpUntil(tester, find.byType(ResetPasswordScreen));

    expect(find.byType(ResetPasswordScreen), findsOneWidget);

    final passwordFields = find.byType(TextFormField);
    expect(passwordFields, findsNWidgets(2));
    await tester.enterText(passwordFields.at(0), newPassword);
    await tester.enterText(passwordFields.at(1), newPassword);

    await tester.tap(find.widgetWithText(ElevatedButton, 'Reset Password'));
    await _pumpUntil(tester, find.byType(LoginScreen));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byType(LoginScreen), findsOneWidget);

    final loginFields = find.byType(TextField);
    await tester.enterText(loginFields.at(0), testEmail);
    await tester.enterText(loginFields.at(1), newPassword);
    await tester.tap(find.widgetWithText(ElevatedButton, 'Login'));
    await _pumpUntil(tester, find.byType(HomeScreen),
        maxTries: 30, step: const Duration(milliseconds: 500));

    expect(find.byType(HomeScreen), findsOneWidget);
  });
}
