import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../database/dates.dart';
import '../../providers/providers.dart';
import 'widgets/month_view.dart';
import 'widgets/week_view.dart';

/// Right pane: weekly/monthly overview of tasks and tracked time.
class CalendarPanel extends ConsumerWidget {
  const CalendarPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final view = ref.watch(calendarViewProvider);
    final anchor = ref.watch(calendarAnchorProvider);

    final rangeLabel = switch (view) {
      CalendarView.week => () {
        final monday = startOfWeek(anchor);
        return '${DateFormat.MMMd().format(monday)} - '
            '${DateFormat.MMMd().format(monday.add(const Duration(days: 6)))}';
      }(),
      CalendarView.month => DateFormat.yMMMM().format(anchor),
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            children: [
              SegmentedButton<CalendarView>(
                segments: const [
                  ButtonSegment(value: CalendarView.week, label: Text('Week')),
                  ButtonSegment(
                    value: CalendarView.month,
                    label: Text('Month'),
                  ),
                ],
                selected: {view},
                onSelectionChanged: (selection) =>
                    ref.read(calendarViewProvider.notifier).set(selection.first),
              ),
              IconButton(
                tooltip: 'Previous',
                icon: const Icon(Icons.chevron_left),
                onPressed: () => _navigate(ref, view, anchor, forward: false),
              ),
              Expanded(
                child: Text(
                  rangeLabel,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              IconButton(
                tooltip: 'Today',
                icon: const Icon(Icons.today),
                onPressed: () {
                  final now = DateTime.now();
                  final day = DateTime(now.year, now.month, now.day);
                  ref.read(calendarAnchorProvider.notifier).set(day);
                  ref.read(selectedDateProvider.notifier).set(day);
                },
              ),
              IconButton(
                tooltip: 'Next',
                icon: const Icon(Icons.chevron_right),
                onPressed: () => _navigate(ref, view, anchor, forward: true),
              ),
            ],
          ),
        ),
        Expanded(
          child: switch (view) {
            CalendarView.week => const WeekView(),
            CalendarView.month => const MonthView(),
          },
        ),
      ],
    );
  }

  void _navigate(
    WidgetRef ref,
    CalendarView view,
    DateTime anchor, {
    required bool forward,
  }) {
    final target = switch (view) {
      CalendarView.week => anchor.add(Duration(days: forward ? 7 : -7)),
      CalendarView.month => DateTime(
        anchor.year,
        anchor.month + (forward ? 1 : -1),
        1,
      ),
    };
    ref.read(calendarAnchorProvider.notifier).set(target);
  }
}
