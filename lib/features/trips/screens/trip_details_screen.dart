import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../core/network/api_errors.dart';
import '../../tracking/tracking_map_layers.dart';
import '../trips_api.dart';

const _navy = Color(0xFF1B3B69);
const _yellow = Color(0xFFFEC610);

/// A finished trip: the route the van actually drove plus its facts.
/// Read-only — no socket. Shows every one of the parent's children on it.
class TripDetailsScreen extends StatefulWidget {
  const TripDetailsScreen({super.key, required this.tripId});

  final String tripId;

  @override
  State<TripDetailsScreen> createState() => _TripDetailsScreenState();
}

class _TripDetailsScreenState extends State<TripDetailsScreen> {
  CompletedTrip? _trip;
  TripTrail _trail = const TripTrail([]);
  Map<String, LatLng> _stops = {};
  String? _error;
  bool _loading = true;
  GoogleMapController? _map;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final trip = await TripsApi.details(widget.tripId);
      // The trail and the stop are extras: the screen works without them.
      final extras = await Future.wait<Object?>([
        TripsApi.trail(widget.tripId).catchError((_) => const TripTrail([])),
        TripsApi.kidStops({for (final c in trip.children) c.kidId})
            .catchError((_) => <String, LatLng>{}),
      ]);
      if (!mounted) return;
      setState(() {
        _trip = trip;
        _trail = extras[0] as TripTrail;
        _stops = extras[1] as Map<String, LatLng>;
      });
    } catch (e) {
      if (mounted) setState(() => _error = ApiErrors.message(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<LatLng> get _allPoints => [
        ..._trail.path,
        ..._stops.values,
        if (_trip?.school != null) _trip!.school!.point,
      ];

  void _fit() {
    final bounds = boundsOfPoints(_allPoints);
    if (bounds == null || _map == null) return;
    final same = bounds.southwest == bounds.northeast;
    _map!
        .animateCamera(same
            ? CameraUpdate.newLatLngZoom(bounds.southwest, 15)
            : CameraUpdate.newLatLngBounds(bounds, 56))
        .catchError((Object e) => debugPrint('Trip fit failed: $e'));
  }

  Set<Marker> _markers() {
    final p = _trail.path;
    return {
      if (!_trail.isEmpty) ...{
        Marker(
            markerId: const MarkerId('start'),
            position: p.first,
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
            infoWindow: const InfoWindow(title: 'Trip start')),
        Marker(
            markerId: const MarkerId('end'),
            position: p.last,
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
            infoWindow: const InfoWindow(title: 'Trip end')),
      },
      for (final c in _trip?.children ?? const <TripChild>[])
        if (_stops[c.kidId] != null)
          Marker(
              markerId: MarkerId('stop-${c.kidId}'),
              position: _stops[c.kidId]!,
              icon: BitmapDescriptor.defaultMarkerWithHue(
                  BitmapDescriptor.hueGreen),
              infoWindow: InfoWindow(title: "${c.name}'s stop")),
      if (_trip?.school != null)
        Marker(
            markerId: const MarkerId('school'),
            position: _trip!.school!.point,
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
            infoWindow: InfoWindow(title: _trip!.school!.name)),
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: _navy,
        foregroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        title: const Text('Trip Details',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                fontFamily: 'Poppins')),
      ),
      body: SafeArea(top: false, child: _body()),
    );
  }

  Widget _body() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    final trip = _trip;
    if (trip == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.cloud_off, size: 48, color: Color(0xFF8A94A6)),
            const SizedBox(height: 12),
            Text(_error ?? 'Could not load this trip.',
                textAlign: TextAlign.center),
            TextButton(onPressed: _load, child: const Text('Try again')),
          ]),
        ),
      );
    }
    final hasMap = _allPoints.isNotEmpty;
    return Column(
      children: [
        SizedBox(
          height: 280,
          child: hasMap ? _mapView() : _noTrail(),
        ),
        if (hasMap && _trail.isEmpty) _noTrailNote(),
        Expanded(child: _info(trip)),
      ],
    );
  }

  Widget _mapView() => GoogleMap(
        initialCameraPosition: CameraPosition(target: _allPoints.first, zoom: 14),
        polylines: {
          if (!_trail.isEmpty)
            Polyline(
              polylineId: const PolylineId('trail'),
              points: _trail.path,
              color: _navy,
              width: 5,
              jointType: JointType.round,
              startCap: Cap.roundCap,
              endCap: Cap.roundCap,
            ),
        },
        markers: _markers(),
        zoomControlsEnabled: false,
        myLocationButtonEnabled: false,
        mapToolbarEnabled: false,
        onMapCreated: (c) {
          _map = c;
          // Wait a frame: fitting before layout has no size to fit into.
          WidgetsBinding.instance.addPostFrameCallback((_) => _fit());
        },
      );

  Widget _noTrail() => Container(
        color: const Color(0xFFE8ECF3),
        alignment: Alignment.center,
        child: const Text('Route map not available for this trip',
            style: TextStyle(color: Color(0xFF8A94A6))),
      );

  Widget _noTrailNote() => Container(
        width: double.infinity,
        color: _yellow.withValues(alpha: 0.2),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: const Text('The driven route was not recorded for this trip.',
            style: TextStyle(fontSize: 12, color: _navy)),
      );

  Widget _info(CompletedTrip trip) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _section('Trip', [
          _row('Route', '${trip.routeName} (${tripTypeLabel(trip.tripType)})'),
          _row('Date', pktDate(trip.endedAt ?? trip.startedAt)),
          _row('Started', pktTime(trip.startedAt)),
          _row('Ended', pktTime(trip.endedAt)),
          _row('Duration', durationText(trip.durationSeconds)),
          _row('Distance', distanceText(trip.distanceMeters)),
        ]),
        const SizedBox(height: 12),
        _section('Driver & van', [
          _row('Driver', trip.driverName ?? '—'),
          _row('Van', trip.vanNumber ?? '—'),
        ]),
        const SizedBox(height: 12),
        for (final c in trip.children) ...[
          _section(c.name, [
            _row(trip.tripType == 'drop' ? 'Drop time' : 'Pickup time',
                c.at == null ? '—' : pktTime(c.at)),
            _row('Status', childStatusLabel(c.status)),
          ]),
          const SizedBox(height: 12),
        ],
      ],
    );
  }

  Widget _section(String title, List<Widget> rows) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(14)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 14, color: _navy)),
            const SizedBox(height: 8),
            ...rows,
          ],
        ),
      );

  Widget _row(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
                width: 96,
                child: Text(label,
                    style: const TextStyle(
                        fontSize: 13, color: Color(0xFF8A94A6)))),
            Expanded(
                child: Text(value,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600))),
          ],
        ),
      );
}
