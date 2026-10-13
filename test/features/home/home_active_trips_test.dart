import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smartvan/core/network/api_service.dart';
import 'package:smartvan/features/home/screens/home_screen.dart';

/// Answers every API call with an empty list, except the profile, the rating
/// summary and the active trips (which the test controls).
class _FakeApi implements HttpClientAdapter {
  List<Map<String, dynamic>> trips = [];
  bool activeTripsFail = false;
  int activeTripCalls = 0;

  @override
  Future<ResponseBody> fetch(RequestOptions options,
      Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    Object body = {'data': []};
    switch (options.path) {
      case '/kid/getActiveTripDetails':
        activeTripCalls++;
        if (activeTripsFail) {
          throw DioException.connectionError(
              requestOptions: options, reason: 'offline');
        }
        body = {'data': trips};
      case '/auth/getProfile':
        body = {
          'data': {'fullname': 'Test Parent'}
        };
      case '/rating/myRatingSummary':
        body = {'data': {}};
      case '/chat/unread':
        body = {
          'data': {'unread': 0}
        };
    }
    return ResponseBody.fromString(jsonEncode(body), 200, headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType]
    });
  }

  @override
  void close({bool force = false}) {}
}

const _trip = {
  'kids': [
    {'fullname': 'Kid One'}
  ],
  'driverFullname': 'Test Driver',
  'carNumber': 'KHI-1',
};

void main() {
  late _FakeApi api;

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({});
    api = _FakeApi();
    ApiService.useHttpAdapter(api);
  });

  Future<void> openHome(WidgetTester tester) async {
    // Wider than a phone: the test font is wider than Poppins, and Home's
    // rows would overflow here though they fit on a real device.
    tester.view.physicalSize = const Size(1800, 3600);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
        const ProviderScope(child: MaterialApp(home: HomeScreen())));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
  }

  /// Takes the screen down so its timers are cancelled.
  Future<void> close(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 1));
  }

  final card = find.text('Van is on the way!');
  Finder navItem(String label) => find.descendant(
      of: find.byType(BottomNavigationBar), matching: find.text(label));

  testWidgets(
      'the card shows while a trip is on, and goes within 30 s of its end',
      (tester) async {
    api.trips = [Map<String, dynamic>.from(_trip)];
    await openHome(tester);
    expect(card, findsOneWidget);
    expect(find.textContaining('Kid One'), findsOneWidget);

    api.trips = []; // the driver ended the trip
    await tester.pump(const Duration(seconds: 29));
    expect(card, findsOneWidget, reason: 'not asked again yet');
    await tester.pump(const Duration(seconds: 2));
    await tester.pump(const Duration(milliseconds: 200));
    expect(card, findsNothing);
    await close(tester);
  });

  testWidgets('a trip that starts later shows up on the next check',
      (tester) async {
    await openHome(tester);
    expect(card, findsNothing);
    api.trips = [Map<String, dynamic>.from(_trip)];
    await tester.pump(const Duration(seconds: 31));
    await tester.pump(const Duration(milliseconds: 200));
    expect(card, findsOneWidget);
    await close(tester);
  });

  testWidgets('coming back to the Home tab checks again', (tester) async {
    api.trips = [Map<String, dynamic>.from(_trip)];
    await openHome(tester);
    expect(card, findsOneWidget);

    await tester.tap(navItem('Alerts'));
    await tester.pump(const Duration(milliseconds: 300));
    final before = api.activeTripCalls;
    api.trips = [];
    await tester.tap(navItem('Home'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(api.activeTripCalls, before + 1);
    expect(card, findsNothing);
    await close(tester);
  });

  testWidgets('the timer does not check while another tab is showing',
      (tester) async {
    await openHome(tester);
    await tester.tap(navItem('Alerts'));
    await tester.pump(const Duration(milliseconds: 300));
    final before = api.activeTripCalls;
    await tester.pump(const Duration(seconds: 65));
    expect(api.activeTripCalls, before);
    await close(tester);
  });

  testWidgets('returning from the background checks again', (tester) async {
    api.trips = [Map<String, dynamic>.from(_trip)];
    await openHome(tester);
    expect(card, findsOneWidget);

    api.trips = [];
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump(const Duration(seconds: 1));
    expect(card, findsOneWidget, reason: 'nothing happens in the background');
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump(const Duration(milliseconds: 300));
    expect(card, findsNothing);
    await close(tester);
  });

  testWidgets('pull to refresh reloads the card', (tester) async {
    api.trips = [Map<String, dynamic>.from(_trip)];
    await openHome(tester);
    expect(card, findsOneWidget);

    api.trips = [];
    await tester.drag(find.byType(CustomScrollView), const Offset(0, 400));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    expect(card, findsNothing);
    await close(tester);
  });

  testWidgets('a failed check keeps the card instead of blinking it away',
      (tester) async {
    api.trips = [Map<String, dynamic>.from(_trip)];
    await openHome(tester);
    expect(card, findsOneWidget);

    api.activeTripsFail = true;
    await tester.pump(const Duration(seconds: 31));
    await tester.pump(const Duration(milliseconds: 200));
    expect(card, findsOneWidget);
    await close(tester);
  });
}
