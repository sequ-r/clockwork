import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database/app_database.dart';
import '../database/database.dart';
import '../database/dates.dart';

/// Daily working-hours limit after which a warning is shown.
const workingHoursLimit = Duration(hours: 8);

/// Whether [duration] exceeds the daily working-hours limit.
bool isOverLimit(Duration duration) => duration > workingHoursLimit;

/// Available calendar views for the right pane.
enum CalendarView { week, month }

final databaseProvider = Provider<ClockworkDatabase>((ref) {
  final db = openDatabase();
  ref.onDispose(db.close);
  return db;
});

final tagDaoProvider = Provider((ref) => ref.watch(databaseProvider).tagDao);
final taskDaoProvider =
    Provider((ref) => ref.watch(databaseProvider).taskDao);
final timeEntryDaoProvider =
    Provider((ref) => ref.watch(databaseProvider).timeEntryDao);

final tagsProvider =
    StreamProvider<List<Tag>>((ref) => ref.watch(tagDaoProvider).watchAll());

/// Currently selected day, shown in the left pane.
final selectedDateProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
});

/// Anchor date of the visible calendar in the right pane.
final calendarAnchorProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
});

/// Active calendar view of the right pane.
final calendarViewProvider =
    StateProvider<CalendarView>((ref) => CalendarView.week);

/// Selected tag filter; null means "all".
final tagFilterProvider = StateProvider<int?>((ref) => null);

/// Increments whenever the tray requests the quick-add dialog.
final quickAddRequestProvider = StateProvider<int>((ref) => 0);

/// Day-keys covered by the visible calendar (week or month).
final visibleDateKeysProvider = Provider<List<String>>((ref) {
  final anchor = ref.watch(calendarAnchorProvider);
  return switch (ref.watch(calendarViewProvider)) {
    CalendarView.week => weekKeys(anchor),
    CalendarView.month => monthKeys(anchor),
  };
});

final tasksForDateProvider =
    StreamProvider.family<List<Task>, String>((ref, date) {
  return ref.watch(taskDaoProvider).watchForDate(date);
});

final entriesForDateProvider =
    StreamProvider.family<List<TimeEntry>, String>((ref, date) {
  return ref.watch(timeEntryDaoProvider).watchForDate(date);
});

final tasksForSelectedDateProvider = StreamProvider<List<Task>>((ref) {
  final date = dateKey(ref.watch(selectedDateProvider));
  return ref.watch(taskDaoProvider).watchForDate(date);
});

final entriesForSelectedDateProvider = StreamProvider<List<TimeEntry>>((ref) {
  final date = dateKey(ref.watch(selectedDateProvider));
  return ref.watch(timeEntryDaoProvider).watchForDate(date);
});

/// Tasks of the visible calendar range.
final visibleTasksProvider = StreamProvider<List<Task>>((ref) {
  return ref
      .watch(taskDaoProvider)
      .watchDateRange(ref.watch(visibleDateKeysProvider));
});

/// Time entries of the visible calendar range.
final visibleEntriesProvider = StreamProvider<List<TimeEntry>>((ref) {
  return ref
      .watch(timeEntryDaoProvider)
      .watchDateRange(ref.watch(visibleDateKeysProvider));
});

/// Tasks of the selected day, filtered by the active tag.
final filteredTasksProvider = Provider<List<Task>>((ref) {
  final tasks = ref.watch(tasksForSelectedDateProvider).valueOrNull ?? [];
  final filter = ref.watch(tagFilterProvider);
  if (filter == null) return tasks;
  return tasks.where((t) => t.tagId == filter).toList();
});

/// Total tracked time of the selected day.
final selectedDateTotalProvider = Provider<Duration>((ref) {
  final entries = ref.watch(entriesForSelectedDateProvider).valueOrNull ?? [];
  return totalMinutes(entries.map((e) => e.minutes));
});

/// Total tracked time of the visible calendar range.
final visibleTotalProvider = Provider<Duration>((ref) {
  final entries = ref.watch(visibleEntriesProvider).valueOrNull ?? [];
  return totalMinutes(entries.map((e) => e.minutes));
});

/// Total tracked time per day-key of the visible calendar range.
final dailyTotalsProvider = Provider<Map<String, Duration>>((ref) {
  final entries = ref.watch(visibleEntriesProvider).valueOrNull ?? [];
  final totals = <String, Duration>{};
  for (final entry in entries) {
    totals[entry.date] = (totals[entry.date] ?? Duration.zero) +
        Duration(minutes: entry.minutes);
  }
  return totals;
});

/// Tracked time per task-id, over all time, for the selected day's tasks.
final taskHoursProvider = Provider<AsyncValue<Map<int, Duration>>>((ref) {
  final tasks = ref.watch(tasksForSelectedDateProvider).valueOrNull ?? [];
  if (tasks.isEmpty) {
    return const AsyncData(<int, Duration>{});
  }
  final key = tasks.map((t) => t.id).join(',');
  return ref.watch(_taskEntriesProvider(key));
});

final _taskEntriesProvider =
    StreamProvider.family.autoDispose<Map<int, Duration>, String>(
        (ref, taskIdsKey) {
  final taskIds = taskIdsKey.split(',').map(int.parse);
  return ref
      .watch(timeEntryDaoProvider)
      .watchForTaskIds(taskIds)
      .map((entries) {
    final totals = <int, Duration>{};
    for (final entry in entries) {
      final taskId = entry.taskId;
      if (taskId == null) continue;
      totals[taskId] = (totals[taskId] ?? Duration.zero) +
          Duration(minutes: entry.minutes);
    }
    return totals;
  });
});

/// Tracked time per tag-id of the visible calendar range.
final visibleTagTotalsProvider = Provider<Map<int, Duration>>((ref) {
  final entries = ref.watch(visibleEntriesProvider).valueOrNull ?? [];
  final totals = <int, Duration>{};
  for (final entry in entries) {
    final tagId = entry.tagId;
    if (tagId == null) continue;
    totals[tagId] =
        (totals[tagId] ?? Duration.zero) + Duration(minutes: entry.minutes);
  }
  return totals;
});
