import 'package:flutter/animation.dart';
import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'geo_math.dart';

/// Where the van is drawn and which way it points (degrees, 0 = north).
@immutable
class VanPose {
  const VanPose(this.position, this.rotation);

  final LatLng position;
  final double rotation;

  @override
  bool operator ==(Object other) =>
      other is VanPose &&
      other.position == position &&
      other.rotation == rotation;

  @override
  int get hashCode => Object.hash(position, rotation);
}

/// Turns the stream of GPS fixes into a smooth [pose]: each new fix is
/// reached in [duration] by blending the coordinates and turning the short
/// way round. No UI in here — give it a [TickerProvider] and listen to [pose].
class VanPoseAnimator {
  VanPoseAnimator({
    required TickerProvider vsync,
    this.duration = const Duration(seconds: 1),
    this.jumpThresholdMeters = 200,
    this.minSpeedMetersPerSecond = 1,
    this.minMoveMeters = 3,
  }) : _controller = AnimationController(vsync: vsync, duration: duration) {
    _controller.addListener(_tick);
  }

  final Duration duration;

  /// A fix further than this from where the van is drawn is a jump (tunnel,
  /// GPS recovering): the van is placed there, not driven there.
  final double jumpThresholdMeters;

  /// Below this speed the heading from GPS is noise, so the van keeps the way
  /// it was pointing.
  final double minSpeedMetersPerSecond;

  /// Without a speed reading, moves shorter than this don't turn the van.
  final double minMoveMeters;

  final AnimationController _controller;

  /// Null until the first fix.
  final ValueNotifier<VanPose?> pose = ValueNotifier(null);

  LatLng? _target;
  LatLng _from = const LatLng(0, 0);
  LatLng _to = const LatLng(0, 0);
  double _fromRotation = 0;
  double _toRotation = 0;

  /// A new GPS fix. [speedMetersPerSecond] is the device's own reading, if it
  /// has one. [headingDegrees] is the compass heading reported with the fix
  /// (0 = north); without a usable one the heading is the bearing from the
  /// previous fix.
  void update(LatLng position,
      {double? speedMetersPerSecond, double? headingDegrees}) {
    final previousTarget = _target;
    if (previousTarget == position) return;
    _target = position;

    final shown = pose.value;
    if (shown == null) {
      pose.value = VanPose(position, 0);
      _from = _to = position;
      return;
    }

    var rotation = shown.rotation;
    final moved = distanceMeters(previousTarget ?? shown.position, position);
    final fastEnough = speedMetersPerSecond != null
        ? speedMetersPerSecond >= minSpeedMetersPerSecond
        : moved >= minMoveMeters;
    if (fastEnough && previousTarget != null) {
      rotation = headingDegrees != null &&
              headingDegrees >= 0 &&
              headingDegrees <= 360
          ? normalizeDegrees(headingDegrees)
          : bearingDegrees(previousTarget, position);
    }

    if (distanceMeters(shown.position, position) > jumpThresholdMeters) {
      _controller.stop();
      pose.value = VanPose(position, rotation);
      return;
    }

    _from = shown.position;
    _to = position;
    _fromRotation = shown.rotation;
    _toRotation = rotation;
    _controller.forward(from: 0);
  }

  void _tick() {
    final t = _controller.value;
    pose.value = VanPose(
      lerpLatLng(_from, _to, t),
      lerpDegrees(_fromRotation, _toRotation, t),
    );
  }

  void dispose() {
    _controller.dispose();
    pose.dispose();
  }
}
