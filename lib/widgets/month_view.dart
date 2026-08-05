import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database/dates.dart';
import '../providers/providers.dart';

/// Month overview: calendar grid with per-day totals and task counts.
class MonthView extends ConsumerWidget {
  const MonthView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final anchor = ref.watch(calendarAnchorProvider);
    final firstOfMonth = DateTime(anchor.year, anchor.month, 1);
    final daysInMonth = DateTime(anchor.year, anchor.month + 1, 0).day;
    final leadingBlanks = firstOfMonth.weekday - DateTime.monday;
    final tasks = ref.watch(visibleTasksProvider).valueOrNull ?? [];
    final dailyTotals = ref.watch(dailyTotalsProvider);
    final filter = ref.watch(tagFilterProvider);
    final todayKey = dateKey(DateTime.now());
    final selectedKey = dateKey(ref.watch(selectedDateProvider));

    final taskCounts = <String, int>{};
    for (final task in tasks) {
      if (filter != null && task.tagId != filter) continue;
      taskCounts[task.date] = (taskCounts[task.date] ?? 0) + 1;
    }

    final cells = <Widget>[
      for (var i = 0; i < leadingBlanks; i++) const _EmptyCell(),
      for (var day = 1; day <= daysInMonth; day++)
        Builder(builder: (context) {
          final date = DateTime(anchor.year, anchor.month, day);
          final key = dateKey(date);
          return _DayCell(
            date: date,
            total: dailyTotals[key] ?? Duration.zero,
            taskCount: taskCounts[key] ?? 0,
            isToday: key == todayKey,
            isSelected: key == selectedKey,
            onTap: () {
              ref.read(selectedDateProvider.notifier).state = date;
            },
          );
        }),
    ];
    final rowCount = ((leadingBlanks + daysInMonth) / 7).ceil();
    while (cells.length < rowCount * 7) {
      cells.add(const _EmptyCell());
    }

    const weekdaySymbols = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return Padding(
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              for (final symbol in weekdaySymbols)
                Expanded(
                  child: Center(
                    child: Text(
                      symbol,
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Expanded(
            child: Column(
              children: [
                for (var row = 0; row < rowCount; row++)
                  Expanded(
                    child: Row(
                      children: [
                        for (var col = 0; col < 7; col++)
                          Expanded(child: cells[row * 7 + col]),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyCell extends StatelessWidget {
  const _EmptyCell();

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.date,
    required this.total,
    required this.taskCount,
    required this.isToday,
    required this.isSelected,
    required this.onTap,
  });

  final DateTime date;
  final Duration total;
  final int taskCount;
  final bool isToday;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final overLimit = isOverLimit(total);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.all(2),
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: isSelected
              ? colorScheme.primaryContainer.withAlpha(80)
              : colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isToday ? colorScheme.primary : Colors.transparent,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  '${date.day}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: isToday ? FontWeight.bold : null,
                    color: isToday ? colorScheme.primary : null,
                  ),
                ),
                const Spacer(),
                if (taskCount > 0)
                  Text(
                    '$taskCount ${taskCount == 1 ? 'task' : 'tasks'}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.outline,
                    ),
                  ),
              ],
            ),
            const Spacer(),
            if (total > Duration.zero)
              Row(
                children: [
                  Text(
                    formatDuration(total),
                    style: theme.textTheme.labelMedium?.copyWith(
                      color:
                          overLimit ? colorScheme.error : colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (overLimit) ...[
                    const SizedBox(width: 2),
                    Tooltip(
                      message: 'Over the '
                          '${workingHoursLimit.inHours}h working limit',
                      child: Icon(
                        Icons.warning_amber_rounded,
                        size: 14,
                        color: colorScheme.error,
                      ),
                    ),
                  ],
                ],
              ),
          ],
        ),
      ),
    );
  }
}
