import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// The planned road ahead: bright blue on a white outline, so it reads on
/// every map colour.
const plannedLineColor = Color(0xFF2563EB);

/// Where the van has been: thinner and quieter than the planned line.
const trailLineColor = Color(0xFF64748B);

/// Planned line (white outline + blue, solid), then the driven trail on top.
/// With no road path yet, a thin dashed blue line from the van to the stop
/// stands in for it.
Set<Polyline> trackingPolylines({
  required List<LatLng> plannedPath,
  required List<LatLng> trail,
  required LatLng van,
  required LatLng stop,
}) {
  return {
    if (plannedPath.length > 1) ...{
      Polyline(
        polylineId: const PolylineId('planned-outline'),
        points: plannedPath,
        color: Colors.white,
        width: 10,
        zIndex: 1,
        jointType: JointType.round,
        startCap: Cap.roundCap,
        endCap: Cap.roundCap,
      ),
      Polyline(
        polylineId: const PolylineId('planned'),
        points: plannedPath,
        color: plannedLineColor,
        width: 6,
        zIndex: 2,
        jointType: JointType.round,
        startCap: Cap.roundCap,
        endCap: Cap.roundCap,
      ),
    } else
      Polyline(
        polylineId: const PolylineId('planned'),
        points: [van, stop],
        color: plannedLineColor,
        width: 3,
        zIndex: 2,
        patterns: [PatternItem.dash(20), PatternItem.gap(10)],
      ),
    if (trail.length > 1)
      Polyline(
        polylineId: const PolylineId('trail'),
        points: List.of(trail),
        color: trailLineColor,
        width: 3,
        zIndex: 3,
        jointType: JointType.round,
      ),
  };
}

/// Everything the parent wants in view at once: the van, their child's stop,
/// the school and the planned line. Null when there is nothing to fit.
LatLngBounds? boundsOfPoints(Iterable<LatLng> points) {
  double? south, north, west, east;
  for (final p in points) {
    south = south == null || p.latitude < south ? p.latitude : south;
    north = north == null || p.latitude > north ? p.latitude : north;
    west = west == null || p.longitude < west ? p.longitude : west;
    east = east == null || p.longitude > east ? p.longitude : east;
  }
  if (south == null) return null;
  return LatLngBounds(
      southwest: LatLng(south, west!), northeast: LatLng(north!, east!));
}

/// "5 min (1:23 PM)". The server sends the clock time already in Pakistan
/// time; "N/A" or nothing means no time to show. One minute or less is
/// "Arriving now".
String etaText(int minutes, String? etaTime) {
  if (minutes <= 1) return 'Arriving now';
  final hasTime = etaTime != null && etaTime.isNotEmpty && etaTime != 'N/A';
  return '$minutes min${hasTime ? ' ($etaTime)' : ''}';
}
