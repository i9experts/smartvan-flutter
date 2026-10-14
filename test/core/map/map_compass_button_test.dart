import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smartvan/core/map/map_compass_button.dart';

void main() {
  Widget host(Widget child) =>
      MaterialApp(home: Scaffold(body: Center(child: child)));

  double turns(WidgetTester tester) => tester
      .widget<AnimatedRotation>(find.byKey(const Key('compass-needle')))
      .turns;

  testWidgets('north up: the needle is not turned', (tester) async {
    await tester.pumpWidget(host(MapCompassButton(
        bearing: 0, onPressed: () {}, semanticLabel: 'Point map north')));
    expect(turns(tester), 0);
  });

  testWidgets('the needle turns by minus the bearing', (tester) async {
    await tester.pumpWidget(host(
        MapCompassButton(bearing: 90, onPressed: () {}, semanticLabel: 'x')));
    expect(turns(tester), closeTo(-0.25, 1e-9));
    await tester.pumpWidget(host(
        MapCompassButton(bearing: 180, onPressed: () {}, semanticLabel: 'x')));
    expect(turns(tester), closeTo(-0.5, 1e-9));
  });

  testWidgets(
      '359° → 1° turns the short way (+2°), not nearly a full turn back',
      (tester) async {
    await tester.pumpWidget(host(
        MapCompassButton(bearing: 359, onPressed: () {}, semanticLabel: 'x')));
    final before = turns(tester);
    await tester.pumpWidget(host(
        MapCompassButton(bearing: 1, onPressed: () {}, semanticLabel: 'x')));
    expect((turns(tester) - before).abs(), lessThan(0.01));
  });

  testWidgets('smooth: the rotation animates, it does not jump',
      (tester) async {
    await tester.pumpWidget(host(
        MapCompassButton(bearing: 0, onPressed: () {}, semanticLabel: 'x')));
    await tester.pumpWidget(host(
        MapCompassButton(bearing: 90, onPressed: () {}, semanticLabel: 'x')));
    expect(find.byType(AnimatedRotation), findsOneWidget);
    final rotation =
        tester.widget<AnimatedRotation>(find.byType(AnimatedRotation));
    expect(rotation.duration, greaterThan(Duration.zero));
  });

  testWidgets('tapping calls onPressed', (tester) async {
    var taps = 0;
    await tester.pumpWidget(host(MapCompassButton(
        bearing: 0, onPressed: () => taps++, semanticLabel: 'x')));
    await tester.tap(find.byType(MapCompassButton));
    expect(taps, 1);
  });

  testWidgets('heading-up shows the navigation arrow instead of the needle',
      (tester) async {
    await tester.pumpWidget(host(MapCompassButton(
        bearing: 0,
        headingUp: true,
        onPressed: () {},
        semanticLabel: 'Point map north')));
    expect(find.byKey(const Key('compass-heading-up')), findsOneWidget);
    expect(find.byKey(const Key('compass-needle')), findsNothing);
  });

  testWidgets('a screen reader hears what the tap does', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(host(MapCompassButton(
        bearing: 0, onPressed: () {}, semanticLabel: 'Rotate map with van')));
    expect(find.bySemanticsLabel('Rotate map with van'), findsOneWidget);
    final node =
        tester.getSemantics(find.bySemanticsLabel('Rotate map with van'));
    expect(node.hasFlag(SemanticsFlag.isButton), isTrue);
    handle.dispose();
  });

  testWidgets('the label changes with the next action', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(host(MapCompassButton(
        bearing: 0, onPressed: () {}, semanticLabel: 'Rotate map with van')));
    await tester.pumpWidget(host(MapCompassButton(
        bearing: 40, onPressed: () {}, semanticLabel: 'Point map north')));
    expect(find.bySemanticsLabel('Point map north'), findsOneWidget);
    handle.dispose();
  });
}
