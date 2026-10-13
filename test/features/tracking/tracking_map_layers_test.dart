import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:smartvan/features/tracking/tracking_map_layers.dart';

void main() {
  const van = LatLng(24.9, 67.0);
  const stop = LatLng(24.95, 67.05);
  const path = [LatLng(24.9, 67.0), LatLng(24.92, 67.02), LatLng(24.95, 67.05)];
  const trail = [LatLng(24.89, 66.99), LatLng(24.9, 67.0)];

  Polyline line(Set<Polyline> s, String id) =>
      s.firstWhere((p) => p.polylineId.value == id);

  group('trackingPolylines', () {
    test('planned line: bright blue, width 6, on a wider white outline', () {
      final lines = trackingPolylines(
          plannedPath: path, trail: trail, van: van, stop: stop);
      final blue = line(lines, 'planned');
      final outline = line(lines, 'planned-outline');
      expect(blue.color, const Color(0xFF2563EB));
      expect(blue.width, 6);
      expect(blue.patterns, isEmpty);
      expect(outline.color, Colors.white);
      expect(outline.width, greaterThan(blue.width));
      expect(outline.zIndex, lessThan(blue.zIndex));
      expect(blue.points, path);
    });

    test('the trail is thinner, a different colour and on top', () {
      final lines = trackingPolylines(
          plannedPath: path, trail: trail, van: van, stop: stop);
      final blue = line(lines, 'planned');
      final grey = line(lines, 'trail');
      expect(grey.color, trailLineColor);
      expect(grey.color, isNot(blue.color));
      expect(grey.width, lessThan(blue.width));
      expect(grey.zIndex, greaterThan(blue.zIndex));
    });

    test('no road path yet: a thin dashed blue line van → stop stands in', () {
      final lines = trackingPolylines(
          plannedPath: const [], trail: const [], van: van, stop: stop);
      expect(lines.map((p) => p.polylineId.value), ['planned']);
      final stand = line(lines, 'planned');
      expect(stand.points, [van, stop]);
      expect(stand.patterns, isNotEmpty);
      expect(stand.width, lessThan(6));
    });

    test('a one-point trail draws nothing', () {
      final lines = trackingPolylines(
          plannedPath: path, trail: [trail.first], van: van, stop: stop);
      expect(lines.any((p) => p.polylineId.value == 'trail'), isFalse);
    });
  });

  group('boundsOfPoints', () {
    test('covers every point', () {
      final b = boundsOfPoints(const [
        LatLng(24.9, 67.0),
        LatLng(24.95, 67.05),
        LatLng(24.85, 67.1),
      ])!;
      expect(b.southwest, const LatLng(24.85, 67.0));
      expect(b.northeast, const LatLng(24.95, 67.1));
    });

    test('nothing to fit gives null; one point gives a zero-size box', () {
      expect(boundsOfPoints(const []), isNull);
      final b = boundsOfPoints(const [LatLng(1, 2)])!;
      expect(b.southwest, b.northeast);
    });
  });

  group('etaText', () {
    test('minutes with the Pakistan clock time the server sends', () {
      expect(etaText(5, '1:23 PM'), '5 min (1:23 PM)');
    });

    test('no usable time: minutes only', () {
      expect(etaText(12, 'N/A'), '12 min');
      expect(etaText(12, null), '12 min');
      expect(etaText(12, ''), '12 min');
    });

    test('a minute or less is Arriving now', () {
      expect(etaText(1, '1:23 PM'), 'Arriving now');
      expect(etaText(0, null), 'Arriving now');
    });
  });
}
