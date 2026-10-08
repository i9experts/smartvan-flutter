import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/network/api_service.dart';
import '../../../core/widgets/skeletons/home_screen_skeleton.dart';
import '../../alerts/screens/alerts_screen.dart';
import '../../kids/screens/kids_screen.dart';
import '../../profile/screens/profile_screen.dart';
import '../../../core/storage/token_storage.dart';
import '../../chat/chat_api.dart';
import '../../tracking/screens/parent_tracking_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _currentIndex = 0;
  Map<String, dynamic>? _profile;
  List<dynamic> _kids = [];
  List<dynamic> _alerts = [];
  List<dynamic> _banners = [];
  /// Today's trips that are in progress for this parent's kids.
  List<dynamic> _activeTrips = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  int _chatUnread = 0;

  Future<void> _loadChatUnread() async {
    try {
      final n = await ChatApi.unread();
      if (mounted) setState(() => _chatUnread = n);
    } catch (_) {
      // chat not available — icon without badge
    }
  }

  Future<void> _loadData() async {
    _loadChatUnread();
    await Future.wait([
      _loadProfile(),
      _loadKids(),
      _loadAlerts(),
      _loadBanners(),
      _loadActiveTrips(),
    ]);
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _loadBanners() async {
    try {
      final response = await ApiService.get('/promotion-banner/active');
      if (response.statusCode == 200) {
        final raw = response.data;
        final data = raw['data'] ?? raw;
        if (mounted) setState(() => _banners = data is List ? data : []);
      }
    } catch (e) {}
  }

  Future<void> _loadProfile() async {
    try {
      final response = await ApiService.get('/auth/getProfile');
      if (response.statusCode == 200 && mounted) {
        // The API wraps the user in { data: ... }; older builds read the
        // wrapper itself, so the name/photo never showed.
        final raw = response.data;
        final user = raw is Map && raw['data'] is Map ? raw['data'] : raw;
        setState(() => _profile = user is Map ? Map<String, dynamic>.from(user) : null);
      }
    } catch (e) {}
  }

  Future<void> _loadKids() async {
    try {
      final response = await ApiService.get('/kid/getKids');
      if (response.statusCode == 200 && mounted) {
        // Response is { message, data: [kids] } — reading data['kids'] always
        // gave an empty list, so Home said "No kids added yet".
        final raw = response.data;
        final list = raw is List ? raw : (raw is Map ? (raw['data'] ?? raw['kids']) : null);
        setState(() => _kids = list is List ? list : []);
      }
    } catch (_) {
      // keep whatever was shown
    }
  }

  Future<void> _loadActiveTrips() async {
    try {
      final response = await ApiService.get('/kid/getActiveTripDetails');
      if (response.statusCode == 200 && mounted) {
        final raw = response.data;
        final list = raw is Map ? raw['data'] : raw;
        setState(() => _activeTrips = list is List ? list : []);
      }
    } catch (_) {
      if (mounted) setState(() => _activeTrips = []);
    }
  }

  Future<void> _loadAlerts() async {
    try {
      final response =
          await ApiService.get('/alert/getDriverNotificationByParent');
      if (response.statusCode == 200 && mounted) {
        // Response is { message, data: { notifications: [...] } } (newest
        // first); data['alerts'] never existed, so Recent Alerts was empty.
        final raw = response.data;
        final inner = raw is Map ? raw['data'] : raw;
        final list = inner is List
            ? inner
            : (inner is Map ? (inner['notifications'] ?? inner['alerts']) : null);
        setState(() => _alerts = list is List ? list : []);
      }
    } catch (_) {
      // keep whatever was shown
    }
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Logout',
          style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'Are you sure you want to logout?',
          style: TextStyle(fontFamily: 'Poppins'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Color(0xFF8A94A6), fontFamily: 'Poppins'),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF4B4B),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text(
              'Logout',
              style: TextStyle(color: Colors.white, fontFamily: 'Poppins'),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    await TokenStorage.clear();
    if (mounted) context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: _isLoading ? const HomeScreenSkeleton() : _buildBody(),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBody() {
    switch (_currentIndex) {
      case 0:
        return _buildHome();
      case 1:
        return const TrackingScreen();
      case 2:
        return const KidsScreen();
      case 3:
        return const AlertsScreen();
      case 4:
        return ProfileScreen(onProfileUpdated: _loadProfile);
      default:
        return _buildHome();
    }
  }

  Widget _buildHome() {
    final name = _profile?['fullname'] ?? _profile?['name'] ?? 'Parent';
    final firstName = name.toString().trim().split(' ').first;
    final hour = DateTime.now().hour;
    final greeting = hour < 12 ? 'Good Morning' : (hour < 17 ? 'Good Afternoon' : 'Good Evening');
    final photo = (_profile?['image'] ?? _profile?['profileImage'])?.toString();

    return RefreshIndicator(
      onRefresh: _loadData,
      color: const Color(0xFF1B2B6B),
      child: CustomScrollView(
        slivers: [
          // Pinned header: the greeting row lives in the toolbar itself, so it
          // stays visible while scrolling (it used to sit in a collapsing
          // FlexibleSpaceBar background, leaving an empty blue bar).
          SliverAppBar(
            pinned: true,
            toolbarHeight: 76,
            titleSpacing: 20,
            automaticallyImplyLeading: false,
            backgroundColor: const Color(0xFF1B2B6B),
            surfaceTintColor: Colors.transparent,
            scrolledUnderElevation: 2,
            flexibleSpace: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF1B2B6B), Color(0xFF2D4099)],
                ),
              ),
            ),
            title: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Row(
                                children: [
                                  Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: const Color(0xFFFFB800),
                                        width: 2,
                                      ),
                                      color: Colors.white.withOpacity(0.2),
                                    ),
                                    child: ClipOval(
                                      child: photo != null && photo.isNotEmpty
                                          ? Image.network(
                                              photo,
                                              fit: BoxFit.cover,
                                              errorBuilder: (_, __, ___) =>
                                                  const Icon(
                                                Icons.person,
                                                color: Colors.white,
                                                size: 28,
                                              ),
                                            )
                                          : const Icon(
                                              Icons.person,
                                              color: Colors.white,
                                              size: 28,
                                            ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          '$greeting, $firstName! 👋',
                                          overflow: TextOverflow.ellipsis,
                                          maxLines: 1,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            fontFamily: 'Poppins',
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        const Text(
                                          'Track your child\'s journey',
                                          overflow: TextOverflow.ellipsis,
                                          maxLines: 1,
                                          style: TextStyle(
                                            color: Colors.white70,
                                            fontSize: 12,
                                            fontFamily: 'Poppins',
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Row(
                              children: [
                                IconButton(
                                  tooltip: 'Messages',
                                  onPressed: () async {
                                    await context.push('/chats');
                                    _loadChatUnread();
                                  },
                                  icon: Badge(
                                    isLabelVisible: _chatUnread > 0,
                                    label: Text('$_chatUnread'),
                                    backgroundColor: const Color(0xFF27AE60),
                                    child: const Icon(Icons.chat_bubble_outline,
                                        color: Colors.white, size: 24),
                                  ),
                                ),
                                IconButton(
                                  onPressed: () =>
                                      setState(() => _currentIndex = 3),
                                  icon: Stack(
                                    children: [
                                      const Icon(Icons.notifications_outlined,
                                          color: Colors.white, size: 26),
                                      if (_alerts.isNotEmpty)
                                        Positioned(
                                          right: 0,
                                          top: 0,
                                          child: Container(
                                            width: 8,
                                            height: 8,
                                            decoration: const BoxDecoration(
                                              color: Color(0xFFFFB800),
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  onPressed: _logout,
                                  icon: const Icon(Icons.logout,
                                      color: Colors.white, size: 22),
                                ),
                              ],
                            ),
                          ],
                        ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildActiveTripBanner(),
                  _buildAdBanner(),
                  const SizedBox(height: 24),
                  const Text(
                    'Quick Actions',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A2E),
                      fontFamily: 'Poppins',
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildQuickActions(),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'My Kids',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A1A2E),
                          fontFamily: 'Poppins',
                        ),
                      ),
                      TextButton(
                        onPressed: () => setState(() => _currentIndex = 2),
                        child: const Text(
                          'View All',
                          style: TextStyle(
                            color: Color(0xFF1B2B6B),
                            fontSize: 13,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildKidsSection(),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Recent Alerts',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A1A2E),
                          fontFamily: 'Poppins',
                        ),
                      ),
                      TextButton(
                        onPressed: () => setState(() => _currentIndex = 3),
                        child: const Text(
                          'View All',
                          style: TextStyle(
                            color: Color(0xFF1B2B6B),
                            fontSize: 13,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildAlertsSection(),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Shown only while one of this parent's kids has a trip in progress
  /// (it used to be a hardcoded "Van is on the way — 12 minutes" for
  /// everyone). Live ETA is on the Track tab.
  Widget _buildActiveTripBanner() {
    if (_activeTrips.isEmpty) return const SizedBox.shrink();
    final trip = _activeTrips.first is Map ? _activeTrips.first as Map : const {};
    final kids = (trip['kids'] is List ? trip['kids'] as List : const [])
        .whereType<Map>()
        .map((k) => (k['name'] ?? k['fullname'])?.toString() ?? '')
        .where((n) => n.isNotEmpty)
        .toList();
    final driver = trip['driverFullname']?.toString();
    final van = trip['carNumber']?.toString();
    final who = kids.isEmpty ? 'Your child' : kids.join(', ');
    final details = [
      if (driver != null && driver.isNotEmpty) 'Driver $driver',
      if (van != null && van.isNotEmpty) 'Van $van',
    ].join(' · ');

    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFF27AE60), Color(0xFF2ECC71)]),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF27AE60).withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.directions_bus, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _activeTrips.length > 1 ? '${_activeTrips.length} trips in progress' : 'Van is on the way!',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    details.isEmpty ? who : '$who · $details',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white70, fontSize: 12, fontFamily: 'Poppins'),
                  ),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: () => setState(() => _currentIndex = 1),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF27AE60),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Track', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdBanner() {
    // Real, admin-managed banners — replaces what used to be a
    // completely hardcoded, static list of 3 fake ads.
    if (_banners.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 110,
      child: PageView.builder(
        itemCount: _banners.length,
        itemBuilder: (context, index) {
          final banner = _banners[index];
          final imageUrl = banner['imageUrl'] as String?;
          final title = banner['title'] as String? ?? '';
          final redirectUrl = banner['redirectUrl'] as String?;

          return GestureDetector(
            onTap: redirectUrl == null || redirectUrl.isEmpty
                ? null
                : () async {
                    final uri = Uri.tryParse(redirectUrl);
                    if (uri != null && await canLaunchUrl(uri)) {
                      await launchUrl(uri,
                          mode: LaunchMode.externalApplication);
                    }
                  },
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: const Color(0xFF1B2B6B),
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (imageUrl != null)
                    Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          Container(color: const Color(0xFF1B2B6B)),
                    ),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withOpacity(0),
                            Colors.black.withOpacity(0.55)
                          ],
                        ),
                      ),
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildQuickActions() {
    final actions = [
      {
        'icon': Icons.map_outlined,
        'label': 'Live Track',
        'color': const Color(0xFF1B2B6B),
        'index': 1,
      },
      {
        'icon': Icons.child_care_outlined,
        'label': 'My Kids',
        'color': const Color(0xFFFFB800),
        'index': 2,
      },
      {
        'icon': Icons.notifications_outlined,
        'label': 'Alerts',
        'color': const Color(0xFFFF4B4B),
        'index': 3,
      },
      {
        'icon': Icons.person_outlined,
        'label': 'Profile',
        'color': const Color(0xFF00C48C),
        'index': 4,
      },
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: actions.map((action) {
        return GestureDetector(
          onTap: () => setState(() => _currentIndex = action['index'] as int),
          child: Column(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: (action['color'] as Color).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  action['icon'] as IconData,
                  color: action['color'] as Color,
                  size: 28,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                action['label'] as String,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF1A1A2E),
                  fontFamily: 'Poppins',
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildKidsSection() {
    if (_kids.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            const Icon(Icons.child_care, size: 48, color: Color(0xFF8A94A6)),
            const SizedBox(height: 12),
            const Text(
              'No kids added yet',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1A2E),
                fontFamily: 'Poppins',
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Add your child to start tracking',
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF8A94A6),
                fontFamily: 'Poppins',
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => context.go('/add-kid'),
              icon: const Icon(Icons.add, size: 18),
              label: const Text(
                'Add Kid',
                style: TextStyle(fontFamily: 'Poppins'),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1B2B6B),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return SizedBox(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _kids.length + 1,
        itemBuilder: (context, index) {
          if (index == _kids.length) {
            return GestureDetector(
              onTap: () => context.go('/add-kid'),
              child: Container(
                width: 90,
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF1B2B6B)),
                ),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_circle_outline,
                        color: Color(0xFF1B2B6B), size: 28),
                    SizedBox(height: 8),
                    Text(
                      'Add Kid',
                      style: TextStyle(
                        fontSize: 11,
                        color: Color(0xFF1B2B6B),
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          final kid = _kids[index];
          return Container(
            width: 90,
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1B2B6B).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: (kid['image']?.toString().isNotEmpty ?? false)
                      ? Image.network(
                          kid['image'].toString(),
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(Icons.child_care,
                              color: Color(0xFF1B2B6B), size: 28),
                        )
                      : const Icon(Icons.child_care,
                          color: Color(0xFF1B2B6B), size: 28),
                ),
                const SizedBox(height: 8),
                Text(
                  (kid['fullname'] ?? kid['name'] ?? 'Kid').toString(),
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A2E),
                    fontFamily: 'Poppins',
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Builder(builder: (_) {
                  // Real status from the school (was always "Active").
                  final active = kid['status']?.toString() == 'active';
                  final color = active ? const Color(0xFF27AE60) : const Color(0xFFFFB800);
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      active ? 'Active' : 'Pending',
                      style: TextStyle(
                        fontSize: 9,
                        color: color,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  );
                }),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildAlertsSection() {
    if (_alerts.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Row(
          children: [
            Icon(Icons.check_circle_outline,
                color: Color(0xFF27AE60), size: 24),
            SizedBox(width: 12),
            Text(
              'No alerts at the moment',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF8A94A6),
                fontFamily: 'Poppins',
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: _alerts.take(3).map((alert) {
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFB800).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.notifications_outlined,
                    color: Color(0xFFFFB800), size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      alert['title'] ?? alert['message'] ?? 'Alert',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A1A2E),
                        fontFamily: 'Poppins',
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      alert['description'] ?? alert['body'] ?? '',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF8A94A6),
                        fontFamily: 'Poppins',
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: const Color(0xFF1B2B6B),
        unselectedItemColor: const Color(0xFF8A94A6),
        selectedLabelStyle: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          fontFamily: 'Poppins',
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 11,
          fontFamily: 'Poppins',
        ),
        elevation: 0,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.map_outlined),
            activeIcon: Icon(Icons.map),
            label: 'Track',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.child_care_outlined),
            activeIcon: Icon(Icons.child_care),
            label: 'Kids',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications_outlined),
            activeIcon: Icon(Icons.notifications),
            label: 'Alerts',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outlined),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
