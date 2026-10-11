import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/network/api_service.dart';

/// Lets a parent rate the driver for one or more recently-ended trips they
/// haven't rated yet. Either opened with an already-fetched [pendingRatings]
/// list (Home-screen "Rate Now" prompt), or opened bare from a "rate your
/// driver" push notification tap — in which case it fetches
/// GET /rating/pendingRatings itself, optionally narrowed to [tripId] from
/// the notification payload. Steps through one trip at a time — rate &
/// next, or skip.
class RateTripScreen extends StatefulWidget {
  final List<Map<String, dynamic>> pendingRatings;
  final String? tripId;

  const RateTripScreen({super.key, this.pendingRatings = const [], this.tripId});

  @override
  State<RateTripScreen> createState() => _RateTripScreenState();
}

class _RateTripScreenState extends State<RateTripScreen> {
  List<Map<String, dynamic>> _queue = [];
  bool _isLoadingQueue = true;
  int _index = 0;
  int _stars = 0;
  final TextEditingController _commentController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    if (widget.pendingRatings.isNotEmpty) {
      _queue = widget.pendingRatings;
      _isLoadingQueue = false;
    } else {
      _fetchQueue();
    }
  }

  Future<void> _fetchQueue() async {
    try {
      final response = await ApiService.get('/rating/pendingRatings');
      final raw = response.data;
      final all = ((raw is Map ? raw['data'] : null) ?? raw ?? []) as List<dynamic>;
      var items = all.cast<Map<String, dynamic>>();
      if (widget.tripId != null) {
        final narrowed = items.where((r) => r['tripId'] == widget.tripId).toList();
        if (narrowed.isNotEmpty) items = narrowed;
      }
      if (mounted) setState(() => _queue = items);
    } catch (e) {
      debugPrint('Failed to load pending ratings: $e');
    } finally {
      if (mounted) setState(() => _isLoadingQueue = false);
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Map<String, dynamic> get _current => _queue[_index];

  void _advance() {
    if (_index >= _queue.length - 1) {
      if (mounted) context.pop();
      return;
    }
    setState(() {
      _index += 1;
      _stars = 0;
      _commentController.clear();
    });
  }

  Future<void> _submit() async {
    if (_stars == 0) return;
    setState(() => _isSubmitting = true);
    try {
      // The backend resolves the driver from the trip itself — a parent
      // never needs to (and can't) choose who they're rating.
      final response = await ApiService.post('/rating/rateTrip', {
        'tripId': _current['tripId'],
        'stars': _stars,
        if (_commentController.text.trim().isNotEmpty)
          'comment': _commentController.text.trim(),
      });

      if (response.statusCode != 200 && response.statusCode != 201) {
        final message = response.data is Map
            ? (response.data['message'] ?? 'Failed to submit rating')
            : 'Failed to submit rating';
        throw Exception(message);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Thanks for rating your driver!'),
            backgroundColor: const Color(0xFF27AE60),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
      _advance();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit rating: $e'),
            backgroundColor: const Color(0xFFFF4B4B),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingQueue) {
      return const Scaffold(
        backgroundColor: Color(0xFFF5F6FA),
        body: Center(child: CircularProgressIndicator(color: Color(0xFF1B2B6B))),
      );
    }

    if (_queue.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.pop();
      });
      return const SizedBox.shrink();
    }

    final driverName = _current['driverName'] ?? 'your driver';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B2B6B),
        foregroundColor: Colors.white,
        title: Text(
          'Rate driver (${_index + 1}/${_queue.length})',
          style: const TextStyle(fontFamily: 'Poppins'),
        ),
        actions: [
          TextButton(
            onPressed: _isSubmitting ? null : _advance,
            child: const Text('Skip', style: TextStyle(color: Colors.white, fontFamily: 'Poppins')),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              CircleAvatar(
                radius: 40,
                backgroundColor: const Color(0xFF1B2B6B).withOpacity(0.1),
                backgroundImage: (_current['driverImage'] as String?)?.isNotEmpty == true
                    ? NetworkImage(_current['driverImage'])
                    : null,
                child: (_current['driverImage'] as String?)?.isNotEmpty == true
                    ? null
                    : Text(
                        driverName.toString().isNotEmpty ? driverName[0].toUpperCase() : '?',
                        style: const TextStyle(
                            fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF1B2B6B)),
                      ),
              ),
              const SizedBox(height: 16),
              Center(
                child: Text(
                  'How was your trip with $driverName?',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w600, fontFamily: 'Poppins'),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (i) {
                  final filled = i < _stars;
                  return IconButton(
                    iconSize: 40,
                    onPressed: () => setState(() => _stars = i + 1),
                    icon: Icon(
                      filled ? Icons.star : Icons.star_border,
                      color: const Color(0xFFFFB800),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _commentController,
                maxLines: 3,
                maxLength: 500,
                decoration: InputDecoration(
                  hintText: 'Add a comment (optional)',
                  hintStyle: const TextStyle(fontFamily: 'Poppins'),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: _isSubmitting || _stars == 0 ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1B2B6B),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text(
                        'Submit Rating',
                        style: TextStyle(color: Colors.white, fontFamily: 'Poppins', fontSize: 16),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
