/// UI-level state: which day is selected, which calendar view is shown,
/// which tag is filtered.
///
/// Implemented as code-generated `@riverpod` notifiers. Reads go through
/// the typed providers; writes go through the generated `.notifier`.
library;

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../database/dates.dart';

part 'ui_state.g.dart';

/// Daily working-hours limit after which a warning is shown.
const workingHoursLimit = Duration(hours: 8);

/// Whether [duration] exceeds the daily working-hours limit.
bool isOverLimit(Duration duration) => duration > workingHoursLimit;

/// Available calendar views for the right pane.
enum CalendarView {
  /// Seven-day view, anchored on the week's Monday.
  week,

  /// Month grid, anchored on the first of the month.
  month,
}

DateTime _todayMidnight() {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
}

/// Currently selected day, shown in the left pane.
@Riverpod(keepAlive: true)
class SelectedDate extends _$SelectedDate {
  @override
  DateTime build() => _todayMidnight();

  /// Replaces the selected day, normalised to local midnight.
  void set(DateTime value) {
    state = DateTime(value.year, value.month, value.day);
  }
}

/// Anchor date of the visible calendar in the right pane.
@Riverpod(keepAlive: true)
class CalendarAnchor extends _$CalendarAnchor {
  @override
  DateTime build() => _todayMidnight();

  /// Replaces the anchor day, normalised to local midnight.
  void set(DateTime value) {
    state = DateTime(value.year, value.month, value.day);
  }
}

/// Active calendar view of the right pane.
@Riverpod(keepAlive: true)
class CalendarViewMode extends _$CalendarViewMode {
  @override
  CalendarView build() => CalendarView.week;

  /// Switches between week and month.
  void set(CalendarView value) => state = value;
}

/// Selected tag filter; null means "all".
@Riverpod(keepAlive: true)
class TagFilter extends _$TagFilter {
  @override
  int? build() => null;

  /// Sets or clears the active tag filter.
  void set(int? value) => state = value;
}

/// Increments whenever the tray requests the quick-add dialog.
///
/// Using a counter (rather than a boolean) makes the event idempotent:
/// every tray click produces a fresh event even if the dialog was already
/// shown and dismissed.
@Riverpod(keepAlive: true)
class QuickAddRequest extends _$QuickAddRequest {
  @override
  int build() => 0;

  /// Fires a quick-add request, visible to listeners as a state change.
  void request() => state = state + 1;
}

/// Index of the active tab in the narrow layout.
///
/// Hoisted into a provider so the selection survives the wide→narrow
/// layout transition (which otherwise remounts the tab widget and resets
/// the index).
@Riverpod(keepAlive: true)
class HomeTab extends _$HomeTab {
  @override
  int build() => 0;

  /// Switches to [index] (0 = Today, 1 = Calendar).
  void set(int index) => state = index;
}

/// Modes for standalone popup windows opened from the system tray.
enum TrayPopupMode {
  /// Normal main window view.
  none,

  /// Compact popup window for quick time entry.
  quickAdd,

  /// Compact popup window for managing projects.
  manageProjects,
}

/// Active popup window mode opened from the system tray.
@Riverpod(keepAlive: true)
class ActiveTrayPopup extends _$ActiveTrayPopup {
  @override
  TrayPopupMode build() => TrayPopupMode.none;

  /// Sets the active tray popup mode.
  void set(TrayPopupMode mode) => state = mode;
}

/// Day-keys covered by the visible calendar (week or month).
@Riverpod(keepAlive: true)
List<String> visibleDateKeys(Ref ref) {
  final anchor = ref.watch(calendarAnchorProvider);
  return switch (ref.watch(calendarViewModeProvider)) {
    CalendarView.week => weekKeys(anchor),
    CalendarView.month => monthKeys(anchor),
  };
}
