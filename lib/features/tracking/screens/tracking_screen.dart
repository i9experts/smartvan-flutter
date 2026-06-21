import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/network/api_service.dart';

class TrackingScreen extends ConsumerStatefulWidget {
  const TrackingScreen({super.key});

  @override
  ConsumerState<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends ConsumerState<TrackingScreen> {
  GoogleMapController? _mapController;
  IO.Socket? _socket;
  LatLng _vanPosition = const LatLng(24.8607, 67.0011);
  LatLng _homePosition = const LatLng(24.8700, 67.0100);
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  bool _isConnected = false;
  bool _isLoading = true;
  Map<String, dynamic>? _tripData;
  String _vanStatus = 'En Route';
  String _eta = 'Calculating...';
  String _driverName = 'Driver';
  String _vanNumber = 'SV-001';
  double _vanSpeed = 0.0;

  @override
  void initState() {
    super.initState();
    _initTracking();
  }

  @override
  void dispose() {
    _socket?.disconnect();
    _socket?.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _initTracking() async {
    await _loadTripData();
    _connectSocket();
    _setupMarkers();
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _loadTripData() async {
    try {
      final response = await ApiService.get('/kid/getActiveTripDetails');
      if (response.statusCode == 200 && response.data != null) {
        setState(() {
          _tripData = response.data;
          final driver = response.data['driver'];
          final van = response.data['van'];
          if (driver != null) _driverName = driver['name'] ?? 'Driver';
          if (van != null) _vanNumber = van['plateNumber'] ?? 'SV-001';
          final location = response.data['currentLocation'];
          if (location != null) {
            _vanPosition = LatLng(
              location['lat'] ?? 24.8607,
              location['lng'] ?? 67.0011,
            );
          }
        });
      }
    } catch (e) {}
  }

  void _connectSocket() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(AppConstants.tokenKey) ?? '';

    _socket = IO.io(
      AppConstants.socketUrl,
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .setAuth({'token': token})
          .enableAutoConnect()
          .build(),
    );

    _socket!.onConnect((_) {
      if (mounted) setState(() => _isConnected = true);
      _socket!.emit('joinTracking', {'token': token});
    });

    _socket!.onDisconnect((_) {
      if (mounted) setState(() => _isConnected = false);
    });

    _socket!.on('vanLocation', (data) {
      if (data != null && mounted) {
        final lat = data['lat'] ?? data['latitude'];
        final lng = data['lng'] ?? data['longitude'];
        final speed = data['speed'] ?? 0.0;
        final eta = data['eta'] ?? 'Calculating...';

        if (lat != null && lng != null) {
          setState(() {
            _vanPosition = LatLng(
              double.tryParse(lat.toString()) ?? _vanPosition.latitude,
              double.tryParse(lng.toString()) ?? _vanPosition.longitude,
            );
            _vanSpeed = double.tryParse(speed.toString()) ?? 0.0;
            _eta = eta.toString();
          });
          _updateVanMarker();
          _animateCamera();
        }
      }
    });

    _socket!.on('tripStatus', (data) {
      if (data != null && mounted) {
        setState(() => _vanStatus = data['status'] ?? 'En Route');
      }
    });

    _socket!.connect();
  }

  void _setupMarkers() {
    setState(() {
      _markers = {
        Marker(
          markerId: const MarkerId('van'),
          position: _vanPosition,
          icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueBlue),
          infoWindow: InfoWindow(
            title: 'SmartVan - $_vanNumber',
            snippet: 'Driver: $_driverName',
          ),
        ),
        Marker(
          markerId: const MarkerId('home'),
          position: _homePosition,
          icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueGreen),
          infoWindow: const InfoWindow(
            title: 'Your Home',
            snippet: 'Drop-off location',
          ),
        ),
      };

      _polylines = {
        Polyline(
          polylineId: const PolylineId('route'),
          points: [_vanPosition, _homePosition],
          color: const Color(0xFF1B2B6B),
          width: 4,
          patterns: [
            PatternItem.dash(20),
            PatternItem.gap(10),
          ],
        ),
      };
    });
  }

