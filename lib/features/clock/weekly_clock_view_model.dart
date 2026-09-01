import 'dart:async';

import 'package:clockwork/data/repositories/time_entry_repository.dart';
import 'package:clockwork/database/database.dart';
import 'package:clockwork/database/dates.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/foundation.dart';

/// Step size for the clock stepper, in minutes.
const clockStepMinutes = 30;

/// Smallest pending amount selectable on the clock stepper, in minutes.
const clockMinPendingMinutes = -12 * 60;

/// Largest pending amount selectable on the clock stepper, in minutes.
const clockMaxPendingMinutes = 24 * 60;

/// Formats [minutes] as an `HH:MM:SS` clock string.
///
/// Seconds are always `00` because tracked time is minute-based.
String formatClockHHmmss(int minutes) {
  final sign = minutes < 0 ? '-' : '';
  final abs = minutes.abs();
  final h = (abs ~/ 60).toString().padLeft(2, '0');
  final m = (abs % 60).toString().padLeft(2, '0');
  return '$sign$h:$m:00';
}

/// Formats a pending amount (minutes) like `0.5h` or `-1.5h`.
String formatPendingHours(int minutes) {
  final hours = minutes / 60;
  final text = hours == hours.roundToDouble()
      ? hours.abs().toInt().toString()
      : hours.abs().toString();
  return '${hours < 0 ? '-' : ''}${text}h';
}

/// View model for the weekly clock screen: shows the live total of
/// worked hours for the current week and commits add/remove amounts.
class WeeklyClockViewModel extends ChangeNotifier {
  /// Creates the view model and starts watching the current week.
  WeeklyClockViewModel({required this.repository}) {
    _subscription = repository
        .watchDateRange(weekKeys(DateTime.now()))
        .listen(_onEntries);
  }

  /// Repository backing the weekly totals and entry mutations.
  final TimeEntryRepository repository;
  late final StreamSubscription<List<TimeEntry>> _subscription;
  int _weekTotalMinutes = 0;
  int _pendingMinutes = clockStepMinutes;

  /// Total minutes logged in the current week.
  int get weekTotalMinutes => _weekTotalMinutes;

  /// The week total formatted as `HH:MM:SS`.
  String get weekTotalLabel => formatClockHHmmss(_weekTotalMinutes);

  /// The pending amount to add (positive) or remove (negative), minutes.
  int get pendingMinutes => _pendingMinutes;

  /// The pending amount formatted like `0.5h`.
  String get pendingLabel => formatPendingHours(_pendingMinutes);

  /// Whether the confirm action adds time (vs. removing it).
  bool get isAddAction => _pendingMinutes >= 0;

  /// Whether the pending amount can be increased.
  bool get canIncrease =>
      _pendingMinutes + clockStepMinutes <= clockMaxPendingMinutes;

  /// Whether the pending amount can be decreased.
  bool get canDecrease =>
      _pendingMinutes - clockStepMinutes >= clockMinPendingMinutes;

  void _onEntries(List<TimeEntry> entries) {
    final total = entries.fold<int>(0, (sum, entry) => sum + entry.minutes);
    if (total != _weekTotalMinutes) {
      _weekTotalMinutes = total;
      notifyListeners();
    }
  }

  /// Increases the pending amount by one [clockStepMinutes] step.
  void increment() {
    if (!canIncrease) return;
    _pendingMinutes += clockStepMinutes;
    notifyListeners();
  }

  /// Decreases the pending amount by one [clockStepMinutes] step.
  void decrement() {
    if (!canDecrease) return;
    _pendingMinutes -= clockStepMinutes;
    notifyListeners();
  }

  /// Commits the pending amount to today: adds a time entry when
  /// positive, trims the most recent entries when negative.
  Future<void> confirm() async {
    if (_pendingMinutes == 0) return;
    final today = dateKey(DateTime.now());
    if (_pendingMinutes > 0) {
      await repository.createEntry(
        TimeEntriesCompanion.insert(
          date: today,
          minutes: _pendingMinutes,
          tagId: const Value(null),
        ),
      );
    } else {
      await repository.removeMinutesFromDay(today, -_pendingMinutes);
    }
  }

  @override
  void dispose() {
    unawaited(_subscription.cancel());
    super.dispose();
  }
}
