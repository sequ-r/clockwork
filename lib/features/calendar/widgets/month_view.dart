import 'package:clockwork/app/theme.dart';
import 'package:clockwork/core/view_models/app_view_model.dart';
import 'package:clockwork/database/dates.dart';
import 'package:clockwork/features/calendar/calendar_view_model.dart';
import 'package:clockwork/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';

/// Month overview: calendar grid with per-day totals and task counts.
class MonthView extends StatelessWidget {
  /// Creates the month overview pane.
  const MonthView({super.key, required this.viewModel});

  /// The calendar view model.
  final CalendarViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final appVm = viewModel.appViewModel;
    final anchor = appVm.calendarAnchor;
    final firstOfMonth = DateTime(anchor.year, anchor.month, 1);
    final daysInMonth = DateTime(anchor.year, anchor.month + 1, 0).day;
    // Monday-first week: how many blanks to insert before day 1?
    final leadingBlanks = firstOfMonth.weekday - DateTime.monday;
    final tasks = viewModel.tasks;
    final dailyTotals = viewModel.dailyTotals;
    final filter = appVm.tagFilter;
    final todayKey = dateKey(DateTime.now());
    final selectedKey = dateKey(appVm.selectedDate);

    final taskCounts = <String, int>{};
    for (final task in tasks) {
      if (filter != null && task.tagId != filter) continue;
      taskCounts[task.date] = (taskCounts[task.date] ?? 0) + 1;
    }

    final cells = <Widget>[
      for (var i = 0; i < leadingBlanks; i++) const _EmptyCell(),
      for (var day = 1; day <= daysInMonth; day++)
        Builder(
          builder: (context) {
            final date = DateTime(anchor.year, anchor.month, day);
            final key = dateKey(date);
            return _DayCell(
              date: date,
              total: dailyTotals[key] ?? Duration.zero,
              taskCount: taskCounts[key] ?? 0,
              isToday: key == todayKey,
              isSelected: key == selectedKey,
              onTap: () => appVm.setSelectedDate(date),
            );
          },
        ),
    ];
    while (cells.length % 7 != 0) {
      cells.add(const _EmptyCell());
    }

    const weekdaySymbols = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return Padding(
      padding: const EdgeInsets.all(kSpacingSm),
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
          const SizedBox(height: kSpacingXs),
          Expanded(
            child: GridView.count(
              crossAxisCount: 7,
              childAspectRatio: 1.0,
              physics: const NeverScrollableScrollPhysics(),
              children: cells,
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
    final l10n = AppLocalizations.of(context)!;
    final semanticsLabel =
        '${date.day}, $taskCount tasks, ${formatDuration(total)} tracked'
        '${isSelected ? ", selected" : ""}${isToday ? ", today" : ""}';

    return Semantics(
      button: true,
      label: semanticsLabel,
      selected: isSelected,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.all(2),
          padding: const EdgeInsets.all(kSpacingXs + 2),
          decoration: BoxDecoration(
            color: isSelected
                ? colorScheme.primaryContainer.withAlpha(80)
                : colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(kRadiusSmall + 2),
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
                      '$taskCount ${taskCount == 1 ? "task" : "tasks"}',
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
                        color: overLimit
                            ? colorScheme.error
                            : colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (overLimit) ...[
                      const SizedBox(width: 2),
                      Tooltip(
                        message: l10n.overLimitTooltip(
                          workingHoursLimit.inHours,
                        ),
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
      ),
    );
  }
}