  void _updateVanMarker() {
    final updatedMarkers =
        _markers.where((m) => m.markerId.value != 'van').toSet();
    updatedMarkers.add(
      Marker(
        markerId: const MarkerId('van'),
        position: _vanPosition,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        infoWindow: InfoWindow(
          title: 'SmartVan - $_vanNumber',
          snippet: 'Driver: $_driverName',
        ),
      ),
    );

    setState(() {
      _markers = updatedMarkers;
      _polylines = {
        Polyline(
          polylineId: const PolylineId('route'),
          points: [_vanPosition, _homePosition],
          color: const Color(0xFF1B2B6B),
          width: 4,
          patterns: [
            PatternItem.dash(20),
            PatternItem.gap(10),
          ],
        ),
      };
    });
  }

  void _animateCamera() {
    _mapController?.animateCamera(
      CameraUpdate.newLatLng(_vanPosition),
    );
  }

  void _centerOnVan() {
    _mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: _vanPosition, zoom: 15),
      ),
    );
  }

  void _fitBounds() {
    final bounds = LatLngBounds(
      southwest: LatLng(
        _vanPosition.latitude < _homePosition.latitude
            ? _vanPosition.latitude
            : _homePosition.latitude,
        _vanPosition.longitude < _homePosition.longitude
            ? _vanPosition.longitude
            : _homePosition.longitude,
      ),
      northeast: LatLng(
        _vanPosition.latitude > _homePosition.latitude
            ? _vanPosition.latitude
            : _homePosition.latitude,
        _vanPosition.longitude > _homePosition.longitude
            ? _vanPosition.longitude
            : _homePosition.longitude,
      ),
    );
    _mapController?.animateCamera(CameraUpdate.newLatLngBounds(bounds, 80));
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
                colors: [Color(0xFF1B2B6B), Color(0xFF2D4099)],
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
                            color: _isConnected
                                ? const Color(0xFF27AE60)
                                : const Color(0xFFFF4B4B),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _isConnected ? 'Live' : 'Connecting...',
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
                ? const Center(
                    child: CircularProgressIndicator(
                        color: Color(0xFF1B2B6B)),
                  )
                : Stack(
                    children: [
                      GoogleMap(
                        initialCameraPosition: CameraPosition(
                          target: _vanPosition,
                          zoom: 14,
                        ),
                        onMapCreated: (controller) {
                          _mapController = controller;
                          Future.delayed(
                              const Duration(milliseconds: 500), _fitBounds);
                        },
                        markers: _markers,
                        polylines: _polylines,
                        myLocationEnabled: true,
                        myLocationButtonEnabled: false,
                        zoomControlsEnabled: false,
                        mapToolbarEnabled: false,
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
                              onTap: _fitBounds,
                            ),
                          ],
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
        child: Icon(icon, color: const Color(0xFF1B2B6B), size: 20),
      ),
    );
  }

  Widget _buildInfoCard() {
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
                  color: const Color(0xFF1B2B6B).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.directions_bus,
                    color: Color(0xFF1B2B6B), size: 26),
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
                  color: const Color(0xFF27AE60).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _vanStatus,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF27AE60),
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: Color(0xFFEAECF0), height: 1),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStat(
                icon: Icons.access_time,
                label: 'ETA',
                value: _eta,
                color: const Color(0xFF1B2B6B),
              ),
              _buildStatDivider(),
              _buildStat(
                icon: Icons.speed,
                label: 'Speed',
                value: '${_vanSpeed.toStringAsFixed(0)} km/h',
                color: const Color(0xFFFFB800),
              ),
              _buildStatDivider(),
              _buildStat(
                icon: Icons.route,
                label: 'Status',
                value: _isConnected ? 'Live' : 'Offline',
                color: _isConnected
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
      try {
        _socket?.emit('sos', {
          'message': 'Parent sent SOS alert',
          'location': {
            'lat': _vanPosition.latitude,
            'lng': _vanPosition.longitude,
          },
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('SOS Alert sent successfully!'),
              backgroundColor: const Color(0xFFFF4B4B),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          );
        }
      } catch (e) {}
    }
  }
}