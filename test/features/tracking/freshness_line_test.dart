import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smartvan/features/tracking/widgets/freshness_line.dart';

void main() {
  final now = DateTime(2026, 10, 13, 13, 30);

  Future<void> pump(WidgetTester tester,
          {required DateTime? lastAt, bool offline = false}) =>
      tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: FreshnessLine(now: now, lastAt: lastAt, offline: offline),
        ),
      ));

  testWidgets('always says how old the position is', (tester) async {
    await pump(tester, lastAt: now.subtract(const Duration(seconds: 12)));
    expect(find.text('Updated 12 sec ago'), findsOneWidget);
  });

  testWidgets('before any position it still says something', (tester) async {
    await pump(tester, lastAt: null);
    expect(find.textContaining('Waiting'), findsOneWidget);
  });

  testWidgets('offline: when the van was last seen, in red', (tester) async {
    await pump(tester, lastAt: DateTime(2026, 10, 13, 13, 23), offline: true);
    expect(find.text('Driver offline — last seen 1:23 PM'), findsOneWidget);
    final text = tester.widget<Text>(find.textContaining('last seen'));
    expect(text.style?.color, const Color(0xFFFF4B4B));
  });

  testWidgets('offline with no position known falls back to the age line',
      (tester) async {
    await pump(tester, lastAt: null, offline: true);
    expect(find.textContaining('Waiting'), findsOneWidget);
  });
}
