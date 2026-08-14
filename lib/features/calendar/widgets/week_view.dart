import 'package:clockwork/app/theme.dart';
import 'package:clockwork/core/view_models/app_view_model.dart';
import 'package:clockwork/database/database.dart';
import 'package:clockwork/database/dates.dart';
import 'package:clockwork/features/calendar/calendar_view_model.dart';
import 'package:clockwork/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Renders a time entry as `1h 30m - notes` (notes omitted when empty).
String _entryLabel(TimeEntry entry) {
  final minutes = formatDuration(Duration(minutes: entry.minutes));
  return entry.notes == null ? minutes : '$minutes - ${entry.notes}';
}

/// Week overview: one column per day with tasks and tracked time.
class WeekView extends StatelessWidget {
  /// Creates the week overview pane.
  const WeekView({super.key, required this.viewModel});

  /// The calendar view model.
  final CalendarViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final appVm = viewModel.appViewModel;
    final monday = startOfWeek(appVm.calendarAnchor);
    final tasks = viewModel.tasks;
    final entries = viewModel.entries;
    final dailyTotals = viewModel.dailyTotals;
    final tags = viewModel.tags;
    final tagById = {for (final t in tags) t.id: t};
    final filter = appVm.tagFilter;
    final todayKey = dateKey(DateTime.now());
    final selectedKey = dateKey(appVm.selectedDate);

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
                  onTap: () => appVm.setSelectedDate(day),
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
    final l10n = AppLocalizations.of(context)!;
    final semanticsLabel =
        '${DateFormat.EEEE().format(date)}, ${date.day}, '
        '${tasks.length} tasks, ${formatDuration(total)} tracked'
        '${isSelected ? ", selected" : ""}${isToday ? ", today" : ""}';

    return Semantics(
      button: true,
      label: semanticsLabel,
      selected: isSelected,
      child: GestureDetector(
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
                            total == Duration.zero
                                ? '-'
                                : formatDuration(total),
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: colorScheme.primary,
                            ),
                          ),
                          if (isOverLimit(total)) ...[
                            const SizedBox(width: 4),
                            Tooltip(
                              message: l10n.overLimitTooltip(
                                workingHoursLimit.inHours,
                              ),
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
                                _entryLabel(entry),
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
      ),
    );
  }
}
