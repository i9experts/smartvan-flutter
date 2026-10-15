import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import '../../core/network/api_errors.dart';
import '../../core/network/api_service.dart';

/// Pakistan has no daylight saving, so PKT is always UTC+5.
const pktOffset = Duration(hours: 5);

DateTime? parseIso(Object? v) {
  if (v is! String || v.isEmpty) return null;
  return DateTime.tryParse(v)?.toUtc();
}

/// "2:05 PM" in Pakistan time, or "—".
String pktTime(DateTime? utc) =>
    utc == null ? '—' : DateFormat('h:mm a').format(utc.add(pktOffset));

/// "15 Oct 2026" in Pakistan time, or "—".
String pktDate(DateTime? utc) =>
    utc == null ? '—' : DateFormat('d MMM yyyy').format(utc.add(pktOffset));

/// "41 min", "1 h 5 min".
String durationText(int seconds) {
  final m = (seconds / 60).round();
  if (m < 60) return '$m min';
  return m % 60 == 0 ? '${m ~/ 60} h' : '${m ~/ 60} h ${m % 60} min';
}

String distanceText(num meters) => meters < 1000
    ? '${meters.round()} m'
    : '${(meters / 1000).toStringAsFixed(1)} km';

String tripTypeLabel(String type) => type == 'drop' ? 'Drop' : 'Pick';

String childStatusLabel(String status) {
  switch (status) {
    case 'picked':
      return 'Picked up';
    case 'dropped':
      return 'Dropped off';
    case 'absent':
      return 'Absent';
    case 'no_show':
      return 'Not at stop';
    default:
      return 'Pending';
  }
}

class TripChild {
  final String kidId;
  final String name;
  final String status;
  final DateTime? at;
  const TripChild(
      {required this.kidId, required this.name, required this.status, this.at});

  factory TripChild.fromJson(Map j) => TripChild(
        kidId: j['kidId']?.toString() ?? '',
        name: j['name']?.toString() ?? 'Child',
        status: j['status']?.toString() ?? 'pending',
        at: parseIso(j['at']),
      );
}

class TripSchool {
  final String name;
  final LatLng point;
  const TripSchool(this.name, this.point);
}

class CompletedTrip {
  final String id;
  final String routeName;
  final String tripType;
  final DateTime? startedAt;
  final DateTime? endedAt;
  final int durationSeconds;
  final int distanceMeters;
  final List<TripChild> children;
  final String? driverName;
  final String? vanNumber;
  final TripSchool? school;

  const CompletedTrip({
    required this.id,
    required this.routeName,
    required this.tripType,
    this.startedAt,
    this.endedAt,
    this.durationSeconds = 0,
    this.distanceMeters = 0,
    this.children = const [],
    this.driverName,
    this.vanNumber,
    this.school,
  });

  factory CompletedTrip.fromJson(Map j) {
    final s = j['school'];
    final lat = s is Map ? (s['lat'] as num?)?.toDouble() : null;
    final lng = s is Map ? (s['lng'] as num?)?.toDouble() : null;
    return CompletedTrip(
      id: j['id']?.toString() ?? '',
      routeName: j['routeName']?.toString() ?? 'Trip',
      tripType: j['tripType']?.toString() ?? 'pick',
      startedAt: parseIso(j['startedAt']),
      endedAt: parseIso(j['endedAt']),
      durationSeconds: (j['durationSeconds'] as num?)?.toInt() ?? 0,
      distanceMeters: (j['distanceMeters'] as num?)?.toInt() ?? 0,
      children: (j['children'] is List ? j['children'] as List : const [])
          .whereType<Map>()
          .map(TripChild.fromJson)
          .toList(),
      driverName: j['driverName']?.toString(),
      vanNumber: j['vanNumber']?.toString(),
      school: lat != null && lng != null && (lat != 0 || lng != 0)
          ? TripSchool(s['name']?.toString() ?? 'School', LatLng(lat, lng))
          : null,
    );
  }

  CompletedTrip withDriver(CompletedTrip details) => CompletedTrip(
        id: id,
        routeName: routeName,
        tripType: tripType,
        startedAt: startedAt,
        endedAt: endedAt,
        durationSeconds: durationSeconds,
        distanceMeters: distanceMeters,
        children: children,
        driverName: details.driverName,
        vanNumber: details.vanNumber,
        school: details.school,
      );
}

class TripPage {
  final List<CompletedTrip> items;
  final bool hasMore;
  const TripPage(this.items, this.hasMore);
}

/// Where the van really went, from GET /trips/:id/trail.
class TripTrail {
  final List<LatLng> path;
  const TripTrail(this.path);
  bool get isEmpty => path.length < 2;
}

class TripsApi {
  TripsApi._();

  static Map _data(dynamic body) =>
      body is Map ? (body['data'] is Map ? body['data'] as Map : body) : {};

  /// `scope`: "today" or "all".
  static Future<TripPage> completed(
      {String scope = 'all', int page = 1, int limit = 20}) async {
    final res = ApiErrors.ensureOk(await ApiService.get(
        '/parent/trips/completed?scope=$scope&page=$page&limit=$limit'));
    final d = _data(res.data);
    final items = (d['items'] is List ? d['items'] as List : const [])
        .whereType<Map>()
        .map(CompletedTrip.fromJson)
        .toList();
    return TripPage(items, d['hasMore'] == true);
  }

  static Future<CompletedTrip> details(String tripId) async {
    final res = ApiErrors.ensureOk(
        await ApiService.get('/parent/trips/$tripId/details'));
    return CompletedTrip.fromJson(_data(res.data));
  }

  /// An empty trail (not an error) when the trip has no saved points.
  static Future<TripTrail> trail(String tripId) async {
    final res =
        ApiErrors.ensureOk(await ApiService.get('/trips/$tripId/trail'));
    final path = _data(res.data)['path'];
    final points = <LatLng>[];
    if (path is List) {
      for (final p in path.whereType<Map>()) {
        final lat = (p['lat'] as num?)?.toDouble();
        final lng = (p['lng'] as num?)?.toDouble();
        if (lat != null && lng != null) points.add(LatLng(lat, lng));
      }
    }
    return TripTrail(points);
  }

  /// The saved home/pickup point of one of the parent's kids, if set.
  static Future<LatLng?> kidStop(String kidId) async {
    final res = ApiErrors.ensureOk(await ApiService.get('/kid/getKids'));
    final raw = res.data;
    final list = raw is List ? raw : (raw is Map ? (raw['data'] ?? raw['kids']) : null);
    if (list is! List) return null;
    for (final k in list.whereType<Map>()) {
      if ((k['_id'] ?? k['id'])?.toString() != kidId) continue;
      final lat = (k['homeLat'] as num?)?.toDouble();
      final lng = (k['homeLng'] as num?)?.toDouble();
      return lat != null && lng != null ? LatLng(lat, lng) : null;
    }
    return null;
  }
}
