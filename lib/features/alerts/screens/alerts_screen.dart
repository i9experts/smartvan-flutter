import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_service.dart';

class AlertsScreen extends ConsumerStatefulWidget {
  const AlertsScreen({super.key});

  @override
  ConsumerState<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends ConsumerState<AlertsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<dynamic> _allAlerts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadAlerts();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAlerts() async {
    setState(() => _isLoading = true);
    try {
      final response = await ApiService.get('/alert/getDriverNotificationByParent');
      if (response.statusCode == 200) {
        final data = response.data;
        // API returns { data: [...] } or { alerts: [...] } or just a list
        List<dynamic> alerts = [];
        if (data is List) {
          alerts = data;
        } else if (data is Map) {
          final inner = data['data'];
          if (inner is Map) {
            alerts = inner['notifications'] ?? inner['alerts'] ?? [];
          } else if (inner is List) {
            alerts = inner;
          } else {
            alerts = data['notifications'] ?? data['alerts'] ?? [];
          }
        }
        setState(() => _allAlerts = alerts);
      }
    } catch (e) {
      debugPrint('Alerts error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<dynamic> _filterAlerts(String type) {
    if (type == 'all') return _allAlerts;
    return _allAlerts.where((a) {
      final alertType = (a['alertType'] ?? a['type'] ?? '').toString().toLowerCase();
      final recipientType = (a['recipientType'] ?? '').toString().toLowerCase();
      if (type == 'general') return alertType != 'sos' && alertType != 'pickup' && alertType != 'drop';
      return alertType == type || recipientType.contains(type);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: Column(
        children: [
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
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Alerts',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Poppins',
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${_allAlerts.length} Total',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  TabBar(
                    controller: _tabController,
                    indicatorColor: const Color(0xFFFFB800),
                    indicatorWeight: 3,
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.white54,
                    labelStyle: const TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                    tabs: const [
                      Tab(text: 'All Alerts'),
                      Tab(text: 'General'),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF1B2B6B)))
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildAlertsList(_filterAlerts('all')),
                      _buildAlertsList(_filterAlerts('general')),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertsList(List<dynamic> alerts) {
    return RefreshIndicator(
      onRefresh: _loadAlerts,
      color: const Color(0xFF1B2B6B),
      child: alerts.isEmpty
          ? ListView(
              children: [
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.5,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: const Color(0xFF1B2B6B).withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.notifications_off_outlined, size: 40, color: Color(0xFF1B2B6B)),
                      ),
                      const SizedBox(height: 16),
                      const Text('No Alerts',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1A1A2E), fontFamily: 'Poppins')),
                      const SizedBox(height: 8),
                      const Text('You have no alerts at the moment',
                          style: TextStyle(fontSize: 13, color: Color(0xFF8A94A6), fontFamily: 'Poppins')),
                    ],
                  ),
                ),
              ],
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: alerts.length,
              itemBuilder: (context, index) => _buildAlertCard(alerts[index]),
            ),
    );
  }

  Widget _buildAlertCard(dynamic alert) {
    // Handle both old and new API response formats
    final String alertType = (alert['alertType'] ?? alert['type'] ?? 'info').toString().toLowerCase();
    final String title = alert['alertType'] ?? alert['title'] ?? 'Alert';
    final String body = alert['message'] ?? alert['body'] ?? alert['description'] ?? '';
    final String time = alert['createdAt'] ?? alert['date'] ?? alert['time'] ?? '';
    final String recipientType = alert['recipientType'] ?? '';

    Color alertColor;
    IconData alertIcon;
    Color bgColor;

    switch (alertType) {
      case 'sos':
      case 'emergency':
        alertColor = const Color(0xFFFF4B4B);
        alertIcon = Icons.sos_outlined;
        bgColor = const Color(0xFFFF4B4B).withOpacity(0.1);
        break;
      case 'pickup':
      case 'route change':
        alertColor = const Color(0xFF27AE60);
        alertIcon = Icons.directions_bus_outlined;
        bgColor = const Color(0xFF27AE60).withOpacity(0.1);
        break;
      case 'drop':
      case 'delay notice':
        alertColor = const Color(0xFF1B2B6B);
        alertIcon = Icons.home_outlined;
        bgColor = const Color(0xFF1B2B6B).withOpacity(0.1);
        break;
      case 'safety alert':
        alertColor = const Color(0xFFFF4B4B);
        alertIcon = Icons.security_outlined;
        bgColor = const Color(0xFFFF4B4B).withOpacity(0.1);
        break;
      case 'school closure':
        alertColor = const Color(0xFF8B5CF6);
        alertIcon = Icons.school_outlined;
        bgColor = const Color(0xFF8B5CF6).withOpacity(0.1);
        break;
      default:
        alertColor = const Color(0xFFFFB800);
        alertIcon = Icons.notifications_outlined;
        bgColor = const Color(0xFFFFB800).withOpacity(0.1);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(12)),
              child: Icon(alertIcon, color: alertColor, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1A1A2E), fontFamily: 'Poppins'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (body.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(body,
                        style: const TextStyle(fontSize: 12, color: Color(0xFF8A94A6), fontFamily: 'Poppins'),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(8)),
                            child: Text(title.toUpperCase(),
                                style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: alertColor, fontFamily: 'Poppins')),
                          ),
                          if (recipientType.isNotEmpty) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
                              child: Text(
                                recipientType.replaceAll('_', ' '),
                                style: const TextStyle(fontSize: 9, color: Color(0xFF8A94A6), fontFamily: 'Poppins'),
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (time.isNotEmpty)
                        Text(_formatTime(time),
                            style: const TextStyle(fontSize: 11, color: Color(0xFF8A94A6), fontFamily: 'Poppins')),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(String time) {
    try {
      final dt = DateTime.parse(time).toLocal();
      final now = DateTime.now();
      final diff = now.difference(dt);
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      return '${diff.inDays}d ago';
    } catch (e) {
      return time;
    }
  }
}