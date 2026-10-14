import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:smartvan/core/map/map_compass.dart';

void main() {
  group('compassTapAction', () {
    test('a turned map goes north', () {
      expect(
          compassTapAction(
              bearing: 90,
              following: true,
              headingUp: false,
              headingUpAllowed: false),
          CompassTapAction.pointNorth);
    });

    test('the parent map has no heading-up: always north', () {
      expect(
          compassTapAction(
              bearing: 0,
              following: true,
              headingUp: false,
              headingUpAllowed: false),
          CompassTapAction.pointNorth);
    });

    test('north is within half a degree', () {
      expect(isPointingNorth(0.4), isTrue);
      expect(isPointingNorth(359.7), isTrue);
      expect(isPointingNorth(1), isFalse);
    });
  });

  group('MapCompassController without a follow camera (north up only)', () {
    late MapCompassController compass;
    late List<CameraPosition> animated;

    setUp(() {
      animated = [];
      compass = MapCompassController()
        ..attach(animateTo: (p) async => animated.add(p));
    });

    tearDown(() => compass.dispose());

    test('takes bearing and zoom from the camera moves', () {
      var notified = 0;
      compass.addListener(() => notified++);
      compass.onCameraMove(const CameraPosition(
          target: LatLng(24.9, 67.0), zoom: 16, bearing: 75));
      expect(compass.bearing, 75);
      expect(compass.zoom, 16);
      expect(notified, 1);
    });

    test('tap: north up, target and zoom stay, tilt 0', () {
      compass.onCameraMove(const CameraPosition(
          target: LatLng(24.9, 67.0), zoom: 16, bearing: 75, tilt: 20));
      compass.onPressed();
      expect(animated.single,
          const CameraPosition(target: LatLng(24.9, 67.0), zoom: 16));
    });

    test('never heading-up, even on a north map', () {
      compass.onCameraMove(const CameraPosition(
          target: LatLng(24.9, 67.0), zoom: 16, bearing: 0));
      expect(compass.nextAction, CompassTapAction.pointNorth);
      compass.onPressed();
      expect(compass.headingUp, isFalse);
      expect(animated.single.bearing, 0);
    });

    test('a refusing map does not crash', () async {
      compass.attach(animateTo: (_) => Future<void>.error(StateError('gone')));
      compass.onCameraMove(
          const CameraPosition(target: LatLng(1, 2), zoom: 14, bearing: 90));
      compass.onPressed();
      await Future<void>.delayed(Duration.zero);
    });
  });
}
