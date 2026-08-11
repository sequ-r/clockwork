/// Streams and computed views over time entries, plus per-tag/per-task
/// aggregates.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../database/database.dart';
import '../../database/dates.dart';
import 'database.dart';
import 'tasks.dart';
import 'ui_state.dart';

/// Time entries of the visible calendar range.
final visibleEntriesProvider = StreamProvider<List<TimeEntry>>((ref) {
  return ref
      .watch(timeEntryDaoProvider)
      .watchDateRange(ref.watch(visibleDateKeysProvider));
});

/// Total tracked time of the selected day.
final selectedDateTotalProvider = Provider<Duration>((ref) {
  final entries = ref.watch(entriesForSelectedDateProvider).value ?? [];
  return totalMinutes(entries.map((e) => e.minutes));
});

/// Total tracked time of the visible calendar range.
final visibleTotalProvider = Provider<Duration>((ref) {
  final entries = ref.watch(visibleEntriesProvider).value ?? [];
  return totalMinutes(entries.map((e) => e.minutes));
});

/// Total tracked time per day-key of the visible calendar range.
final dailyTotalsProvider = Provider<Map<String, Duration>>((ref) {
  final entries = ref.watch(visibleEntriesProvider).value ?? [];
  final totals = <String, Duration>{};
  for (final entry in entries) {
    totals[entry.date] =
        (totals[entry.date] ?? Duration.zero) +
        Duration(minutes: entry.minutes);
  }
  return totals;
});

/// Tracked time per task-id, over all time, for the selected day's tasks.
final taskHoursProvider = Provider<AsyncValue<Map<int, Duration>>>((ref) {
  final tasks = ref.watch(tasksForSelectedDateProvider).value ?? [];
  if (tasks.isEmpty) {
    return const AsyncData(<int, Duration>{});
  }
  final key = tasks.map((t) => t.id).join(',');
  return ref.watch(_taskEntriesProvider(key));
});

final _taskEntriesProvider = StreamProvider.family
    .autoDispose<Map<int, Duration>, String>((ref, taskIdsKey) {
      final taskIds = taskIdsKey.split(',').map(int.parse);
      return ref.watch(timeEntryDaoProvider).watchForTaskIds(taskIds).map((
        entries,
      ) {
        final totals = <int, Duration>{};
        for (final entry in entries) {
          final taskId = entry.taskId;
          if (taskId == null) continue;
          totals[taskId] =
              (totals[taskId] ?? Duration.zero) +
              Duration(minutes: entry.minutes);
        }
        return totals;
      });
    });

/// Tracked time per tag-id of the visible calendar range.
final visibleTagTotalsProvider = Provider<Map<int, Duration>>((ref) {
  final entries = ref.watch(visibleEntriesProvider).value ?? [];
  final totals = <int, Duration>{};
  for (final entry in entries) {
    final tagId = entry.tagId;
    if (tagId == null) continue;
    totals[tagId] =
        (totals[tagId] ?? Duration.zero) + Duration(minutes: entry.minutes);
  }
  return totals;
});
