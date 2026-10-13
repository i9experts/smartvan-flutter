import 'package:intl/intl.dart';

/// How trustworthy the van's position on the map is.
enum DriverSignal {
  /// A position within the last 30 s.
  live,

  /// 30 s to 4 min old: probably a weak signal or a short gap.
  weak,

  /// Older than 4 min, or the server said so: the driver is offline.
  offline,
}

/// Newer than this is [DriverSignal.live].
const liveWithin = Duration(seconds: 30);

/// Older than this is [DriverSignal.offline] (the server's "tracking lost"
/// alert fires at the same 4 minutes).
const offlineAfter = Duration(minutes: 4);

/// The signal for a last position at [lastAt] ([now] is the time to judge at).
/// [tripStatus] is the server's last `tripStatus` (`moving`, `stopped`,
/// `delayed`, `offline`): its `offline` counts while no fresh position has
/// come since. With no position known yet there is nothing to judge: live.
DriverSignal driverSignal({
  required DateTime now,
  required DateTime? lastAt,
  String? tripStatus,
}) {
  if (lastAt == null) return DriverSignal.live;
  final age = now.difference(lastAt);
  if (age >= offlineAfter) return DriverSignal.offline;
  if (tripStatus == 'offline' && age >= liveWithin) return DriverSignal.offline;
  if (age >= liveWithin) return DriverSignal.weak;
  return DriverSignal.live;
}

/// "Updated 12 sec ago" — always something to read, from the first second.
String updatedAgoText(DateTime now, DateTime? lastAt) {
  if (lastAt == null) return 'Waiting for the van\'s location…';
  final s = now.difference(lastAt).inSeconds.clamp(0, 1 << 30);
  if (s < 5) return 'Updated just now';
  if (s < 60) return 'Updated $s sec ago';
  final m = s ~/ 60;
  if (m < 60) return 'Updated $m min ago';
  return 'Updated ${m ~/ 60} h ago';
}

/// "Driver offline — last seen 1:23 PM", in the phone's local time.
String lastSeenText(DateTime lastAt) =>
    'Driver offline — last seen ${DateFormat('h:mm a').format(lastAt.toLocal())}';

/// A server time (`at`) as a DateTime, or null if it is missing or broken.
DateTime? parseServerTime(Object? value) =>
    value is String ? DateTime.tryParse(value) : null;

/// Drops location events older than the newest one seen. The same point can
/// come twice now (socket and HTTP relay), and events can arrive out of
/// order after a reconnect.
class LocationEventGate {
  DateTime? _newest;

  DateTime? get newest => _newest;

  /// True if the event with server time [at] should be applied. Events
  /// without a time are applied (nothing to compare).
  bool accept(DateTime? at) {
    if (at == null) return true;
    final newest = _newest;
    if (newest != null && !at.isAfter(newest)) return false;
    _newest = at;
    return true;
  }

  /// Notes a time from somewhere else (the first load) so older events that
  /// arrive late are not applied over it.
  void seed(DateTime? at) {
    if (at == null) return;
    final newest = _newest;
    if (newest == null || at.isAfter(newest)) _newest = at;
  }
}
