// Smoke test for SmartVanApp.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:smartvan/main.dart';

void main() {
  setUp(() {
    // No token stored: the splash screen goes on to onboarding.
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('SmartVanApp builds without throwing',
      (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: SmartVanApp()));
    expect(find.byType(MaterialApp), findsOneWidget);

    // The splash screen waits 4 s before moving on; let that timer fire (it
    // is a Future.delayed, which a test cannot cancel), then take the app
    // down so nothing is left running.
    await tester.pump(const Duration(seconds: 5));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 30));
  });
}
