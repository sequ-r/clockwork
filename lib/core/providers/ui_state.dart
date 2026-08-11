/// UI-level state: which day is selected, which calendar view is shown,
/// which tag is filtered.
///
/// Implemented as plain `Notifier`s so that reads and writes both go
/// through typed methods. The `@riverpod` codegen migration in Phase 4
/// will replace these with code-generated providers and `Ref` instances.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../database/dates.dart';

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
class SelectedDate extends Notifier<DateTime> {
  @override
  DateTime build() => _todayMidnight();

  /// Replaces the selected day, normalised to local midnight.
  void set(DateTime value) {
    state = DateTime(value.year, value.month, value.day);
  }
}

/// Provider for the currently selected day.
final selectedDateProvider = NotifierProvider<SelectedDate, DateTime>(
  SelectedDate.new,
);

/// Anchor date of the visible calendar in the right pane.
class CalendarAnchor extends Notifier<DateTime> {
  @override
  DateTime build() => _todayMidnight();

  /// Replaces the anchor day, normalised to local midnight.
  void set(DateTime value) {
    state = DateTime(value.year, value.month, value.day);
  }
}

/// Active calendar view of the right pane.
final calendarAnchorProvider = NotifierProvider<CalendarAnchor, DateTime>(
  CalendarAnchor.new,
);

/// Active calendar view of the right pane.
class CalendarViewMode extends Notifier<CalendarView> {
  @override
  CalendarView build() => CalendarView.week;

  /// Switches between week and month.
  void set(CalendarView value) => state = value;
}

/// Provider for the active calendar view (week or month).
final calendarViewProvider = NotifierProvider<CalendarViewMode, CalendarView>(
  CalendarViewMode.new,
);

/// Selected tag filter; null means "all".
class TagFilter extends Notifier<int?> {
  @override
  int? build() => null;

  /// Sets or clears the active tag filter.
  void set(int? value) => state = value;
}

/// Provider for the active tag filter; null means no filter.
final tagFilterProvider = NotifierProvider<TagFilter, int?>(TagFilter.new);

/// Increments whenever the tray requests the quick-add dialog.
///
/// Using a counter (rather than a boolean) makes the event idempotent:
/// every tray click produces a fresh event even if the dialog was already
/// shown and dismissed.
class QuickAddRequest extends Notifier<int> {
  @override
  int build() => 0;

  /// Fires a quick-add request, visible to listeners as a state change.
  void request() => state = state + 1;
}

/// Provider that emits a fresh event each time the tray wants to open
/// the quick-add dialog.
final quickAddRequestProvider = NotifierProvider<QuickAddRequest, int>(
  QuickAddRequest.new,
);

/// Day-keys covered by the visible calendar (week or month).
final visibleDateKeysProvider = Provider<List<String>>((ref) {
  final anchor = ref.watch(calendarAnchorProvider);
  return switch (ref.watch(calendarViewProvider)) {
    CalendarView.week => weekKeys(anchor),
    CalendarView.month => monthKeys(anchor),
  };
});
