import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smartvan/core/network/api_service.dart';
import 'package:smartvan/features/home/screens/home_screen.dart';
import 'package:smartvan/features/trips/screens/trip_details_screen.dart';
import 'package:smartvan/features/trips/screens/trip_history_screen.dart';
import 'package:smartvan/features/trips/trips_api.dart';

const _child = {
  'kidId': 'k1',
  'name': 'Ayesha',
  'status': 'picked',
  // 02:10 UTC = 7:10 AM PKT
  'at': '2026-10-15T02:10:00.000Z',
};

Map<String, dynamic> _trip({bool full = false}) => {
      'id': 't1',
      'routeName': 'Gulshan Morning',
      'tripType': 'pick',
      'date': '2026-10-15',
      'startedAt': '2026-10-15T02:00:00.000Z',
      'endedAt': '2026-10-15T02:41:00.000Z',
      'durationSeconds': 2460,
      'distanceMeters': 11840,
      'children': [_child],
      if (full) ...{
        'driverName': 'Danish Tufail',
        'vanNumber': 'KHI-1234',
        'school': {'name': 'City School', 'lat': 24.86, 'lng': 67.0},
      },
    };

class _FakeApi implements HttpClientAdapter {
  bool withTrail = true;
  bool completedFails = false;
  bool emptyCompleted = false;

  @override
  Future<ResponseBody> fetch(RequestOptions options,
      Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    Object body = {'data': []};
    final path = options.path;
    if (path.startsWith('/parent/trips/completed')) {
      if (completedFails) {
        throw DioException.connectionError(
            requestOptions: options, reason: 'offline');
      }
      body = {
        'data': {
          'items': emptyCompleted ? [] : [_trip()],
          'hasMore': false
        }
      };
    } else if (path == '/parent/trips/t1/details') {
      body = {'data': _trip(full: true)};
    } else if (path == '/trips/t1/trail') {
      body = {
        'data': {
          'path': withTrail
              ? [
                  {'lat': 24.9, 'lng': 67.1},
                  {'lat': 24.88, 'lng': 67.05},
                  {'lat': 24.86, 'lng': 67.0},
                ]
              : []
        }
      };
    } else if (path == '/kid/getKids') {
      body = {
        'data': [
          {'_id': 'k1', 'homeLat': 24.89, 'homeLng': 67.06}
        ]
      };
    } else if (path == '/auth/getProfile') {
      body = {
        'data': {'fullname': 'Test Parent'}
      };
    } else if (path == '/rating/myRatingSummary') {
      body = {'data': {}};
    } else if (path == '/chat/unread') {
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

void main() {
  late _FakeApi api;

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({});
    api = _FakeApi();
    ApiService.useHttpAdapter(api);
  });

  Future<void> setBigView(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1800, 3600);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
  }

  test('times are shown in Pakistan time', () {
    expect(pktTime(DateTime.utc(2026, 10, 15, 2, 10)), '7:10 AM');
    expect(pktTime(DateTime.utc(2026, 10, 15, 20, 5)), '1:05 AM');
    expect(pktDate(DateTime.utc(2026, 10, 15, 20, 5)), '16 Oct 2026');
    expect(durationText(2460), '41 min');
    expect(distanceText(11840), '11.8 km');
  });

  group('Home section', () {
    Future<void> openHome(WidgetTester tester) async {
      await setBigView(tester);
      await tester.pumpWidget(
          const ProviderScope(child: MaterialApp(home: HomeScreen())));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
    }

    Future<void> close(WidgetTester tester) async {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 1));
    }

    testWidgets('shows the child, driver, van and times', (tester) async {
      await openHome(tester);
      await tester.scrollUntilVisible(find.text("Today's completed trips"), 300,
          scrollable: find.byType(Scrollable).first);
      expect(find.text("Today's completed trips"), findsOneWidget);
      expect(find.text('Ayesha'), findsOneWidget);
      expect(find.textContaining('Danish Tufail'), findsOneWidget);
      expect(find.textContaining('KHI-1234'), findsOneWidget);
      expect(find.textContaining('7:10 AM'), findsOneWidget);
      expect(find.textContaining('Trip ended 7:41 AM'), findsOneWidget);
      await close(tester);
    });

    testWidgets('shows nothing when no trip ended today', (tester) async {
      api.emptyCompleted = true;
      await openHome(tester);
      expect(find.text("Today's completed trips"), findsNothing);
      expect(find.text('View all'), findsNothing);
      await close(tester);
    });

    testWidgets('shows nothing when the request fails', (tester) async {
      api.completedFails = true;
      await openHome(tester);
      expect(find.text("Today's completed trips"), findsNothing);
      await close(tester);
    });
  });

  group('Trip Details', () {
    Future<void> openDetails(WidgetTester tester) async {
      await setBigView(tester);
      await tester.pumpWidget(const MaterialApp(
          home: TripDetailsScreen(tripId: 't1', kidId: 'k1')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
    }

    testWidgets('with a trail: map and all the facts', (tester) async {
      await openDetails(tester);
      expect(find.byType(GoogleMap), findsOneWidget);
      expect(find.text('Danish Tufail'), findsOneWidget);
      expect(find.text('KHI-1234'), findsOneWidget);
      expect(find.textContaining('Gulshan Morning'), findsOneWidget);
      expect(find.text('15 Oct 2026'), findsOneWidget);
      expect(find.text('7:00 AM'), findsOneWidget);
      expect(find.text('7:41 AM'), findsOneWidget);
      expect(find.text('41 min'), findsOneWidget);
      expect(find.text('11.8 km'), findsOneWidget);
      expect(find.text('7:10 AM'), findsOneWidget);
      expect(find.text('Picked up'), findsOneWidget);
      expect(find.textContaining('not recorded'), findsNothing);

      final map = tester.widget<GoogleMap>(find.byType(GoogleMap));
      expect(map.polylines.single.points.length, 3);
      expect(map.markers.map((m) => m.markerId.value),
          containsAll(['start', 'end', 'stop', 'school']));
    });

    testWidgets('without a trail: no line, still the facts and a note',
        (tester) async {
      api.withTrail = false;
      await openDetails(tester);
      expect(find.textContaining('not recorded'), findsOneWidget);
      expect(find.text('Danish Tufail'), findsOneWidget);
      final map = tester.widget<GoogleMap>(find.byType(GoogleMap));
      expect(map.polylines, isEmpty);
      expect(map.markers.map((m) => m.markerId.value),
          containsAll(['stop', 'school']));
      expect(map.markers.map((m) => m.markerId.value),
          isNot(contains('start')));
    });
  });

  group('Trip History', () {
    testWidgets('lists trips, and shows the empty state', (tester) async {
      await setBigView(tester);
      await tester.pumpWidget(const MaterialApp(home: TripHistoryScreen()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('Ayesha'), findsOneWidget);

      api.emptyCompleted = true;
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpWidget(const MaterialApp(home: TripHistoryScreen()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('No completed trips yet'), findsOneWidget);
    });

    testWidgets('shows an error with a retry button', (tester) async {
      api.completedFails = true;
      await setBigView(tester);
      await tester.pumpWidget(const MaterialApp(home: TripHistoryScreen()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.textContaining('No internet'), findsOneWidget);
      expect(find.text('Try again'), findsOneWidget);
    });
  });
}
