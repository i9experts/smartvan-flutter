import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:smartvan/core/map/animated_van_marker.dart';

void main() {
  final normal = BitmapDescriptor.defaultMarkerWithHue(10);
  final grey = BitmapDescriptor.defaultMarkerWithHue(200);

  Future<Marker> van(WidgetTester tester, {required bool stale}) async {
    Marker? seen;
    await tester.pumpWidget(MaterialApp(
      home: AnimatedVanMarker(
        position: const LatLng(24.9, 67.0),
        stale: stale,
        iconFactory: ({required devicePixelRatio}) async => normal,
        staleIconFactory: ({required devicePixelRatio}) async => grey,
        builder: (context, markers) {
          seen = markers.isEmpty ? null : markers.first;
          return const SizedBox();
        },
      ),
    ));
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
    return seen!;
  }

  testWidgets('a live van is the normal icon, fully opaque', (tester) async {
    final m = await van(tester, stale: false);
    expect(m.icon, normal);
    expect(m.alpha, 1.0);
  });

  testWidgets('an offline (stale) van is grey and faded', (tester) async {
    final m = await van(tester, stale: true);
    expect(m.icon, grey);
    expect(m.alpha, lessThan(1.0));
  });
}
