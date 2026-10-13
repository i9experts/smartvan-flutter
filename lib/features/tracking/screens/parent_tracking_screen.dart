import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/map/animated_van_marker.dart';
import '../../../core/map/follow_camera.dart';
import '../../../core/map/polyline_codec.dart';
import '../../../core/network/api_service.dart';
import '../../../core/storage/token_storage.dart';
import '../../../core/widgets/skeletons/tracking_screen_skeleton.dart';
import '../socket_teardown.dart';
import '../tracking_freshness.dart';
import '../tracking_map_layers.dart';
import '../widgets/freshness_line.dart';

class TrackingScreen extends ConsumerStatefulWidget {
  const TrackingScreen({super.key});

  @override
  ConsumerState<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends ConsumerState<TrackingScreen>
    with WidgetsBindingObserver {
  GoogleMapController? _mapController;
  /// Follows the van (zoom ~15) once the parent asks; starts off, because the
  /// map first shows the whole route.
  final FollowCameraController _follow =
      FollowCameraController(following: false);
  static const _followZoom = 15.0;
  io.Socket? _socket;
  LatLng _vanPosition = const LatLng(24.8607, 67.0011);
  LatLng _homePosition = const LatLng(24.8700, 67.0100);
  /// False while [_homePosition] is only the placeholder.
  bool _homeKnown = false;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  /// Where the van has actually driven (GET /trail, then each locationUpdated).
  final List<LatLng> _trail = [];
  /// Road-following line from the van through the remaining stops.
  List<LatLng> _plannedPath = [];
  LatLng? _myStop;
  LatLng? _schoolPoint;
  String? _schoolName;
  Timer? _planTimer;
  String? _connectionError;
  /// True once the server confirmed 'joinedTrip' (we are in the trip room).
  bool _joinedTrip = false;
  bool _isLoading = true;
  bool _noActiveTrip = false;
  Map<String, dynamic>? _tripData;
  String? _currentTripId;
  String? _currentKidName;
  /// Latest socket 'tripStatus': moving | stopped | delayed (null until sent).
  String? _tripStatus;
  String _eta = 'Calculating...';
  /// This parent's kids on the current trip (for per-kid ETA).
  Set<String> _myKidIds = {};
  /// Driver SOS received on this trip (shown as a banner).
  Map<String, dynamic>? _driverSos;
  String _driverName = 'Driver';
  String _vanNumber = 'SV-001';
  double _vanSpeed = 0.0;
  bool _hasSpeed = false;
  /// Heading (degrees) of the latest fix, null when the server sent none.
  double? _vanHeading;
  /// Null until the van's position is known; the animated marker draws it.
  LatLng? _vanFix;

  /// Server time of the newest position applied (event `at`, or the last
  /// stored point at load). Drives "Updated N sec ago" and the signal state.
  DateTime? _lastUpdateAt;

  /// Drops duplicate / older location events (socket and HTTP relay both
  /// deliver now).
  final LocationEventGate _gate = LocationEventGate();

  /// Repaints the "Updated N sec ago" line and the live / weak / offline state
  /// every second without rebuilding the map.
  final ValueNotifier<DateTime> _clock = ValueNotifier(DateTime.now());
  Timer? _clockTimer;
  bool _stale = false;

  /// The socket connected before: a later connect is a reconnect, and the
  /// trail may have a gap.
  bool _connectedBefore = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
    _initTracking();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _clockTimer?.cancel();
    _clock.dispose();
    _planTimer?.cancel();
    _follow.dispose();
    tearDownSocket(_socket);
    _socket = null;
    _mapController?.dispose();
    super.dispose();
  }

  DriverSignal get _signal => driverSignal(
        now: DateTime.now(),
        lastAt: _lastUpdateAt,
        tripStatus: _tripStatus,
      );

  void _tick() {
    if (!mounted) return;
    _clock.value = DateTime.now();
    // The van icon greys out when the driver is offline.
    final stale = _signal == DriverSignal.offline;
    if (stale != _stale) setState(() => _stale = stale);
  }

