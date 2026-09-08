import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:dio/dio.dart';
import 'dart:io';
import '../../../core/constants/app_constants.dart';
import '../../../core/network/api_service.dart';
import '../../fees/screens/payment_history_screen.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  final VoidCallback? onProfileUpdated;
  const ProfileScreen({super.key, this.onProfileUpdated});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  Map<String, dynamic>? _profile;
  bool _isLoading = true;
  bool _isEditing = false;
  bool _isSaving = false;
  bool _notificationsEnabled = true;
  String? _loadError;
  bool _locationEnabled = true;
  File? _selectedImage;
  // The backend's getProfile response has no kidsCount/tripsCount/alertsCount
  // fields at all, so these were always reading undefined and showing "0" —
  // fetched from their real endpoints instead.
  int? _kidsCount;
  int? _tripsCount;
  int? _alertsCount;

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _loadStats();
  }

  Future<void> _setNotificationToggle(bool value) async {
    final previous = _notificationsEnabled;
    setState(() => _notificationsEnabled = value);
    try {
      final response = await ApiService.post('/auth/change-notification-toggle', {
        'notificationToggle': value,
      });
      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception('Failed to update notification setting');
      }
    } catch (e) {
      // Revert — the switch would otherwise silently drift from what the
      // backend (and therefore actual push delivery) is really set to.
      if (mounted) {
        setState(() => _notificationsEnabled = previous);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to update notification setting'),
            backgroundColor: Color(0xFFFF4B4B),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _loadStats() async {
    try {
      final kidsResponse = await ApiService.get('/kid/getKids');
      if (kidsResponse.statusCode == 200) {
        final raw = kidsResponse.data;
        final data = raw is Map ? raw['data'] : raw;
        if (mounted) setState(() => _kidsCount = data is List ? data.length : 0);
      }
    } catch (e) {}

    try {
      final tripsResponse = await ApiService.get('/kid/getTripHistory?limit=1');
      if (tripsResponse.statusCode == 200) {
        final raw = tripsResponse.data;
        final data = raw is Map ? raw['data'] : null;
        if (mounted) {
          setState(() => _tripsCount = data is Map ? (data['total'] as num?)?.toInt() ?? 0 : 0);
        }
      }
    } catch (e) {}

    try {
      final alertsResponse = await ApiService.get('/alert/getDriverNotificationByParent');
      if (alertsResponse.statusCode == 200) {
        final raw = alertsResponse.data;
        final inner = raw is Map ? raw['data'] : null;
        final notifications = inner is Map
            ? (inner['notifications'] ?? inner['alerts'] ?? [])
            : (inner is List ? inner : []);
        if (mounted) {
          setState(() => _alertsCount = notifications is List ? notifications.length : 0);
        }
      }
    } catch (e) {}
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() => _loadError = null);
    try {
      final response = await ApiService.get('/auth/getProfile');
      if (response.statusCode == 200) {
        final raw = response.data;
        final data = raw['data'] ?? raw;
        setState(() {
          _profile = data;
          _nameController.text = data['fullname'] ?? data['name'] ?? '';
          _emailController.text = data['email'] ?? '';
          _phoneController.text = data['phoneNo'] ?? data['phone'] ?? '';
          _addressController.text = data['address'] ?? '';
          _notificationsEnabled = data['notificationToggle'] ?? true;
        });
      }
    } catch (e) {
      String message = 'Could not load your profile.';
      if (e is DioException && e.response?.data?['message'] != null) {
        message = e.response!.data['message'].toString();
      }
      if (mounted) setState(() => _loadError = message);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );
    if (picked != null) {
      setState(() => _selectedImage = File(picked.path));
    }
  }

  Future<void> _saveProfile() async {
    if (_nameController.text.isEmpty) {
      _showError('Name cannot be empty');
      return;
    }
    setState(() => _isSaving = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final userType = prefs.getString('user_type') ?? 'parent';

      // Upload the picked image first (if any) — update-profile expects
      // a plain image URL string, not a raw file.
      String? imageUrl;
      if (_selectedImage != null) {
        imageUrl = await ApiService.uploadImage(_selectedImage!);
      }

      final response = await ApiService.post('/van/update-profile', {
        'fullname': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'phoneNo': _phoneController.text.trim(),
        'address': _addressController.text.trim(),
        'userType': userType,
        if (imageUrl != null) 'image': imageUrl,
      });

      if (response.statusCode == 200 || response.statusCode == 201) {
        setState(() => _selectedImage = null);
        await _loadProfile();
        setState(() => _isEditing = false);
        widget.onProfileUpdated?.call();
        if (mounted) _showSuccess('Profile updated successfully!');
      }
    } catch (e) {
      String message = 'Failed to save. Please try again.';
      if (e is DioException && e.response?.data?['message'] != null) {
        message = e.response!.data['message'].toString();
      }
      if (mounted) _showError(message);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) _showError('Could not open link');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFFFF4B4B),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFF27AE60),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _logout() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Logout',
            style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold)),
        content: const Text('Are you sure you want to logout?',
            style: TextStyle(fontFamily: 'Poppins')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel',
                style: TextStyle(color: Color(0xFF8A94A6), fontFamily: 'Poppins')),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final prefs = await SharedPreferences.getInstance();
              await prefs.remove(AppConstants.tokenKey);
              if (mounted) context.go('/login');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF4B4B),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Logout',
                style: TextStyle(color: Colors.white, fontFamily: 'Poppins')),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF1B2B6B)))
          : CustomScrollView(
              slivers: [
                SliverAppBar(
                  expandedHeight: 200,
                  floating: false,
                  pinned: true,
                  automaticallyImplyLeading: false,
                  backgroundColor: const Color(0xFF1B2B6B),
                  actions: [
                    if (!_isEditing)
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, color: Colors.white),
                        onPressed: () => setState(() => _isEditing = true),
                      ),
                    if (_isEditing)
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () {
                          setState(() => _isEditing = false);
                          _loadProfile();
                        },
                      ),
                  ],
                  flexibleSpace: FlexibleSpaceBar(
                    background: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF1B2B6B), Color(0xFF2D4099)],
                        ),
                      ),
                      child: SafeArea(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(height: 16),
                            GestureDetector(
                              onTap: _isEditing ? _pickImage : null,
                              child: Stack(
                                children: [
                                  Container(
                                    width: 90,
                                    height: 90,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                          color: const Color(0xFFFFB800), width: 3),
                                    ),
                                    child: ClipOval(
                                      child: _selectedImage != null
                                          ? Image.file(_selectedImage!, fit: BoxFit.cover)
                                          : _profile?['image'] != null
                                              ? Image.network(
                                                  _profile!['image'],
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (_, __, ___) =>
                                                      _buildAvatarFallback(),
                                                )
                                              : _buildAvatarFallback(),
                                    ),
                                  ),
                                  if (_isEditing)
                                    Positioned(
                                      bottom: 0,
                                      right: 0,
                                      child: Container(
                                        width: 28,
                                        height: 28,
                                        decoration: const BoxDecoration(
                                            color: Color(0xFFFFB800),
                                            shape: BoxShape.circle),
                                        child: const Icon(Icons.camera_alt,
                                            size: 16, color: Colors.white),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _nameController.text.isNotEmpty
                                  ? _nameController.text
                                  : 'Parent',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Poppins',
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _profile?['email'] ?? '',
                              style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13,
                                  fontFamily: 'Poppins'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildStatsRow(),
                        const SizedBox(height: 24),
                        const Text('Personal Information',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1A1A2E),
                                fontFamily: 'Poppins')),
                        const SizedBox(height: 12),
                        _buildInfoCard(),
                        const SizedBox(height: 24),
                        const Text('Settings',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1A1A2E),
                                fontFamily: 'Poppins')),
                        const SizedBox(height: 12),
                        _buildSettingsCard(),
                        const SizedBox(height: 24),
                        if (_isEditing)
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton(
                              onPressed: _isSaving ? null : _saveProfile,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1B2B6B),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                              ),
                              child: _isSaving
                                  ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                          color: Colors.white, strokeWidth: 2))
                                  : const Text('Save Changes',
                                      style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          fontFamily: 'Poppins')),
                            ),
                          ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: OutlinedButton.icon(
                            onPressed: _logout,
                            icon: const Icon(Icons.logout, color: Color(0xFFFF4B4B)),
                            label: const Text('Logout',
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFFFF4B4B),
                                    fontFamily: 'Poppins')),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Color(0xFFFF4B4B)),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildAvatarFallback() {
    final name = _nameController.text.isNotEmpty
        ? _nameController.text
        : (_profile?['name'] ?? 'P');
    return Container(
      color: const Color(0xFF1B2B6B).withOpacity(0.3),
      child: Center(
        child: Text(
          name[0].toUpperCase(),
          style: const TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontFamily: 'Poppins'),
        ),
      ),
    );
  }

  Widget _buildStatsRow() {
    return Row(
      children: [
        _buildStatCard('Kids', _kidsCount?.toString() ?? '—',
            Icons.child_care, const Color(0xFF1B2B6B)),
        const SizedBox(width: 12),
        _buildStatCard('Trips', _tripsCount?.toString() ?? '—',
            Icons.directions_bus, const Color(0xFFFFB800)),
        const SizedBox(width: 12),
        _buildStatCard('Alerts', _alertsCount?.toString() ?? '—',
            Icons.notifications, const Color(0xFFFF4B4B)),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4))
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(value,
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: color,
                    fontFamily: 'Poppins')),
            const SizedBox(height: 4),
            Text(label,
                style: const TextStyle(
                    fontSize: 11, color: Color(0xFF8A94A6), fontFamily: 'Poppins')),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        children: [
          _buildInfoField(
              icon: Icons.person_outlined,
              label: 'Full Name',
              controller: _nameController,
              isEditing: _isEditing),
          const Divider(height: 1, color: Color(0xFFEAECF0)),
          _buildInfoField(
              icon: Icons.email_outlined,
              label: 'Email',
              controller: _emailController,
              isEditing: false,
              isReadOnly: true),
          const Divider(height: 1, color: Color(0xFFEAECF0)),
          _buildInfoField(
              icon: Icons.phone_outlined,
              label: 'Phone',
              controller: _phoneController,
              isEditing: _isEditing,
              keyboardType: TextInputType.phone),
          const Divider(height: 1, color: Color(0xFFEAECF0)),
          _buildInfoField(
              icon: Icons.home_outlined,
              label: 'Address',
              controller: _addressController,
              isEditing: _isEditing),
        ],
      ),
    );
  }

  Widget _buildInfoField({
    required IconData icon,
    required String label,
    required TextEditingController controller,
    required bool isEditing,
    bool isReadOnly = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF1B2B6B), size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF8A94A6),
                        fontFamily: 'Poppins')),
                const SizedBox(height: 4),
                isEditing && !isReadOnly
                    ? TextFormField(
                        controller: controller,
                        keyboardType: keyboardType,
                        style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF1A1A2E),
                            fontFamily: 'Poppins'),
                        decoration: const InputDecoration(
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: Color(0xFF1B2B6B))),
                        ),
                      )
                    : Text(
                        controller.text.isEmpty ? 'Not set' : controller.text,
                        style: TextStyle(
                            fontSize: 14,
                            color: controller.text.isEmpty
                                ? const Color(0xFF8A94A6)
                                : const Color(0xFF1A1A2E),
                            fontFamily: 'Poppins'),
                      ),
              ],
            ),
          ),
          if (isReadOnly)
            const Icon(Icons.lock_outline, size: 14, color: Color(0xFF8A94A6)),
        ],
      ),
    );
  }

  Widget _buildSettingsCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        children: [
          _buildSettingsItem(
            icon: Icons.notifications_outlined,
            label: 'Push Notifications',
            color: const Color(0xFF1B2B6B),
            hasSwitch: true,
            value: _notificationsEnabled,
            onSwitch: (val) => _setNotificationToggle(val),
          ),
          const Divider(height: 1, color: Color(0xFFEAECF0)),
          _buildSettingsItem(
            icon: Icons.location_on_outlined,
            label: 'Location Access',
            color: const Color(0xFF27AE60),
            hasSwitch: true,
            value: _locationEnabled,
            // This is a device OS permission, not a server-side setting —
            // there is no backend endpoint for it (unlike notifications
            // below). Flipping this here doesn't actually grant/revoke
            // location access; it's UI-only until wired to a real
            // permission_handler request.
            onSwitch: (val) => setState(() => _locationEnabled = val),
          ),
          const Divider(height: 1, color: Color(0xFFEAECF0)),
          // ── Payment History ──────────────────────────────────────────────
          _buildSettingsItem(
            icon: Icons.receipt_long_outlined,
            label: 'Payment History',
            color: const Color(0xFF1B2B6B),
            hasArrow: true,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const PaymentHistoryScreen()),
            ),
          ),
          const Divider(height: 1, color: Color(0xFFEAECF0)),
          _buildSettingsItem(
            icon: Icons.lock_outlined,
            label: 'Change Password',
            color: const Color(0xFF1B2B6B),
            hasArrow: true,
            onTap: () => context.go('/change-password'),
          ),
          const Divider(height: 1, color: Color(0xFFEAECF0)),
          _buildSettingsItem(
            icon: Icons.security_outlined,
            label: 'Privacy Policy',
            color: const Color(0xFF8A94A6),
            hasArrow: true,
            onTap: () => _launchUrl('https://smartvan.pk/privacy-policy'),
          ),
          const Divider(height: 1, color: Color(0xFFEAECF0)),
          _buildSettingsItem(
            icon: Icons.help_outline,
            label: 'Help & Support',
            color: const Color(0xFFFFB800),
            hasArrow: true,
            onTap: () => _launchUrl('https://app.smartvan.pk/support'),
          ),
          const Divider(height: 1, color: Color(0xFFEAECF0)),
          _buildSettingsItem(
            icon: Icons.info_outline,
            label: 'App Version 1.0.0',
            color: const Color(0xFF8A94A6),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsItem({
    required IconData icon,
    required String label,
    required Color color,
    bool hasSwitch = false,
    bool hasArrow = false,
    bool value = false,
    VoidCallback? onTap,
    Function(bool)? onSwitch,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(label,
                  style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF1A1A2E),
                      fontFamily: 'Poppins')),
            ),
            if (hasSwitch)
              Switch(
                  value: value,
                  onChanged: onSwitch,
                  activeColor: const Color(0xFF1B2B6B)),
            if (hasArrow)
              const Icon(Icons.arrow_forward_ios,
                  size: 14, color: Color(0xFF8A94A6)),
          ],
        ),
      ),
    );
  }
}
