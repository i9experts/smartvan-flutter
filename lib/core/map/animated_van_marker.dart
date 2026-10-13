import 'package:flutter/widgets.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'van_icon.dart';
import 'van_pose_animator.dart';

/// Makes the van icon for a device pixel ratio. A parameter so tests need no
/// real image encoding.
typedef VanIconFactory = Future<BitmapDescriptor> Function(
    {required double devicePixelRatio});

/// Draws the van on a map and moves it smoothly between GPS fixes.
///
/// It owns no map: [builder] gets the markers to put on whichever
/// `GoogleMap` the screen has. Feed it [position] (and [speedMetersPerSecond]
/// and [headingDegrees] when known) on every fix; the van glides there in about a second, turning
/// the short way, and [onPose] reports each animation frame (for a camera that
/// follows). Until the icon is ready, or if it cannot be made, the default
/// pin is used.
class AnimatedVanMarker extends StatefulWidget {
  const AnimatedVanMarker({
    super.key,
    required this.position,
    required this.builder,
    this.speedMetersPerSecond,
    this.headingDegrees,
    this.onPose,
    this.title,
    this.markerId = const MarkerId('van'),
    this.iconFactory = createVanIcon,
    this.staleIconFactory = createStaleVanIcon,
    this.stale = false,
    this.duration = const Duration(seconds: 1),
  });

  /// The latest GPS fix; null until there is one (no marker is drawn).
  final LatLng? position;
  final double? speedMetersPerSecond;

  /// Compass heading of the latest fix, if the server sent one.
  final double? headingDegrees;
  final Widget Function(BuildContext context, Set<Marker> markers) builder;
  final ValueChanged<VanPose>? onPose;

  /// Text of the marker's info window, if any.
  final String? title;
  final MarkerId markerId;
  final VanIconFactory iconFactory;
  final VanIconFactory staleIconFactory;

  /// The position is old (the driver is offline): the van is drawn grey and
  /// faded.
  final bool stale;
  final Duration duration;

  @override
  State<AnimatedVanMarker> createState() => _AnimatedVanMarkerState();
}

class _AnimatedVanMarkerState extends State<AnimatedVanMarker>
    with SingleTickerProviderStateMixin {
  late final VanPoseAnimator _animator = VanPoseAnimator(
    vsync: this,
    duration: widget.duration,
  );

  BitmapDescriptor? _icon;
  BitmapDescriptor? _staleIcon;
  double? _iconRatio;

  @override
  void initState() {
    super.initState();
    _animator.pose.addListener(_onPose);
    _feed();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final ratio = MediaQuery.maybeDevicePixelRatioOf(context) ?? 1.0;
    if (_iconRatio == ratio) return;
    _iconRatio = ratio;
    _loadIcon(ratio);
  }

  @override
  void didUpdateWidget(AnimatedVanMarker old) {
    super.didUpdateWidget(old);
    if (old.position != widget.position) _feed();
  }

  @override
  void dispose() {
    _animator.pose.removeListener(_onPose);
    _animator.dispose();
    super.dispose();
  }

  void _feed() {
    final p = widget.position;
    if (p != null) {
      _animator.update(
        p,
        speedMetersPerSecond: widget.speedMetersPerSecond,
        headingDegrees: widget.headingDegrees,
      );
    }
  }

  void _onPose() {
    final pose = _animator.pose.value;
    if (pose != null) widget.onPose?.call(pose);
  }

  Future<void> _loadIcon(double ratio) async {
    try {
      final icon = await widget.iconFactory(devicePixelRatio: ratio);
      final stale = await widget.staleIconFactory(devicePixelRatio: ratio);
      if (mounted && _iconRatio == ratio) {
        setState(() {
          _icon = icon;
          _staleIcon = stale;
        });
      }
    } catch (e) {
      debugPrint('[AnimatedVanMarker] van icon failed, using the pin: $e');
    }
  }

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<VanPose?>(
        valueListenable: _animator.pose,
        builder: (context, pose, _) => widget.builder(
          context,
          pose == null
              ? const <Marker>{}
              : {
                  Marker(
                    markerId: widget.markerId,
                    position: pose.position,
                    rotation: pose.rotation,
                    flat: true,
                    anchor: const Offset(0.5, 0.5),
                    zIndex: 1,
                    alpha: widget.stale ? 0.55 : 1.0,
                    icon: (widget.stale ? _staleIcon ?? _icon : _icon) ??
                        BitmapDescriptor.defaultMarkerWithHue(
                            BitmapDescriptor.hueBlue),
                    infoWindow: InfoWindow(title: widget.title),
                  ),
                },
        ),
      );
}
