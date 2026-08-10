/// UI-level state: which day is selected, which calendar view is shown,
/// which tag is filtered.
///
/// These are `StateProvider`s rather than `Notifier`s because they're
/// trivial single-value state. If they grow logic later, swap to
/// `NotifierProvider`.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../database/dates.dart';

/// Daily working-hours limit after which a warning is shown.
const workingHoursLimit = Duration(hours: 8);

/// Whether [duration] exceeds the daily working-hours limit.
bool isOverLimit(Duration duration) => duration > workingHoursLimit;

/// Available calendar views for the right pane.
enum CalendarView { week, month }

/// Currently selected day, shown in the left pane.
final selectedDateProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
});

/// Anchor date of the visible calendar in the right pane.
final calendarAnchorProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
});

/// Active calendar view of the right pane.
final calendarViewProvider = StateProvider<CalendarView>(
  (ref) => CalendarView.week,
);

/// Selected tag filter; null means "all".
final tagFilterProvider = StateProvider<int?>((ref) => null);

/// Increments whenever the tray requests the quick-add dialog.
///
/// Using a counter (rather than a boolean) makes the event idempotent:
/// every tray click produces a fresh event even if the dialog was already
/// shown and dismissed.
final quickAddRequestProvider = StateProvider<int>((ref) => 0);

/// Day-keys covered by the visible calendar (week or month).
final visibleDateKeysProvider = Provider<List<String>>((ref) {
  final anchor = ref.watch(calendarAnchorProvider);
  return switch (ref.watch(calendarViewProvider)) {
    CalendarView.week => weekKeys(anchor),
    CalendarView.month => monthKeys(anchor),
  };
});
