import 'package:clockwork/cli/parsing.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('parseDurationMinutes', () {
    test('accepts bare hours with plus sign', () {
      expect(parseDurationMinutes('+2'), 120);
      expect(parseDurationMinutes('2'), 120);
    });

    test('accepts fractional hours', () {
      expect(parseDurationMinutes('1.5'), 90);
      expect(parseDurationMinutes('+1.5h'), 90);
    });

    test('accepts hours and minutes', () {
      expect(parseDurationMinutes('2h30m'), 150);
      expect(parseDurationMinutes('1h'), 60);
      expect(parseDurationMinutes('90m'), 90);
    });

    test('rejects invalid input', () {
      expect(parseDurationMinutes(''), isNull);
      expect(parseDurationMinutes('+'), isNull);
      expect(parseDurationMinutes('abc'), isNull);
      expect(parseDurationMinutes('-1'), isNull);
      expect(parseDurationMinutes('0'), isNull);
    });
  });

  group('parseDayOption', () {
    final now = DateTime(2026, 8, 5, 15, 30);

    test('defaults to today', () {
      expect(parseDayOption(null, now: now), DateTime(2026, 8, 5));
      expect(parseDayOption('today', now: now), DateTime(2026, 8, 5));
    });

    test('supports yesterday', () {
      expect(parseDayOption('yesterday', now: now), DateTime(2026, 8, 4));
    });

    test('supports explicit dates', () {
      expect(parseDayOption('2026-08-01', now: now), DateTime(2026, 8, 1));
    });

    test('rejects invalid dates', () {
      expect(parseDayOption('not-a-date', now: now), isNull);
    });
  });
}
