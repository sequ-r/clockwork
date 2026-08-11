/// Streams and computed views over tasks.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../database/database.dart';
import '../../database/dates.dart';
import 'database.dart';
import 'ui_state.dart';

final tasksForDateProvider = StreamProvider.family<List<Task>, String>((
  ref,
  date,
) {
  return ref.watch(taskDaoProvider).watchForDate(date);
});

final entriesForDateProvider = StreamProvider.family<List<TimeEntry>, String>((
  ref,
  date,
) {
  return ref.watch(timeEntryDaoProvider).watchForDate(date);
});

final tasksForSelectedDateProvider = StreamProvider<List<Task>>((ref) {
  final date = dateKey(ref.watch(selectedDateProvider));
  return ref.watch(taskDaoProvider).watchForDate(date);
});

final entriesForSelectedDateProvider = StreamProvider<List<TimeEntry>>((ref) {
  final date = dateKey(ref.watch(selectedDateProvider));
  return ref.watch(timeEntryDaoProvider).watchForDate(date).map((entries) {
    final sorted = [...entries];
    sorted.sort((a, b) => b.id.compareTo(a.id));
    return List<TimeEntry>.unmodifiable(sorted);
  });
});

/// Tasks of the visible calendar range.
final visibleTasksProvider = StreamProvider<List<Task>>((ref) {
  return ref
      .watch(taskDaoProvider)
      .watchDateRange(ref.watch(visibleDateKeysProvider));
});

/// Tasks of the selected day, filtered by the active tag.
final filteredTasksProvider = Provider<List<Task>>((ref) {
  final tasks = ref.watch(tasksForSelectedDateProvider).value ?? [];
  final filter = ref.watch(tagFilterProvider);
  if (filter == null) return tasks;
  return tasks.where((t) => t.tagId == filter).toList();
});
