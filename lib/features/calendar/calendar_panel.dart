import 'package:clockwork/core/di/app_dependencies.dart';
import 'package:clockwork/core/view_models/app_view_model.dart';
import 'package:clockwork/database/dates.dart';
import 'package:clockwork/features/calendar/calendar_view_model.dart';
import 'package:clockwork/features/calendar/widgets/month_view.dart';
import 'package:clockwork/features/calendar/widgets/week_view.dart';
import 'package:clockwork/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Right pane: weekly/monthly overview of tasks and tracked time.
class CalendarPanel extends StatefulWidget {
  /// Creates the calendar pane.
  const CalendarPanel({super.key});

  @override
  State<CalendarPanel> createState() => _CalendarPanelState();
}

class _CalendarPanelState extends State<CalendarPanel> {
  CalendarViewModel? _viewModel;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final deps = ClockworkScope.of(context);
    _viewModel ??= CalendarViewModel(
      taskRepository: deps.taskRepository,
      timeEntryRepository: deps.timeEntryRepository,
      tagRepository: deps.tagRepository,
      appViewModel: deps.appViewModel,
    );
  }

  @override
  void dispose() {
    _viewModel?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = _viewModel;
    if (viewModel == null) return const SizedBox.shrink();

    final l10n = AppLocalizations.of(context)!;

    return ListenableBuilder(
      listenable: viewModel,
      builder: (context, _) {
        final appVm = viewModel.appViewModel;
        final view = appVm.calendarViewMode;
        final anchor = appVm.calendarAnchor;

        final rangeLabel = switch (view) {
          CalendarView.week => () {
            final monday = startOfWeek(anchor);
            final sunday = monday.add(const Duration(days: 6));
            return '${DateFormat.MMMd().format(monday)} - '
                '${DateFormat.MMMd().format(sunday)}';
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
                    segments: [
                      ButtonSegment(
                        value: CalendarView.week,
                        label: Text(l10n.weekSegment),
                      ),
                      ButtonSegment(
                        value: CalendarView.month,
                        label: Text(l10n.monthSegment),
                      ),
                    ],
                    selected: {view},
                    onSelectionChanged: (selection) =>
                        appVm.setCalendarViewMode(selection.first),
                  ),
                  IconButton(
                    tooltip: l10n.previousTooltip,
                    icon: const Icon(Icons.chevron_left),
                    onPressed: () => viewModel.navigate(forward: false),
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
                    tooltip: l10n.todayTooltip,
                    icon: const Icon(Icons.today),
                    onPressed: viewModel.goToToday,
                  ),
                  IconButton(
                    tooltip: l10n.nextTooltip,
                    icon: const Icon(Icons.chevron_right),
                    onPressed: () => viewModel.navigate(forward: true),
                  ),
                ],
              ),
            ),
            Expanded(
              child: switch (view) {
                CalendarView.week => WeekView(viewModel: viewModel),
                CalendarView.month => MonthView(viewModel: viewModel),
              },
            ),
          ],
        );
      },
    );
  }
}
