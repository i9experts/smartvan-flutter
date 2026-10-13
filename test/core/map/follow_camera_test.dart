import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:smartvan/core/map/follow_camera.dart';
import 'package:smartvan/core/map/van_pose_animator.dart';

void main() {
  const a = LatLng(1, 1);
  const b = LatLng(2, 2);
  late FollowCameraController follow;
  late List<LatLng> moved;
  late List<LatLng> animated;

  FollowCameraController make({bool following = true}) {
    final c = FollowCameraController(following: following);
    c.attach(
      move: (p) async => moved.add(p),
      animate: (p) async => animated.add(p),
    );
    return c;
  }

  setUp(() {
    moved = [];
    animated = [];
    follow = make();
  });

  test('follows the van by moving the camera on every frame', () {
    follow.onPose(const VanPose(a, 0));
    follow.onPose(const VanPose(b, 0));
    expect(moved, [a, b]);
    expect(animated, isEmpty);
  });

  test('a touch while following stops it and offers Re-center', () {
    var notified = 0;
    follow.addListener(() => notified++);
    follow.userMoved();
    expect(follow.following, isFalse);
    expect(follow.showRecenter, isTrue);
    expect(notified, 1);
    follow.onPose(const VanPose(a, 0));
    expect(moved, isEmpty);
    follow.userMoved(); // already stopped: nothing more
    expect(notified, 1);
  });

  test('recenter glides to the latest van position and follows again', () {
    follow.onPose(const VanPose(a, 0));
    follow.userMoved();
    follow.onPose(const VanPose(b, 0)); // not followed, but remembered
    follow.recenter();
    expect(follow.following, isTrue);
    expect(follow.showRecenter, isFalse);
    expect(animated, [b]);
    follow.onPose(const VanPose(a, 0));
    expect(moved.last, a);
  });

  test('starting off: the van is not followed and Re-center is not offered',
      () {
    final off = make(following: false);
    off.onPose(const VanPose(a, 0));
    expect(moved, isEmpty);
    expect(off.showRecenter, isFalse);
    off.userMoved(); // the parent was not following: no button either
    expect(off.showRecenter, isFalse);
  });

  test('recenter from an off start (the my-location button) follows', () {
    final off = make(following: false);
    off.onPose(const VanPose(a, 0));
    off.recenter();
    expect(off.following, isTrue);
    expect(animated, [a]);
  });

  test('pause leaves follow mode without offering Re-center', () {
    follow.pause();
    expect(follow.following, isFalse);
    expect(follow.showRecenter, isFalse);
    follow.onPose(const VanPose(a, 0));
    expect(moved, isEmpty);
  });

  test('pause after the user left clears the Re-center button', () {
    follow.userMoved();
    follow.pause(); // "fit" pressed
    expect(follow.showRecenter, isFalse);
  });

  test('a map that refuses a move does not crash', () async {
    follow.attach(
      move: (_) => Future<void>.error(StateError('gone')),
      animate: (_) async {},
    );
    follow.onPose(const VanPose(a, 0));
    await Future<void>.delayed(Duration.zero);
  });

  test('detached, poses are only remembered', () {
    follow.detach();
    follow.onPose(const VanPose(a, 0));
    follow.recenter();
    expect(moved, isEmpty);
    expect(animated, isEmpty);
  });
}
