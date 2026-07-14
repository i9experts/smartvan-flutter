import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';

class HomeAddressPickerResult {
  final double lat;
  final double lng;
  final String address;

  HomeAddressPickerResult({
    required this.lat,
    required this.lng,
    required this.address,
  });
}

class HomeAddressPickerScreen extends StatefulWidget {
  final double? initialLat;
  final double? initialLng;

  const HomeAddressPickerScreen({super.key, this.initialLat, this.initialLng});

  @override
  State<HomeAddressPickerScreen> createState() =>
      _HomeAddressPickerScreenState();
}

class _HomeAddressPickerScreenState extends State<HomeAddressPickerScreen> {
  GoogleMapController? _mapController;
  LatLng _center = const LatLng(24.8607, 67.0011); // Karachi default
  String _address = 'Move the map to set your home location';
  bool _isResolving = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialLat != null && widget.initialLng != null) {
      _center = LatLng(widget.initialLat!, widget.initialLng!);
    }
  }

  Future<void> _resolveAddress(LatLng position) async {
    setState(() => _isResolving = true);
    try {
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        final parts = [
          p.street,
          p.subLocality,
          p.locality,
          p.administrativeArea,
        ].where((e) => e != null && e.trim().isNotEmpty).toList();
        setState(() {
          _address = parts.isNotEmpty
              ? parts.join(', ')
              : 'Lat: ${position.latitude.toStringAsFixed(5)}, Lng: ${position.longitude.toStringAsFixed(5)}';
        });
      }
    } catch (e) {
      setState(() {
        _address =
            'Lat: ${position.latitude.toStringAsFixed(5)}, Lng: ${position.longitude.toStringAsFixed(5)}';
      });
    } finally {
      if (mounted) setState(() => _isResolving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(target: _center, zoom: 16),
            onMapCreated: (controller) {
              _mapController = controller;
              _resolveAddress(_center);
            },
            onCameraMove: (position) => _center = position.target,
            onCameraIdle: () => _resolveAddress(_center),
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
          ),

          // Fixed center pin
          const Center(
            child: Padding(
              padding: EdgeInsets.only(bottom: 40),
              child: Icon(
                Icons.location_pin,
                size: 48,
                color: Color(0xFFFF4B4B),
              ),
            ),
          ),

          // Back button
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Align(
                alignment: Alignment.topLeft,
                child: Material(
                  color: Colors.white,
                  shape: const CircleBorder(),
                  elevation: 3,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Color(0xFF1B2B6B)),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ),
            ),
          ),

          // Bottom confirm card
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                boxShadow: [
                  BoxShadow(color: Colors.black12, blurRadius: 12, offset: Offset(0, -4)),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Pickup Location',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF8A94A6),
                      fontFamily: 'Poppins',
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _isResolving ? 'Locating...' : _address,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1A1A2E),
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ),
                      if (_isResolving)
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _isResolving
                          ? null
                          : () {
                              Navigator.pop(
                                context,
                                HomeAddressPickerResult(
                                  lat: _center.latitude,
                                  lng: _center.longitude,
                                  address: _address,
                                ),
                              );
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1B2B6B),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Confirm Location',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
