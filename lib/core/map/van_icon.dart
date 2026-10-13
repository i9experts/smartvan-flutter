import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Edge of the (square) van icon in logical pixels.
const vanIconLogicalSize = 48.0;

/// A van seen from above, nose pointing up (north at rotation 0).
class VanIconPainter extends CustomPainter {
  const VanIconPainter({this.body = const Color(0xFF1B3B69)});

  final Color body;

  @override
  void paint(Canvas canvas, Size size) {
    // Drawn on a 48 x 48 grid and scaled to whatever size it gets.
    canvas.save();
    canvas.scale(
        size.width / vanIconLogicalSize, size.height / vanIconLogicalSize);

    final fill = Paint()..style = PaintingStyle.fill;

    // Soft ground shadow.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          const Rect.fromLTWH(12, 5, 24, 40), const Radius.circular(8)),
      fill..color = Colors.black.withValues(alpha: 0.18),
    );

    // Wheels, poking out of the sides.
    fill.color = const Color(0xFF14171F);
    for (final y in const [10.0, 31.0]) {
      canvas.drawRRect(
          RRect.fromRectAndRadius(
              Rect.fromLTWH(11, y, 3, 8), const Radius.circular(1.5)),
          fill);
      canvas.drawRRect(
          RRect.fromRectAndRadius(
              Rect.fromLTWH(34, y, 3, 8), const Radius.circular(1.5)),
          fill);
    }

    // Mirrors.
    fill.color = body;
    canvas.drawCircle(const Offset(11.5, 13), 1.6, fill);
    canvas.drawCircle(const Offset(36.5, 13), 1.6, fill);

    // Body with a white edge so it reads on any map colour.
    final bodyRect = RRect.fromRectAndRadius(
        const Rect.fromLTWH(13, 3, 22, 42), const Radius.circular(7));
    canvas.drawRRect(bodyRect, fill..color = Colors.white);
    canvas.drawRRect(bodyRect.deflate(1.4), fill..color = body);

    // Windscreen (front, top) and rear window (bottom).
    fill.color = const Color(0xFF9FD3FF);
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            const Rect.fromLTWH(16, 8, 16, 7), const Radius.circular(3)),
        fill);
    fill.color = const Color(0xFF6FA8DC);
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            const Rect.fromLTWH(17, 38, 14, 4), const Radius.circular(2)),
        fill);

    // Roof panel.
    fill.color = Colors.white.withValues(alpha: 0.16);
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            const Rect.fromLTWH(17, 18, 14, 18), const Radius.circular(3)),
        fill);

    // Headlights.
    fill.color = const Color(0xFFFFD84D);
    canvas.drawCircle(const Offset(17.5, 5.6), 1.4, fill);
    canvas.drawCircle(const Offset(30.5, 5.6), 1.4, fill);

    canvas.restore();
  }

  @override
  bool shouldRepaint(VanIconPainter old) => old.body != body;
}

/// Draws the van at [devicePixelRatio] times its logical size, so it stays
/// sharp on every screen, and wraps it as a map marker icon of
/// [vanIconLogicalSize] logical pixels.
Future<BitmapDescriptor> createVanIcon(
    {required double devicePixelRatio}) async {
  final pixels = (vanIconLogicalSize * devicePixelRatio).round();
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  const VanIconPainter()
      .paint(canvas, Size(pixels.toDouble(), pixels.toDouble()));
  final image = await recorder.endRecording().toImage(pixels, pixels);
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  return BytesMapBitmap(
    bytes!.buffer.asUint8List(),
    imagePixelRatio: devicePixelRatio,
  );
}
