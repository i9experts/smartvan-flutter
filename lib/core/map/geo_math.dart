import 'dart:math' as math;
import 'package:google_maps_flutter/google_maps_flutter.dart';

const _earthRadiusMeters = 6371000.0;

double _rad(double deg) => deg * math.pi / 180;
double _deg(double rad) => rad * 180 / math.pi;

/// Great-circle distance between [a] and [b] in metres (haversine).
double distanceMeters(LatLng a, LatLng b) {
  final dLat = _rad(b.latitude - a.latitude);
  final dLng = _rad(b.longitude - a.longitude);
  final h = math.pow(math.sin(dLat / 2), 2) +
      math.cos(_rad(a.latitude)) *
          math.cos(_rad(b.latitude)) *
          math.pow(math.sin(dLng / 2), 2);
  return 2 * _earthRadiusMeters * math.asin(math.sqrt(h.toDouble()));
}

/// Initial compass bearing from [a] to [b] in degrees, 0 = north, clockwise,
/// in [0, 360).
double bearingDegrees(LatLng a, LatLng b) {
  final lat1 = _rad(a.latitude);
  final lat2 = _rad(b.latitude);
  final dLng = _rad(b.longitude - a.longitude);
  final y = math.sin(dLng) * math.cos(lat2);
  final x = math.cos(lat1) * math.sin(lat2) -
      math.sin(lat1) * math.cos(lat2) * math.cos(dLng);
  return normalizeDegrees(_deg(math.atan2(y, x)));
}

/// [degrees] folded into [0, 360).
double normalizeDegrees(double degrees) => (degrees % 360 + 360) % 360;

/// The signed turn from [from] to [to] along the shorter way, in
/// (-180, 180]. 350° → 10° is +20, not -340.
double shortestTurn(double from, double to) {
  final d = normalizeDegrees(to - from);
  return d > 180 ? d - 360 : d;
}

/// [from] turned towards [to] by [t] (0..1) the short way, in [0, 360).
double lerpDegrees(double from, double to, double t) =>
    normalizeDegrees(from + shortestTurn(from, to) * t);

/// Straight-line blend of two coordinates; fine over the few metres between
/// two GPS fixes.
LatLng lerpLatLng(LatLng a, LatLng b, double t) => LatLng(
      a.latitude + (b.latitude - a.latitude) * t,
      a.longitude + (b.longitude - a.longitude) * t,
    );
