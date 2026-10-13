import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// What the compass button does when tapped.
enum CompassTapAction {
  /// Turn the map so north is up (zoom and target stay).
  pointNorth,

  /// Follow the van with the map turned to its heading ("heading up").
  headingUp,
}

/// A map whose bearing is within this many degrees of north counts as
/// pointing north.
const northToleranceDegrees = 0.5;

bool isPointingNorth(double bearing) {
  final b = bearing % 360;
  return b < northToleranceDegrees || b > 360 - northToleranceDegrees;
}

/// The compass button's next step:
///
/// - in heading-up mode → north up;
/// - map turned away from north → north up;
/// - already north and following the van → heading up ([headingUpAllowed]);
/// - otherwise → north up (nothing to do if it already is).
CompassTapAction compassTapAction({
  required double bearing,
  required bool following,
  required bool headingUp,
  bool headingUpAllowed = true,
}) {
  if (headingUp) return CompassTapAction.pointNorth;
  if (!isPointingNorth(bearing)) return CompassTapAction.pointNorth;
  if (following && headingUpAllowed) return CompassTapAction.headingUp;
  return CompassTapAction.pointNorth;
}

/// What the compass needs from the follow-the-van camera. Only the driver's
/// map has a heading-up mode; a map without one passes no follow at all.
abstract interface class CompassFollow implements Listenable {
  bool get following;
  bool get headingUp;

  /// Follow the van with the map turned to its heading.
  void enterHeadingUp();

  /// Back to a north-up map (still following if it was).
  void exitHeadingUp();
}

/// The camera's bearing and zoom for the compass, and what a tap does.
///
/// Feed it the map's `onCameraMove`; listen to it to rotate the needle.
class MapCompassController extends ChangeNotifier {
  MapCompassController({this.follow}) {
    follow?.addListener(notifyListeners);
  }

  /// The follow camera whose heading-up mode the compass switches; null for a
  /// map that is only ever north-up.
  final CompassFollow? follow;

  CameraPosition _camera = const CameraPosition(target: LatLng(0, 0));
  Future<void> Function(CameraPosition)? _animateTo;

  CameraPosition get camera => _camera;

  /// Degrees clockwise from north, as the map reports it.
  double get bearing => _camera.bearing;

  double get zoom => _camera.zoom;

  bool get headingUp => follow?.headingUp ?? false;

  /// What a tap would do now (for the button's label).
  CompassTapAction get nextAction => compassTapAction(
        bearing: bearing,
        following: follow?.following ?? false,
        headingUp: headingUp,
        headingUpAllowed: follow != null,
      );

  /// Hooks up the map: [animateTo] glides the camera to a position.
  void attach({required Future<void> Function(CameraPosition) animateTo}) =>
      _animateTo = animateTo;

  void attachMap(GoogleMapController map) => attach(
      animateTo: (p) => map.animateCamera(CameraUpdate.newCameraPosition(p)));

  void detach() => _animateTo = null;

  /// The map's `onCameraMove`.
  void onCameraMove(CameraPosition position) {
    _camera = position;
    notifyListeners();
  }

  void onPressed() {
    switch (nextAction) {
      case CompassTapAction.headingUp:
        follow?.enterHeadingUp();
      case CompassTapAction.pointNorth:
        follow?.exitHeadingUp();
        _animateTo
            ?.call(CameraPosition(
          target: _camera.target,
          zoom: _camera.zoom,
          bearing: 0,
          tilt: 0,
        ))
            .catchError((Object e) {
          debugPrint('[Compass] camera move failed: $e');
        });
    }
  }

  @override
  void dispose() {
    follow?.removeListener(notifyListeners);
    super.dispose();
  }
}
