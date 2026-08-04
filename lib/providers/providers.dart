import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database/app_database.dart';
import '../database/database.dart';
import '../database/dates.dart';

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

/// Currently selected day in the task panel.
final selectedDateProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
});

/// Anchor of the visible week in the calendar view.
final weekAnchorProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
});

/// Selected tag filter; null means "all".
final tagFilterProvider = StateProvider<int?>((ref) => null);

final tasksForSelectedDateProvider = StreamProvider<List<Task>>((ref) {
  final date = dateKey(ref.watch(selectedDateProvider));
  return ref.watch(taskDaoProvider).watchForDate(date);
});

final tasksForDateProvider =
    StreamProvider.family<List<Task>, String>((ref, date) {
  return ref.watch(taskDaoProvider).watchForDate(date);
});

final weekTasksProvider = StreamProvider<List<Task>>((ref) {
  final anchor = ref.watch(weekAnchorProvider);
  return ref.watch(taskDaoProvider).watchDateRange(weekKeys(anchor));
});

final weekEntriesProvider = StreamProvider<List<TimeEntry>>((ref) {
  final monday = startOfWeek(ref.watch(weekAnchorProvider));
  final end = monday.add(const Duration(days: 7));
  return ref.watch(timeEntryDaoProvider).watchRange(monday, end);
});

/// Tasks of the selected day filtered by the active tag.
final filteredTasksProvider = Provider<List<Task>>((ref) {
  final tasks = ref.watch(tasksForSelectedDateProvider).valueOrNull ?? [];
  final filter = ref.watch(tagFilterProvider);
  if (filter == null) return tasks;
  return tasks.where((t) => t.tagId == filter).toList();
});

/// Total time tracked on the visible week.
final weekTotalProvider = Provider<Duration>((ref) {
  final entries = ref.watch(weekEntriesProvider).valueOrNull ?? [];
  return entries.fold<Duration>(
      Duration.zero, (sum, e) => sum + entryDuration(e.start, e.end));
});

/// Total tracked time per day-key of the visible week.
final dailyTotalsProvider = Provider<Map<String, Duration>>((ref) {
  final entries = ref.watch(weekEntriesProvider).valueOrNull ?? [];
  final totals = <String, Duration>{};
  for (final e in entries) {
    final key = dateKey(e.start);
    totals[key] = (totals[key] ?? Duration.zero) +
        entryDuration(e.start, e.end);
  }
  return totals;
});

/// Tracked time per tag-id of the visible week.
final weeklyTagTotalsProvider = Provider<Map<int, Duration>>((ref) {
  final entries = ref.watch(weekEntriesProvider).valueOrNull ?? [];
  final totals = <int, Duration>{};
  for (final e in entries) {
    final tagId = e.tagId;
    if (tagId == null) continue;
    totals[tagId] =
        (totals[tagId] ?? Duration.zero) + entryDuration(e.start, e.end);
  }
  return totals;
});
