import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'van_pose_animator.dart';

/// Keeps a map's camera on the van while [following], and lets the user take
/// over: [userMoved] (a touch on the map) stops following, [recenter] resumes.
/// Listen to it to show or hide a "Re-center" button ([showRecenter]).
///
/// Same idea as the driver app's controller; [following] can start off (the
/// parent's map first fits the whole route), and [pause] leaves follow mode
/// without offering "Re-center".
class FollowCameraController extends ChangeNotifier {
  FollowCameraController({bool following = true}) : _following = following;

  bool _following;
  bool _released = false;
  VanPose? _last;
  Future<void> Function(LatLng)? _move;
  Future<void> Function(LatLng)? _animate;

  bool get following => _following;

  /// True after the user moved the map away while it was following — the
  /// moment to offer "Re-center".
  bool get showRecenter => _released;

  /// Hooks up a real map: [move] jumps the camera (called every frame while
  /// the van animates), [animate] glides it (used by [recenter]).
  void attach({
    required Future<void> Function(LatLng) move,
    required Future<void> Function(LatLng) animate,
  }) {
    _move = move;
    _animate = animate;
  }

  /// [recenterZoom]: zoom (and flat tilt) used when gliding back to the van;
  /// while following, the camera only moves and keeps the user's zoom.
  void attachMap(GoogleMapController map, {double? recenterZoom}) => attach(
        move: (p) => map.moveCamera(CameraUpdate.newLatLng(p)),
        animate: (p) => map.animateCamera(recenterZoom == null
            ? CameraUpdate.newLatLng(p)
            : CameraUpdate.newCameraPosition(
                CameraPosition(target: p, zoom: recenterZoom, tilt: 0))),
      );

  void detach() {
    _move = null;
    _animate = null;
  }

  /// The van is now drawn at [pose]; follows it when following.
  void onPose(VanPose pose) {
    _last = pose;
    if (_following) _run(_move, pose.position);
  }

  /// The user touched the map: stop following (and offer "Re-center" if it
  /// was following).
  void userMoved() {
    if (_following) {
      _following = false;
      _released = true;
      notifyListeners();
    }
  }

  /// Leave follow mode on purpose (the map was fitted to the whole route):
  /// no "Re-center" button.
  void pause() {
    if (!_following && !_released) return;
    _following = false;
    _released = false;
    notifyListeners();
  }

  /// Follow again, gliding back to the van.
  void recenter() {
    final changed = !_following || _released;
    _following = true;
    _released = false;
    final last = _last;
    if (last != null) _run(_animate, last.position);
    if (changed) notifyListeners();
  }

  void _run(Future<void> Function(LatLng)? action, LatLng to) {
    // A map that is being torn down can refuse; the next frame tries again.
    action?.call(to).catchError((Object e) {
      debugPrint('[FollowCamera] camera move failed: $e');
    });
  }
}
