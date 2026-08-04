/// Date helpers shared by GUI and CLI.
library;

String dateKey(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-'
    '${date.month.toString().padLeft(2, '0')}-'
    '${date.day.toString().padLeft(2, '0')}';

DateTime dateFromKey(String key) => DateTime.parse(key);

/// Monday of the week containing [date].
DateTime startOfWeek(DateTime date) {
  final d = DateTime(date.year, date.month, date.day);
  return d.subtract(Duration(days: d.weekday - DateTime.monday));
}

/// All seven day-keys of the week containing [date].
List<String> weekKeys(DateTime date) {
  final monday = startOfWeek(date);
  return List.generate(7, (i) => dateKey(monday.add(Duration(days: i))));
}

Duration entryDuration(DateTime start, DateTime end) => end.difference(start);

String formatDuration(Duration d) {
  final h = d.inHours;
  final m = d.inMinutes.remainder(60);
  if (h == 0) return '${m}m';
  return '${h}h ${m.toString().padLeft(2, '0')}m';
}
