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

  /// Deletes the time entry matching [id].
  Future<int> deleteEntry(int id) => timeEntryDao.deleteEntry(id);
}
