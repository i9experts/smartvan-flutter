import 'package:flutter_test/flutter_test.dart';
import 'package:smartvan/features/tracking/tracking_freshness.dart';

void main() {
  final now = DateTime.utc(2026, 10, 13, 8, 30);
  DateTime ago(int seconds) => now.subtract(Duration(seconds: seconds));

  group('driverSignal', () {
    test('a position within 30 s is live', () {
      expect(driverSignal(now: now, lastAt: ago(0)), DriverSignal.live);
      expect(driverSignal(now: now, lastAt: ago(29)), DriverSignal.live);
    });

    test('30 s to 4 min is a weak signal', () {
      expect(driverSignal(now: now, lastAt: ago(30)), DriverSignal.weak);
      expect(driverSignal(now: now, lastAt: ago(120)), DriverSignal.weak);
      expect(driverSignal(now: now, lastAt: ago(239)), DriverSignal.weak);
    });

    test('4 min and more is offline', () {
      expect(driverSignal(now: now, lastAt: ago(240)), DriverSignal.offline);
      expect(driverSignal(now: now, lastAt: ago(3600)), DriverSignal.offline);
    });

    test('the server saying offline counts while nothing fresh came', () {
      expect(driverSignal(now: now, lastAt: ago(60), tripStatus: 'offline'),
          DriverSignal.offline);
    });

    test('a fresh position beats an old offline status (it is back)', () {
      expect(driverSignal(now: now, lastAt: ago(5), tripStatus: 'offline'),
          DriverSignal.live);
    });

    test('other statuses do not change the age rules', () {
      expect(driverSignal(now: now, lastAt: ago(100), tripStatus: 'moving'),
          DriverSignal.weak);
    });

    test('no position yet: nothing to judge', () {
      expect(driverSignal(now: now, lastAt: null), DriverSignal.live);
    });
  });

  group('updatedAgoText', () {
    test('seconds, minutes, hours', () {
      expect(updatedAgoText(now, ago(12)), 'Updated 12 sec ago');
      expect(updatedAgoText(now, ago(2)), 'Updated just now');
      expect(updatedAgoText(now, ago(59)), 'Updated 59 sec ago');
      expect(updatedAgoText(now, ago(60)), 'Updated 1 min ago');
      expect(updatedAgoText(now, ago(185)), 'Updated 3 min ago');
      expect(updatedAgoText(now, ago(3 * 3600 + 5)), 'Updated 3 h ago');
    });

    test('always something to read', () {
      expect(updatedAgoText(now, null), isNotEmpty);
    });

    test('a time slightly in the future (clock skew) is "just now"', () {
      expect(updatedAgoText(now, now.add(const Duration(seconds: 3))),
          'Updated just now');
    });
  });

  test('lastSeenText is the local clock time with AM/PM', () {
    final at = DateTime(2026, 10, 13, 13, 23);
    expect(lastSeenText(at), 'Driver offline — last seen 1:23 PM');
  });

  test('parseServerTime reads ISO strings only', () {
    expect(parseServerTime('2026-10-13T08:30:00.000Z'), now);
    expect(parseServerTime(null), isNull);
    expect(parseServerTime(5), isNull);
    expect(parseServerTime('nope'), isNull);
  });

  group('LocationEventGate', () {
    test('applies newer events, drops duplicates and older ones', () {
      final gate = LocationEventGate();
      expect(gate.accept(ago(10)), isTrue);
      expect(gate.accept(ago(10)), isFalse, reason: 'same event twice');
      expect(gate.accept(ago(20)), isFalse, reason: 'older');
      expect(gate.accept(ago(5)), isTrue);
      expect(gate.newest, ago(5));
    });

    test('events with no time are applied', () {
      final gate = LocationEventGate();
      expect(gate.accept(null), isTrue);
      expect(gate.accept(ago(5)), isTrue);
      expect(gate.accept(null), isTrue);
    });

    test('seed: older late events do not overwrite the first load', () {
      final gate = LocationEventGate()..seed(ago(10));
      expect(gate.accept(ago(30)), isFalse);
      expect(gate.accept(ago(2)), isTrue);
      gate.seed(ago(100)); // never moves it back
      expect(gate.newest, ago(2));
    });
  });
}
