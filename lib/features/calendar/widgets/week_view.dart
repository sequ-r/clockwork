import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../app/theme.dart';
import '../../../database/database.dart';
import '../../../database/dates.dart';
import '../../../providers/providers.dart';

/// Week overview: one column per day with tasks and tracked time.
class WeekView extends ConsumerWidget {
  const WeekView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final monday = startOfWeek(ref.watch(calendarAnchorProvider));
    final tasks = ref.watch(visibleTasksProvider).valueOrNull ?? [];
    final entries = ref.watch(visibleEntriesProvider).valueOrNull ?? [];
    final dailyTotals = ref.watch(dailyTotalsProvider);
    final tags = ref.watch(tagsProvider).valueOrNull ?? [];
    final tagById = {for (final t in tags) t.id: t};
    final filter = ref.watch(tagFilterProvider);
    final todayKey = dateKey(DateTime.now());
    final selectedKey = dateKey(ref.watch(selectedDateProvider));

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < 7; i++)
          Builder(
            builder: (context) {
              final day = monday.add(Duration(days: i));
              final key = dateKey(day);
              final dayTasks = tasks
                  .where(
                    (t) =>
                        t.date == key && (filter == null || t.tagId == filter),
                  )
                  .toList();
              final dayEntries =
                  entries
                      .where(
                        (e) =>
                            e.date == key &&
                            (filter == null || e.tagId == filter),
                      )
                      .toList()
                    ..sort((a, b) => a.id.compareTo(b.id));
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
            },
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
        margin: const EdgeInsets.all(kSpacingXs),
        decoration: BoxDecoration(
          color: isSelected
              ? colorScheme.primaryContainer.withAlpha(80)
              : colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(kRadiusMedium),
          border: Border.all(
            color: isToday ? colorScheme.primary : Colors.transparent,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(kSpacingSm),
              child: Column(
                children: [
                  Text(
                    DateFormat.E().format(date),
                    style: theme.textTheme.labelMedium,
                  ),
                  Text(
                    '${date.day}',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: isToday ? colorScheme.primary : null,
                      fontWeight: isToday ? FontWeight.bold : null,
                    ),
                  ),
                  const SizedBox(height: kSpacingXs),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          total == Duration.zero ? '-' : formatDuration(total),
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: colorScheme.primary,
                          ),
                        ),
                        if (isOverLimit(total)) ...[
                          const SizedBox(width: 4),
                          Tooltip(
                            message:
                                'Over the '
                                '${workingHoursLimit.inHours}h working limit',
                            child: Icon(
                              Icons.warning_amber_rounded,
                              size: 16,
                              color: colorScheme.error,
                            ),
                          ),
                        ],
                      ],
                    ),
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
                        horizontal: 6,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest.withAlpha(
                          120,
                        ),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 4,
                            backgroundColor: entry.tagId == null
                                ? Colors.grey
                                : Color(
                                    tagById[entry.tagId]?.color ?? 0xFF888888,
                                  ),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              '${formatDuration(Duration(minutes: entry.minutes))}'
                              '${entry.notes != null ? ' - ${entry.notes}' : ''}',
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
