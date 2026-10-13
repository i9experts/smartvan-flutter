import 'package:flutter/material.dart';
import '../tracking_freshness.dart';

/// "Updated 12 sec ago" — or, once the driver is offline, when the van was
/// last seen. Always on the info card.
class FreshnessLine extends StatelessWidget {
  const FreshnessLine({
    super.key,
    required this.now,
    required this.lastAt,
    required this.offline,
  });

  final DateTime now;
  final DateTime? lastAt;
  final bool offline;

  @override
  Widget build(BuildContext context) {
    final last = lastAt;
    final showLastSeen = offline && last != null;
    final color =
        showLastSeen ? const Color(0xFFFF4B4B) : const Color(0xFF8A94A6);
    return Row(
      children: [
        Icon(showLastSeen ? Icons.signal_wifi_off : Icons.update,
            size: 14, color: color),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            showLastSeen ? lastSeenText(last) : updatedAgoText(now, last),
            style: TextStyle(fontSize: 12, color: color, fontFamily: 'Poppins'),
          ),
        ),
      ],
    );
  }
}
