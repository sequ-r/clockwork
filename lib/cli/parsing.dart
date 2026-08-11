/// Parsing helpers shared by the CLI and its tests.
library;

/// Parses a duration argument such as `+2`, `2h30m`, `90m` or `1.5h`
/// into minutes.
///
/// A bare number (with optional leading `+`) is interpreted as hours and
/// may be fractional. Returns null when the input is not valid.
int? parseDurationMinutes(String input) {
  final text = input.startsWith('+') ? input.substring(1) : input;
  if (text.isEmpty) return null;

  final hoursMinutes = RegExp(r'^(\d+)h(\d+)m$').firstMatch(text);
  if (hoursMinutes != null) {
    return int.parse(hoursMinutes[1]!) * 60 + int.parse(hoursMinutes[2]!);
  }
  final hoursOnly = RegExp(r'^(\d+(?:\.\d+)?)h$').firstMatch(text);
  if (hoursOnly != null) {
    return (double.parse(hoursOnly[1]!) * 60).round();
  }
  final minutesOnly = RegExp(r'^(\d+)m$').firstMatch(text);
  if (minutesOnly != null) {
    return int.parse(minutesOnly[1]!);
  }

  final hours = double.tryParse(text);
  if (hours == null || hours <= 0) return null;
  return (hours * 60).round();
}

/// Resolves a `--day` option value to a concrete day.
///
/// Accepts `today`, `yesterday` and `YYYY-MM-DD`. Returns null for
/// invalid input.
DateTime? parseDayOption(String? value, {DateTime? now}) {
  final reference = now ?? DateTime.now();
  final today = DateTime(reference.year, reference.month, reference.day);
  switch (value) {
    case null:
    case 'today':
      return today;
    case 'yesterday':
      return today.subtract(const Duration(days: 1));
    default:
      final parsed = DateTime.tryParse(value);
      if (parsed == null) return null;
      return DateTime(parsed.year, parsed.month, parsed.day);
  }
}
