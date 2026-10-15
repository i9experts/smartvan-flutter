import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/network/api_errors.dart';
import '../trips_api.dart';
import 'completed_trip_card.dart';

/// Finished trips for the parent's kids, newest first, grouped by day
/// (Pakistan time). Not scrollable itself: it sits inside the Track page's
/// scroll view. [reloadSignal] changing makes it start over (pull-to-refresh).
class RecentTripsSection extends StatefulWidget {
  const RecentTripsSection({super.key, this.reloadSignal = 0});

  final int reloadSignal;

  @override
  State<RecentTripsSection> createState() => _RecentTripsSectionState();
}

class _RecentTripsSectionState extends State<RecentTripsSection> {
  final List<CompletedTrip> _trips = [];
  int _page = 0;
  bool _hasMore = true;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(RecentTripsSection old) {
    super.didUpdateWidget(old);
    if (old.reloadSignal != widget.reloadSignal) {
      _trips.clear();
      _page = 0;
      _hasMore = true;
      _load();
    }
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
    final now = DateTime.now().toUtc();
    final rows = [
      for (final t in _trips)
        for (final c in t.children) (t, c),
    ];
    final children = <Widget>[];
    String? lastDay;
    for (final (trip, child) in rows) {
      final day = dayLabel(trip.endedAt, now);
      if (day != lastDay) {
        lastDay = day;
        children.add(Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 8),
          child: Text(day,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF8A94A6))),
        ));
      }
      children.add(CompletedTripCard(
        trip: trip,
        child: child,
        onTap: () =>
            context.push('/trip-details/${trip.id}?kid=${child.kidId}'),
      ));
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Recent trips',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A2E))),
          ...children,
          if (_loading)
            const Padding(
                padding: EdgeInsets.all(20),
                child: Center(child: CircularProgressIndicator()))
          else if (_error != null)
            Center(
                child: TextButton(
                    onPressed: _load,
                    child: Text(rows.isEmpty
                        ? '$_error  Tap to retry'
                        : 'Could not load more. Tap to retry')))
          else if (rows.isEmpty)
            const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(
                    child: Text('No completed trips yet',
                        style: TextStyle(color: Color(0xFF8A94A6)))))
          else if (_hasMore)
            Center(
                child: TextButton(
                    onPressed: _load, child: const Text('Load more'))),
        ],
      ),
    );
  }
}