  /// Back from the background: the socket may have been suspended, so what
  /// happened meanwhile is fetched again.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed || _currentTripId == null) return;
    final socket = _socket;
    if (socket != null && socket.connected != true) socket.connect();
    _refreshAfterGap();
  }

  /// Position, trail, planned line and ETA again — after the app was away or
  /// the socket reconnected, or the driver uploaded points recorded offline.
  Future<void> _refreshAfterGap() async {
    await _loadTripData();
    if (!mounted || _noActiveTrip) return;
    await Future.wait([_loadTrail(), _loadRoutePlan()]);
    _fetchEta();
  }

  Future<void> _initTracking() async {
    await _loadTripData();
    if (!mounted) return;
    await _loadHomeLocation();
    if (!mounted) return;
    if (_currentTripId != null) {
      _connectSocket();
      // One initial ETA; after that the server pushes 'etaUpdate'.
      _fetchEta();
      await Future.wait([_loadTrail(), _loadRoutePlan()]);
      _planTimer =
          Timer.periodic(const Duration(seconds: 60), (_) => _loadRoutePlan());
    }
    _setupMarkers();
    _rebuildPolylines();
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _loadTripData() async {
    try {
      final response = await ApiService.get('/kid/getActiveTripDetails');
      if (!mounted) return;
      if (response.statusCode == 200 && response.data != null) {
        final raw = response.data;
        final trips = (raw['data'] ?? []) as List;

        if (trips.isEmpty) {
          setState(() => _noActiveTrip = true);
          return;
        }

        final trip = Map<String, dynamic>.from(trips.first as Map);
        final locations = (trip['locations'] ?? []) as List;
        final lastLoc =
            locations.isNotEmpty ? Map<String, dynamic>.from(locations.last) : null;
        final kids = (trip['kids'] ?? []) as List;

        setState(() {
          _tripData = trip;
          _currentTripId = trip['tripId']?.toString();
          _driverName = trip['driverFullname'] ?? 'Driver';
          _vanNumber = trip['carNumber'] ?? 'SV-001';
          if (kids.isNotEmpty) {
            _currentKidName = Map<String, dynamic>.from(kids.first)['name'];
          }
          _myKidIds = kids
              .whereType<Map>()
              .map((k) => (k['id'] ?? k['kidId'])?.toString())
              .whereType<String>()
              .toSet();
          if (lastLoc != null) {
            final lat = lastLoc['lat'];
            final long = lastLoc['long'];
            if (lat != null && long != null) {
              _vanPosition = LatLng(
                (lat as num).toDouble(),
                (long as num).toDouble(),
              );
              _vanFix = _vanPosition;
            }
            final at = parseServerTime(lastLoc['time']);
            if (at != null) {
              _gate.seed(at);
              if (_lastUpdateAt == null || at.isAfter(_lastUpdateAt!)) {
                _lastUpdateAt = at;
              }
            }
          }
        });
      } else {
        setState(() => _noActiveTrip = true);
      }
    } catch (e) {
      if (mounted) setState(() => _noActiveTrip = true);
    }
  }

  /// Uses the kid's saved pickup-point (set via the map picker in Add Kid)
  /// as the home marker, instead of a hardcoded placeholder.
  Future<void> _loadHomeLocation() async {
    try {
      final response = await ApiService.get('/kid/getKids');
      final raw = response.data;
      final kids = (raw is List ? raw : (raw['data'] ?? raw['kids'] ?? [])) as List;

      final kidWithHome = kids.cast<Map>().firstWhere(
            (k) => k['homeLat'] != null && k['homeLng'] != null,
            orElse: () => {},
          );

      if (kidWithHome.isNotEmpty && mounted) {
        setState(() {
          _homePosition = LatLng(
            (kidWithHome['homeLat'] as num).toDouble(),
            (kidWithHome['homeLng'] as num).toDouble(),
          );
          _homeKnown = true;
        });
      }
    } catch (e) {
      // Falls back to the placeholder home position — non-fatal.
    }
  }

  void _connectSocket() async {
    final token = await TokenStorage.read() ?? '';
    // The screen was left while the token was being read.
    if (!mounted) return;

    _socket = io.io(
      AppConstants.socketUrl,
      io.OptionBuilder()
          .setTransports(['websocket', 'polling'])
          .setAuth({'token': token})
          // connect() is called once below; auto-connect as well made the
          // socket open twice and time out.
          .disableAutoConnect()
          .enableReconnection()
          .setReconnectionAttempts(double.infinity)
          .setReconnectionDelay(2000)
          .build(),
    );

    _socket!.onConnect((_) {
      debugPrint('Tracking socket connected, joining trip $_currentTripId');
      if (mounted) {
        setState(() {
          _connectionError = null;
        });
      }
      if (_currentTripId != null) {
        _socket!.emit('joinTrip', {'tripId': _currentTripId});
      }
      // A reconnect: events were missed while the socket was down.
      if (_connectedBefore) _refreshAfterGap();
      _connectedBefore = true;
    });

    _socket!.on('joinedTrip', (data) {
      debugPrint('Tracking socket joinedTrip: $data');
      if (mounted) {
        setState(() {
          _joinedTrip = true;
          _connectionError = null;
        });
      }
    });

    // Server pushes per-kid ETA after each van update (computed at most
    // once a minute), so the app no longer calls the ETA API itself.
    _socket!.on('etaUpdate', (data) {
      if (data is! Map || !mounted) return;
      final list = data['eta'];
      if (list is! List) return;
      final mine = list
          .whereType<Map>()
          .where((e) => _myKidIds.contains(e['kidId']?.toString()))
          .toList();
      if (mine.isEmpty) return;
      mine.sort((a, b) =>
          ((a['minutes'] as num?) ?? 999).compareTo((b['minutes'] as num?) ?? 999));
      final m = (mine.first['minutes'] as num?)?.toInt();
      final t = mine.first['etaTime']?.toString();
      if (m == null) return;
      setState(() => _eta = etaText(m, t));
    });

    // Emergency raised by the driver (Phase 2 driver SOS).
    _socket!.on('tripStatus', (data) {
      if (data is! Map || !mounted) return;
      final seen = parseServerTime(data['lastSeenAt']);
      setState(() {
        _tripStatus = data['status']?.toString();
        if (seen != null &&
            (_lastUpdateAt == null || seen.isAfter(_lastUpdateAt!))) {
          _lastUpdateAt = seen;
        }
      });
    });

    // The driver's phone uploaded points it recorded while offline.
    _socket!.on('trailBackfilled', (data) {
      if (!mounted) return;
      _loadTrail();
      _loadRoutePlan();
    });

    _socket!.on('sosAlert', (data) {
      if (data is! Map || !mounted) return;
      if (data['source'] != 'driver') return;
      setState(() => _driverSos = Map<String, dynamic>.from(data));
    });

    _socket!.onDisconnect((_) {
      if (mounted) {
        setState(() {
          _joinedTrip = false;
        });
      }
    });

    _socket!.onConnectError((data) {
      debugPrint('Tracking socket connect_error: $data');
      if (mounted) {
        setState(() {
            _connectionError = _friendlyError(data);
        });
      }
    });

    _socket!.onConnectTimeout((data) {
      debugPrint('Tracking socket connect_timeout: $data');
      if (mounted) {
        setState(() {
            _connectionError = 'Connection timed out';
        });
      }
    });

    _socket!.on('error', (data) {
      // joinTrip refusals ('Not authorized…', 'Trip not found') arrive here.
      debugPrint('Tracking socket error: $data');
      if (mounted) {
        setState(() {
          _joinedTrip = false;
          _connectionError = _friendlyError(data);
        });
      }
    });

    _socket!.on('locationUpdated', (data) {
      if (data == null || !mounted) return;
      final location = data['location'];
      if (location == null) return;

      final lat = double.tryParse(location['lat'].toString());
      final long = double.tryParse(location['long'].toString());
      if (lat == null || long == null) return;

      // Socket and HTTP relay can both deliver a point, and a reconnect can
      // replay old ones: apply only what is newer than what the map shows.
      final at = parseServerTime(data['at']);
      if (!_gate.accept(at)) return;

      final newPosition = LatLng(lat, long);
      final speedKmh = (data['speedKmh'] as num?)?.toDouble();
      final heading = (data['heading'] as num?)?.toDouble();

      setState(() {
        _lastUpdateAt = at ?? DateTime.now();
        _vanPosition = newPosition;
        _vanFix = newPosition;
        _vanHeading = heading;
        _hasSpeed = speedKmh != null;
        if (speedKmh != null) _vanSpeed = speedKmh;
      });
      _trail.add(newPosition);
      _rebuildPolylines();
    });

    _socket!.connect();
  }

  /// Server errors are `{ msg }` maps; anything else is shown as text.
  String _friendlyError(dynamic data) {
    if (data is Map && data['msg'] != null) return data['msg'].toString();
    final text = data?.toString() ?? '';
    return text.isEmpty ? 'Could not connect to live tracking' : text;
  }

  Widget _buildDriverSosBanner() {
    final schoolPhone = _tripData?['schoolContact']?.toString();
    final driverPhone = _tripData?['driverPhoneNo']?.toString();
    Widget call(String label, String? phone) => phone == null || phone.isEmpty
        ? const SizedBox.shrink()
        : TextButton(
            onPressed: () => launchUrl(Uri(scheme: 'tel', path: phone)),
            style: TextButton.styleFrom(foregroundColor: Colors.white),
            child: Text(label),
          );
    return Material(
      color: const Color(0xFFE53935),
      borderRadius: BorderRadius.circular(14),
      elevation: 6,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 10, 4, 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: Colors.white),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text('The driver raised an emergency alert',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Poppins')),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => setState(() => _driverSos = null),
                ),
              ],
            ),
            const Text('The school has been informed and has the van\'s location.',
                style: TextStyle(color: Colors.white, fontSize: 12, fontFamily: 'Poppins')),
            Row(
              children: [
                call('Call school', schoolPhone),
                call('Call driver', driverPhone),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String get _statusLabel => statusLabel(_signal, _tripStatus);

  Color get _statusColor => Color(statusColorValue(_signal, _tripStatus));

  Widget _buildDelayBanner() {
    return Material(
      color: const Color(0xFFFFF3E0),
      borderRadius: BorderRadius.circular(12),
      elevation: 2,
      child: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Icon(Icons.traffic_rounded, color: Color(0xFFE67E22), size: 18),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'The van is delayed in traffic. ETA may be later than usual.',
                style: TextStyle(
                    color: Color(0xFF8A4B08),
                    fontSize: 12,
                    fontFamily: 'Poppins'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectionBanner() {
    return Material(
      color: const Color(0xFFE53935),
      borderRadius: BorderRadius.circular(12),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            const Icon(Icons.wifi_off_rounded, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Live tracking unavailable: $_connectionError',
                style: const TextStyle(
                    color: Colors.white, fontSize: 12, fontFamily: 'Poppins'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _fetchEta() async {
    if (_currentTripId == null) return;
    try {
      final response = await ApiService.get(
        '/trips/eta/$_currentTripId?lat=${_vanPosition.latitude}&lng=${_vanPosition.longitude}',
      );
      if (response.statusCode == 200) {
        final etaList = ((response.data['eta'] ?? []) as List)
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
        if (etaList.isEmpty) return;

        final match = _currentKidName != null
            ? etaList.firstWhere(
                (e) => e['destinationName'] == _currentKidName,
                orElse: () => etaList.first,
              )
            : etaList.first;

        if (mounted) {
          setState(() => _eta = match['durationText'] ?? 'Calculating...');
        }
      }
    } catch (e) {
      // Non-fatal — ETA just won't update this cycle.
    }
  }

  void _setupMarkers() {
    if (!mounted) return;
    setState(() {
      _markers = {
        Marker(
          markerId: const MarkerId('home'),
          position: _myStop ?? _homePosition,
          icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueGreen),
          infoWindow: InfoWindow(
            title: _currentKidName != null
                ? '$_currentKidName\'s stop'
                : 'Your Home',
            snippet: 'Pickup / drop-off point',
          ),
        ),
        if (_schoolPoint != null)
          Marker(
            markerId: const MarkerId('school'),
            position: _schoolPoint!,
            icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueOrange),
            infoWindow: InfoWindow(title: _schoolName ?? 'School'),
          ),
      };
    });
  }

  Future<void> _loadTrail() async {
    try {
      final r = await ApiService.get('/trips/$_currentTripId/trail');
      final data = r.data is Map ? (r.data['data'] ?? r.data) : null;
      final poly = data is Map ? data['polyline']?.toString() : null;
      if (poly == null || poly.isEmpty || !mounted) return;
      _trail
        ..clear()
        ..addAll(decodePolyline(poly));
      _rebuildPolylines();
    } catch (e) {
      debugPrint('Tracking trail failed: $e');
    }
  }

  /// Own child's stop, the school and the road line still to drive.
  Future<void> _loadRoutePlan() async {
    if (_currentTripId == null) return;
    try {
      final r = await ApiService.get('/trips/$_currentTripId/route-plan');
      final data = r.data is Map ? (r.data['data'] ?? r.data) : null;
      if (data is! Map || !mounted) return;
      LatLng? point(dynamic m) {
        if (m is! Map) return null;
        final lat = (m['lat'] as num?)?.toDouble();
        final lng = ((m['lng'] ?? m['long']) as num?)?.toDouble();
        // The server sends 0,0 for stops/schools that have no coordinates yet.
        if (lat == null || lng == null || (lat == 0 && lng == 0)) return null;
        return LatLng(lat, lng);
      }

      final stops = (data['stops'] as List? ?? []).whereType<Map>();
      final mine = stops
          .where((s) => s['mine'] == true && point(s) != null)
          .toList();
      final school = data['school'];
      final poly = (data['plannedPath'] as Map?)?['polyline']?.toString();
      _myStop = mine.isEmpty ? null : point(mine.first);
      _schoolPoint = point(school);
      _schoolName = school is Map ? school['name']?.toString() : null;
      _plannedPath = poly == null || poly.isEmpty ? [] : decodePolyline(poly);
      _setupMarkers();
      _rebuildPolylines();
    } catch (e) {
      debugPrint('Tracking route-plan failed: $e');
    }
  }

  void _rebuildPolylines() {
    if (!mounted) return;
    setState(() {
      _polylines = trackingPolylines(
        plannedPath: _plannedPath,
        trail: _trail,
        van: _vanPosition,
        stop: _myStop ?? _homePosition,
      );
    });
  }

  /// Back to the van at zoom ~15 and follow it from here on.
  void _centerOnVan() => _follow.recenter();

  /// The van, the child's stop, the school and the planned line, all in view
  /// above the info card (the map's bottom padding keeps that space free).
  /// Leaves follow mode — the parent is looking at the whole route.
  void _fitAll() {
    final map = _mapController;
    if (map == null) return;
    final points = <LatLng>[
      _vanPosition,
      if (_myStop != null) _myStop!,
      if (_myStop == null && _homeKnown) _homePosition,
      if (_schoolPoint != null) _schoolPoint!,
      ..._plannedPath,
    ];
    _follow.pause();
    final bounds = boundsOfPoints(points);
    if (bounds == null ||
        (bounds.southwest.latitude == bounds.northeast.latitude &&
            bounds.southwest.longitude == bounds.northeast.longitude)) {
      map.animateCamera(CameraUpdate.newCameraPosition(
          CameraPosition(target: _vanPosition, zoom: _followZoom, tilt: 0)));
      return;
    }
    map
        .animateCamera(CameraUpdate.newLatLngBounds(bounds, 60))
        .catchError((Object e) => debugPrint('Tracking fit failed: $e'));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: Column(
        children: [
          // Header
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF1B3B69), Color(0xFF2D4099)],
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Live Tracking',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: _noActiveTrip
                                ? const Color(0xFF8A94A6)
                                : _joinedTrip
                                    ? const Color(0xFF27AE60)
                                    : const Color(0xFFFF4B4B),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _noActiveTrip
                              ? 'No active trip'
                              : _joinedTrip
                              ? 'Live'
                              : (_connectionError != null
                                  ? 'Connection failed'
                                  : 'Connecting...'),
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Map
          Expanded(
            child: _isLoading
                ? const TrackingScreenSkeleton()
                : _noActiveTrip
                    ? _buildNoActiveTripState()
                    : Stack(
                    children: [
                      AnimatedVanMarker(
                        position: _vanFix,
                        headingDegrees: _vanHeading,
                        stale: _stale,
                        speedMetersPerSecond: _hasSpeed ? _vanSpeed / 3.6 : null,
                        title: 'SmartVan - $_vanNumber',
                        onPose: _follow.onPose,
                        builder: (context, vanMarkers) => Listener(
                          // Touching the map means the parent is looking around.
                          behavior: HitTestBehavior.translucent,
                          onPointerDown: (_) => _follow.userMoved(),
                          child: GoogleMap(
                          initialCameraPosition: CameraPosition(
                            target: _vanPosition,
                            zoom: 14,
                            tilt: 0,
                          ),
                          onMapCreated: (controller) {
                            _mapController = controller;
                            _follow.attachMap(controller,
                                recenterZoom: _followZoom);
                            Future.delayed(
                                const Duration(milliseconds: 500), _fitAll);
                          },
                          tiltGesturesEnabled: false,
                          // Keeps the van and the camera centre above the info card.
                          padding: const EdgeInsets.only(bottom: 300),
                          markers: {..._markers, ...vanMarkers},
                          polylines: _polylines,
                          myLocationEnabled: true,
                          myLocationButtonEnabled: false,
                          zoomControlsEnabled: false,
                          mapToolbarEnabled: false,
                          ),
                        ),
                      ),

                      if (_connectionError != null && !_joinedTrip)
                        Positioned(
                          top: 12,
                          left: 12,
                          right: 72,
                          child: _buildConnectionBanner(),
                        ),

                      if (_tripStatus == 'delayed' &&
                          _connectionError == null &&
                          _driverSos == null)
                        Positioned(
                          top: 12,
                          left: 12,
                          right: 72,
                          child: _buildDelayBanner(),
                        ),

                      if (_driverSos != null)
                        Positioned(
                          top: 12,
                          left: 12,
                          right: 12,
                          child: _buildDriverSosBanner(),
                        ),

                      // Map Controls
                      Positioned(
                        right: 16,
                        top: 16,
                        child: Column(
                          children: [
                            _buildMapButton(
                              icon: Icons.my_location,
                              onTap: _centerOnVan,
                            ),
                            const SizedBox(height: 8),
                            _buildMapButton(
                              icon: Icons.fit_screen,
                              onTap: _fitAll,
                            ),
                          ],
                        ),
                      ),

                      // Offered once the parent moved the map away from the van.
                      Positioned(
                        right: 16,
                        bottom: 312,
                        child: ListenableBuilder(
                          listenable: _follow,
                          builder: (context, _) => _follow.showRecenter
                              ? FloatingActionButton.extended(
                                  heroTag: null,
                                  onPressed: _centerOnVan,
                                  backgroundColor: Colors.white,
                                  foregroundColor: const Color(0xFF1B3B69),
                                  icon: const Icon(Icons.my_location, size: 20),
                                  label: const Text(
                                    'Re-center',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      fontFamily: 'Poppins',
                                    ),
                                  ),
                                )
                              : const SizedBox.shrink(),
                        ),
                      ),

                      // Bottom Info Card
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: _buildInfoCard(),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoActiveTripState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: const Color(0xFF1B3B69).withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.directions_bus_filled_outlined,
                size: 42,
                color: Color(0xFF1B3B69),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'No Active Trip',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A2E),
                fontFamily: 'Poppins',
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Live tracking will appear here once the driver starts today\'s trip.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFF8A94A6),
                fontFamily: 'Poppins',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMapButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon, color: const Color(0xFF1B3B69), size: 20),
      ),
    );
  }

  /// The card repaints every second ([_clock]) so "Updated N sec ago" and the
  /// live / weak / offline state stay true without rebuilding the map.
  Widget _buildInfoCard() => ValueListenableBuilder<DateTime>(
        valueListenable: _clock,
        builder: (context, now, _) => _infoCard(now),
      );

  Widget _infoCard(DateTime now) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFF1B3B69).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.directions_bus,
                    color: Color(0xFF1B3B69), size: 26),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Van $_vanNumber',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1A2E),
                        fontFamily: 'Poppins',
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Driver: $_driverName',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF8A94A6),
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _statusColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _statusLabel,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _statusColor,
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          FreshnessLine(
            now: now,
            lastAt: _lastUpdateAt,
            offline: _signal == DriverSignal.offline,
          ),
          const SizedBox(height: 12),
          const Divider(color: Color(0xFFEAECF0), height: 1),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStat(
                icon: Icons.access_time,
                label: 'ETA',
                value: _eta,
                color: const Color(0xFF1B3B69),
              ),
              _buildStatDivider(),
              _buildStat(
                icon: Icons.speed,
                label: 'Speed',
                value: '${_vanSpeed.toStringAsFixed(0)} km/h',
                color: const Color(0xFFFEC610),
              ),
              _buildStatDivider(),
              _buildStat(
                icon: Icons.route,
                label: 'Connection',
                value: _joinedTrip ? 'Live' : 'Offline',
                color: _joinedTrip
                    ? const Color(0xFF27AE60)
                    : const Color(0xFFFF4B4B),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: _sendSOS,
              icon: const Icon(Icons.sos, size: 20),
              label: const Text(
                'Send SOS Alert',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Poppins',
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF4B4B),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStat({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: color,
            fontFamily: 'Poppins',
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: Color(0xFF8A94A6),
            fontFamily: 'Poppins',
          ),
        ),
      ],
    );
  }

  Widget _buildStatDivider() {
    return Container(
      height: 40,
      width: 1,
      color: const Color(0xFFEAECF0),
    );
  }

  Future<void> _sendSOS() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Row(
          children: [
            Icon(Icons.sos, color: Color(0xFFFF4B4B)),
            SizedBox(width: 8),
            Text(
              'Send SOS Alert',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.bold,
                color: Color(0xFFFF4B4B),
              ),
            ),
          ],
        ),
        content: const Text(
          'This will send an emergency alert to the driver and school. Are you sure?',
          style: TextStyle(fontFamily: 'Poppins'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Cancel',
              style: TextStyle(
                color: Color(0xFF8A94A6),
                fontFamily: 'Poppins',
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF4B4B),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Send SOS',
              style: TextStyle(
                color: Colors.white,
                fontFamily: 'Poppins',
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      // Wait for the backend's real acknowledgment instead of assuming
      // success the instant we emit — the button used to lie about this.
      final ackCompleter = Completer<Map<String, dynamic>?>();

      void onAck(dynamic data) {
        if (!ackCompleter.isCompleted) {
          ackCompleter.complete(data is Map<String, dynamic> ? data : null);
        }
      }

      try {
        _socket?.on('sosAck', onAck);

        _socket?.emit('sos', {
          'tripId': _currentTripId,
          'message': 'Parent sent SOS alert',
          'location': {
            'lat': _vanPosition.latitude,
            'lng': _vanPosition.longitude,
          },
        });

        // Give the server a few seconds to respond before treating it as
        // undelivered — a slow/dropped connection shouldn't hang the UI.
        final ack = await ackCompleter.future.timeout(
          const Duration(seconds: 6),
          onTimeout: () => null,
        );

        if (!mounted) return;

        final success = ack != null && ack['success'] == true;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? 'SOS Alert sent — the driver and school have been notified.'
                  : 'Could not confirm the SOS was delivered. Please also call the school directly if this is an emergency.',
            ),
            backgroundColor: const Color(0xFFFF4B4B),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
          ),
        );
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                  'Could not send SOS alert. Please call the school directly if this is an emergency.'),
              backgroundColor: const Color(0xFFFF4B4B),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          );
        }
      } finally {
        _socket?.off('sosAck', onAck);
      }
    }
  }
}