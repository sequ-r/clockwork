import 'package:clockwork/database/database.dart';

/// Repository managing logged time entries and daily/range aggregates.
class TimeEntryRepository {
  /// Creates the repository with [timeEntryDao].
  const TimeEntryRepository({required this.timeEntryDao});

  /// Data access object for time entries.
  final TimeEntryDao timeEntryDao;

  /// Reactive stream of time entries logged on [date] (`YYYY-MM-DD`).
  Stream<List<TimeEntry>> watchForDate(String date) =>
      timeEntryDao.watchForDate(date);

  /// Reactive stream of time entries logged on any of [dates].
  Stream<List<TimeEntry>> watchDateRange(Iterable<String> dates) =>
      timeEntryDao.watchDateRange(dates);

  /// One-shot fetch of time entries logged on [date].
  Future<List<TimeEntry>> getForDate(String date) =>
      timeEntryDao.getForDate(date);

  /// Reactive stream of time entries for specific [taskIds].
  Stream<List<TimeEntry>> watchForTaskIds(Iterable<int> taskIds) =>
      timeEntryDao.watchForTaskIds(taskIds);

  /// Inserts a new time entry and returns the inserted row ID.
  Future<int> createEntry(TimeEntriesCompanion companion) =>
      timeEntryDao.createEntry(companion);

  /// Replaces [entry] in the database.
  Future<bool> updateEntry(TimeEntry entry) => timeEntryDao.updateEntry(entry);

  /// Deletes the time entry matching [id].
  Future<int> deleteEntry(int id) => timeEntryDao.deleteEntry(id);

  /// Removes [minutes] of tracked time from [date], trimming the most
  /// recently logged entries first.
  ///
  /// Entries are shrunk in place; entries whose minutes are fully consumed
  /// are deleted. If [minutes] exceeds the logged total for the day, all
  /// entries for that day are removed.
  Future<void> removeMinutesFromDay(String date, int minutes) async {
    if (minutes <= 0) return;
    final entries = await getForDate(date)
      ..sort((a, b) => b.id.compareTo(a.id));
    var remaining = minutes;
    for (final entry in entries) {
      if (remaining <= 0) break;
      final kept = entry.minutes - remaining;
      if (kept <= 0) {
        await deleteEntry(entry.id);
      } else {
        await updateEntry(entry.copyWith(minutes: kept));
      }
      remaining -= entry.minutes;
    }
  }
}
