import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../database/database.dart';
import '../database/dates.dart';
import '../providers/providers.dart';

class WeekView extends ConsumerWidget {
  const WeekView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final anchor = ref.watch(weekAnchorProvider);
    final monday = startOfWeek(anchor);
    final sunday = monday.add(const Duration(days: 6));
    final tasks = ref.watch(weekTasksProvider).valueOrNull ?? [];
    final entries = ref.watch(weekEntriesProvider).valueOrNull ?? [];
    final dailyTotals = ref.watch(dailyTotalsProvider);
    final tags = ref.watch(tagsProvider).valueOrNull ?? [];
    final tagById = {for (final t in tags) t.id: t};
    final filter = ref.watch(tagFilterProvider);
    final todayKey = dateKey(DateTime.now());
    final selectedKey = dateKey(ref.watch(selectedDateProvider));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: Row(
            children: [
              IconButton(
                tooltip: 'Previous week',
                icon: const Icon(Icons.chevron_left),
                onPressed: () {
                  final notifier = ref.read(weekAnchorProvider.notifier);
                  notifier.state =
                      notifier.state.subtract(const Duration(days: 7));
                },
              ),
              Expanded(
                child: Text(
                  '${DateFormat.MMMd().format(monday)} - '
                  '${DateFormat.MMMd().format(sunday)}',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              IconButton(
                tooltip: 'Today',
                icon: const Icon(Icons.today),
                onPressed: () {
                  final now = DateTime.now();
                  final day = DateTime(now.year, now.month, now.day);
                  ref.read(weekAnchorProvider.notifier).state = day;
                  ref.read(selectedDateProvider.notifier).state = day;
                },
              ),
              IconButton(
                tooltip: 'Next week',
                icon: const Icon(Icons.chevron_right),
                onPressed: () {
                  final notifier = ref.read(weekAnchorProvider.notifier);
                  notifier.state = notifier.state.add(const Duration(days: 7));
                },
              ),
            ],
          ),
        ),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < 7; i++)
                Builder(builder: (context) {
                  final day = monday.add(Duration(days: i));
                  final key = dateKey(day);
                  final dayTasks = tasks
                      .where((t) =>
                          t.date == key &&
                          (filter == null || t.tagId == filter))
                      .toList();
                  final dayEntries = entries
                      .where((e) =>
                          dateKey(e.start) == key &&
                          (filter == null || e.tagId == filter))
                      .toList()
                    ..sort((a, b) => a.start.compareTo(b.start));
                  return Expanded(
                    child: _DayColumn(
                      date: day,
                      isSelected: key == selectedKey,
                      isToday: key == todayKey,
                      tasks: dayTasks,
                      entries: dayEntries,
                      total: dailyTotals[key] ?? Duration.zero,
                      tagById: tagById,
                      onTap: () =>
                          ref.read(selectedDateProvider.notifier).state = day,
                    ),
                  );
                }),
            ],
          ),
        ),
      ],
    );
  }
}

class _DayColumn extends StatelessWidget {
  const _DayColumn({
    required this.date,
    required this.isSelected,
    required this.isToday,
    required this.tasks,
    required this.entries,
    required this.total,
    required this.tagById,
    required this.onTap,
  });

  final DateTime date;
  final bool isSelected;
  final bool isToday;
  final List<Task> tasks;
  final List<TimeEntry> entries;
  final Duration total;
  final Map<int, Tag> tagById;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: isSelected
              ? colorScheme.primaryContainer.withAlpha(80)
              : colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isToday ? colorScheme.primary : Colors.transparent,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                children: [
                  Text(DateFormat.E().format(date),
                      style: theme.textTheme.labelMedium),
                  Text(
                    '${date.day}',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: isToday ? colorScheme.primary : null,
                      fontWeight: isToday ? FontWeight.bold : null,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    total == Duration.zero ? '-' : formatDuration(total),
                    style: theme.textTheme.labelLarge
                        ?.copyWith(color: colorScheme.primary),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(6),
                children: [
                  for (final task in tasks)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          Icon(
                            task.done
                                ? Icons.check_circle
                                : Icons.radio_button_unchecked,
                            size: 14,
                            color: task.done
                                ? colorScheme.primary
                                : colorScheme.outline,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              task.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall?.copyWith(
                                decoration: task.done
                                    ? TextDecoration.lineThrough
                                    : null,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  for (final entry in entries)
                    Container(
                      margin: const EdgeInsets.only(bottom: 4),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest
                            .withAlpha(120),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 4,
                            backgroundColor: entry.tagId == null
                                ? Colors.grey
                                : Color(tagById[entry.tagId]?.color ??
                                    0xFF888888),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              '${DateFormat.Hm().format(entry.start)}-'
                              '${DateFormat.Hm().format(entry.end)} '
                              '(${formatDuration(entryDuration(entry.start, entry.end))})',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
