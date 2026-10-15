import 'package:flutter/material.dart';
import '../trips_api.dart';

const _navy = Color(0xFF1B3B69);
const _yellow = Color(0xFFFEC610);

/// One finished trip for one child (a trip carrying two of the parent's
/// children is shown once per child).
class CompletedTripCard extends StatelessWidget {
  const CompletedTripCard(
      {super.key, required this.trip, required this.child, required this.onTap});

  final CompletedTrip trip;
  final TripChild child;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final who = [
      if (trip.driverName?.isNotEmpty ?? false) 'Driver ${trip.driverName}',
      if (trip.vanNumber?.isNotEmpty ?? false) 'Van ${trip.vanNumber}',
    ].join(' · ');
    final isDrop = trip.tripType == 'drop';
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        elevation: 1,
        shadowColor: Colors.black12,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                      color: _navy.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12)),
                  child: Icon(isDrop ? Icons.home_outlined : Icons.school_outlined,
                      color: _navy),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Flexible(
                          child: Text(child.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 14)),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                              color: _yellow.withValues(alpha: 0.25),
                              borderRadius: BorderRadius.circular(8)),
                          child: Text(tripTypeLabel(trip.tripType),
                              style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: _navy)),
                        ),
                      ]),
                      if (who.isNotEmpty)
                        Text(who,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 12, color: Color(0xFF8A94A6))),
                      const SizedBox(height: 2),
                      Text(
                        '${childStatusLabel(child.status)} ${child.at == null ? '' : pktTime(child.at)}'
                            .trim(),
                        style: const TextStyle(fontSize: 12, color: _navy),
                      ),
                      Text('Trip ended ${pktTime(trip.endedAt)} · ${pktDate(trip.endedAt)}',
                          style: const TextStyle(
                              fontSize: 11, color: Color(0xFF8A94A6))),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: Color(0xFF8A94A6)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
