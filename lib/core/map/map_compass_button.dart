import 'package:flutter/material.dart';
import 'geo_math.dart';

/// A round, Google-Maps-style compass button: the needle always points to
/// north (it turns by minus the map's [bearing], smoothly), and tapping it
/// does [onPressed] (north up / heading up — decided by the caller).
///
/// In heading-up mode ([headingUp]) the needle is replaced by a navigation
/// arrow. [semanticLabel] tells a screen reader what a tap does.
class MapCompassButton extends StatefulWidget {
  const MapCompassButton({
    super.key,
    required this.bearing,
    required this.onPressed,
    required this.semanticLabel,
    this.headingUp = false,
  });

  /// The map's bearing in degrees (clockwise from north).
  final double bearing;
  final VoidCallback onPressed;
  final String semanticLabel;
  final bool headingUp;

  static const size = 48.0;

  @override
  State<MapCompassButton> createState() => _MapCompassButtonState();
}

class _MapCompassButtonState extends State<MapCompassButton> {
  /// The needle's turn in full turns, kept continuous (359° → 1° is +2°, not
  /// −358°) so the animation takes the short way.
  late double _turns;
  late double _lastBearing;

  @override
  void initState() {
    super.initState();
    _turns = -widget.bearing / 360;
    _lastBearing = widget.bearing;
  }

  @override
  void didUpdateWidget(MapCompassButton old) {
    super.didUpdateWidget(old);
    if (widget.bearing != _lastBearing) {
      _turns -= shortestTurn(_lastBearing, widget.bearing) / 360;
      _lastBearing = widget.bearing;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: widget.semanticLabel,
      excludeSemantics: true,
      onTap: widget.onPressed,
      child: Material(
        color: Colors.white,
        elevation: 3,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: widget.onPressed,
          child: SizedBox(
            width: MapCompassButton.size,
            height: MapCompassButton.size,
            child: Center(
              child: widget.headingUp
                  ? const Icon(Icons.navigation,
                      key: Key('compass-heading-up'),
                      size: 26,
                      color: Color(0xFF1B3B69))
                  : AnimatedRotation(
                      key: const Key('compass-needle'),
                      turns: _turns,
                      duration: const Duration(milliseconds: 150),
                      child: const CustomPaint(
                        size: Size(22, 30),
                        painter: _NeedlePainter(),
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A diamond needle: the north half red, the south half grey.
class _NeedlePainter extends CustomPainter {
  const _NeedlePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final north = Path()
      ..moveTo(cx, 0)
      ..lineTo(size.width, cy)
      ..lineTo(0, cy)
      ..close();
    final south = Path()
      ..moveTo(cx, size.height)
      ..lineTo(size.width, cy)
      ..lineTo(0, cy)
      ..close();
    canvas.drawPath(north, Paint()..color = const Color(0xFFE53935));
    canvas.drawPath(south, Paint()..color = const Color(0xFFB0B7C3));
  }

  @override
  bool shouldRepaint(_NeedlePainter old) => false;
}
