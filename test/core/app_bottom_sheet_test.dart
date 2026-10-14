import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smartvan/core/widgets/app_bottom_sheet.dart';
import 'package:smartvan/core/widgets/bottom_inset.dart';

const _screen = Size(400, 800);
const _navBar = 48.0;

/// A phone with a [_navBar] tall system navigation bar and, optionally, a
/// keyboard of [keyboard] logical pixels (which covers the nav bar).
Widget _app({
  required Widget home,
  double keyboard = 0,
}) {
  return MediaQuery(
    data: MediaQueryData(
      size: _screen,
      padding: EdgeInsets.only(top: 24, bottom: keyboard > 0 ? 0 : _navBar),
      viewPadding: const EdgeInsets.only(top: 24, bottom: _navBar),
      viewInsets: EdgeInsets.only(bottom: keyboard),
    ),
    child: MaterialApp(home: home),
  );
}

Widget _opener(WidgetBuilder content,
    {bool padContent = true, bool safeAreaInside = false}) {
  return Builder(
    builder: (context) => Scaffold(
      body: Center(
        child: TextButton(
          onPressed: () => showAppBottomSheet<void>(
            context: context,
            padContent: padContent,
            builder: (c) =>
                safeAreaInside ? SafeArea(child: content(c)) : content(c),
          ),
          child: const Text('open'),
        ),
      ),
    ),
  );
}

void main() {
  setUp(() {
    final binding = TestWidgetsFlutterBinding.ensureInitialized();
    binding.platformDispatcher.views.first
      ..physicalSize = _screen
      ..devicePixelRatio = 1;
    addTearDown(() {
      binding.platformDispatcher.views.first.resetPhysicalSize();
      binding.platformDispatcher.views.first.resetDevicePixelRatio();
    });
  });

  group('sheetBottomInset', () {
    test('is the nav bar when no keyboard', () {
      expect(
        sheetBottomInset(
            const MediaQueryData(viewPadding: EdgeInsets.only(bottom: 48))),
        48,
      );
    });

    test('is the keyboard when it is open (it already covers the nav bar)', () {
      expect(
        sheetBottomInset(const MediaQueryData(
          viewPadding: EdgeInsets.only(bottom: 48),
          viewInsets: EdgeInsets.only(bottom: 300),
        )),
        300,
      );
    });
  });

  group('showAppBottomSheet', () {
    testWidgets('last line and button sit above the nav bar', (tester) async {
      await tester.pumpWidget(_app(
        home: _opener((_) => const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(height: 100),
                ElevatedButton(onPressed: null, child: Text('Confirm')),
              ],
            )),
      ));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      final bottom = tester.getBottomLeft(find.byType(ElevatedButton)).dy;
      expect(bottom, lessThanOrEqualTo(_screen.height - _navBar));
    });

    testWidgets('the sheet surface still runs behind the nav bar',
        (tester) async {
      await tester.pumpWidget(_app(
        home: _opener((_) => const SizedBox(height: 100, width: 400)),
      ));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      final surface = tester.getRect(find
          .descendant(
              of: find.byType(BottomSheet), matching: find.byType(Material))
          .first);
      expect(surface.bottom, _screen.height);
    });

    testWidgets('a nested SafeArea does not add the nav bar twice',
        (tester) async {
      await tester.pumpWidget(_app(
        home: _opener(
          (_) => const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ElevatedButton(onPressed: null, child: Text('Confirm')),
            ],
          ),
          safeAreaInside: true,
        ),
      ));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      final bottom = tester.getBottomLeft(find.byType(ElevatedButton)).dy;
      expect(bottom, _screen.height - _navBar);
    });

    testWidgets('content clears the keyboard', (tester) async {
      await tester.pumpWidget(_app(
        keyboard: 300,
        home: _opener(
          (_) => const TextField(key: Key('field')),
        ),
      ));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      final bottom = tester.getBottomLeft(find.byKey(const Key('field'))).dy;
      expect(bottom, lessThanOrEqualTo(_screen.height - 300));
    });

    testWidgets('padContent: false leaves the inset to the sheet',
        (tester) async {
      late double seen;
      await tester.pumpWidget(_app(
        home: _opener((c) {
          seen = sheetBottomInsetOf(c);
          return const SizedBox(height: 100);
        }, padContent: false),
      ));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(seen, _navBar);
    });
  });

  testWidgets('withBottomInset adds the nav bar to a scrollable padding',
      (tester) async {
    late EdgeInsets padding;
    await tester.pumpWidget(_app(
      home: Builder(builder: (context) {
        padding = withBottomInset(context, const EdgeInsets.all(16));
        return const SizedBox();
      }),
    ));
    expect(padding, const EdgeInsets.fromLTRB(16, 16, 16, 16 + _navBar));
  });
}
