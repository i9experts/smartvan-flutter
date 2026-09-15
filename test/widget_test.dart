// Basic smoke test for SmartVanApp.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:smartvan/main.dart';

void main() {
  testWidgets('SmartVanApp builds without throwing', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: SmartVanApp()));
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
