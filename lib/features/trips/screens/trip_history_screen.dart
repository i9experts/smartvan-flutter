import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/network/api_errors.dart';
import '../../../core/widgets/bottom_inset.dart';
import '../trips_api.dart';
import '../widgets/completed_trip_card.dart';

/// Every finished trip that carried the parent's children, newest first.
class TripHistoryScreen extends StatefulWidget {
  const TripHistoryScreen({super.key});

  @override
  State<TripHistoryScreen> createState() => _TripHistoryScreenState();
}

class _TripHistoryScreenState extends State<TripHistoryScreen> {
  final _scroll = ScrollController();
  final List<CompletedTrip> _trips = [];
  int _page = 0;
  bool _hasMore = true;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      if (_scroll.position.pixels > _scroll.position.maxScrollExtent - 300) {
        _load();
      }
    });
    _load();
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    _trips.clear();
    _page = 0;
    _hasMore = true;
    _error = null;
    await _load();
  }

  Future<void> _load() async {
    if (_loading || !_hasMore) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final page = await TripsApi.completed(page: _page + 1);
      if (!mounted) return;
      setState(() {
        _page++;
        _trips.addAll(page.items);
        _hasMore = page.hasMore;
      });
    } catch (e) {
      if (mounted) setState(() => _error = ApiErrors.message(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // One card per own child per trip.
    final rows = [
      for (final t in _trips)
        for (final c in t.children) (t, c),
    ];
    return Scaffold(
      appBar: AppBar(title: const Text('Trip History')),
      body: SafeArea(
        top: false,
        child: RefreshIndicator(
          color: const Color(0xFF1B3B69),
          onRefresh: _refresh,
          child: _body(rows),
        ),
      ),
    );
  }

  Widget _body(List<(CompletedTrip, TripChild)> rows) {
    if (rows.isEmpty && _loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (rows.isEmpty) {
      final failed = _error != null;
      // A scrollable, so pull-to-refresh also works on the empty/error state.
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 120),
          Icon(failed ? Icons.cloud_off : Icons.directions_bus_outlined,
              size: 56, color: const Color(0xFF8A94A6)),
          const SizedBox(height: 12),
          Center(
            child: Text(failed ? _error! : 'No completed trips yet',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFF8A94A6))),
          ),
          if (failed)
            Center(
                child: TextButton(
                    onPressed: _refresh, child: const Text('Try again'))),
        ],
      );
    }
    return ListView.builder(
      controller: _scroll,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: withBottomInset(context, const EdgeInsets.all(16)),
      itemCount: rows.length + 1,
      itemBuilder: (context, i) {
        if (i == rows.length) {
          if (_error != null) {
            return TextButton(
                onPressed: _load, child: Text('$_error  Tap to retry'));
          }
          return _loading
              ? const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()))
              : const SizedBox.shrink();
        }
        final (trip, child) = rows[i];
        return CompletedTripCard(
          trip: trip,
          child: child,
          onTap: () => context.push('/trip-details/${trip.id}?kid=${child.kidId}'),
        );
      },
    );
  }
}
