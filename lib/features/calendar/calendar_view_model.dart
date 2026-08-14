import 'dart:async';

import 'package:clockwork/core/view_models/app_view_model.dart';
import 'package:clockwork/data/repositories/tag_repository.dart';
import 'package:clockwork/data/repositories/task_repository.dart';
import 'package:clockwork/data/repositories/time_entry_repository.dart';
import 'package:clockwork/database/database.dart';
import 'package:flutter/foundation.dart';

/// ViewModel managing state and calculations for the Calendar overview.
class CalendarViewModel extends ChangeNotifier {
  /// Creates the Calendar view model with required dependencies.
  CalendarViewModel({
    required this.taskRepository,
    required this.timeEntryRepository,
    required this.tagRepository,
    required this.appViewModel,
  }) {
    appViewModel.addListener(_onAppViewModelChanged);
    _initStreams();
  }

  /// Task repository reference.
  final TaskRepository taskRepository;

  /// Time entry repository reference.
  final TimeEntryRepository timeEntryRepository;

  /// Tag repository reference.
  final TagRepository tagRepository;

  /// Application view model reference.
  final AppViewModel appViewModel;

  StreamSubscription<List<Tag>>? _tagsSub;
  StreamSubscription<List<Task>>? _tasksSub;
  StreamSubscription<List<TimeEntry>>? _entriesSub;

  List<Tag> _tags = [];
  List<Task> _tasks = [];
  List<TimeEntry> _entries = [];
  List<String> _currentVisibleKeys = [];

  /// Tags list.
  List<Tag> get tags => _tags;

  /// Visible tasks in the calendar date range.
  List<Task> get tasks => _tasks;

  /// Visible time entries in the calendar date range.
  List<TimeEntry> get entries => _entries;

  /// Total tracked duration mapped by day-key.
  Map<String, Duration> get dailyTotals {
    final totals = <String, Duration>{};
    for (final entry in _entries) {
      totals[entry.date] =
          (totals[entry.date] ?? Duration.zero) +
          Duration(minutes: entry.minutes);
    }
    return totals;
  }

  /// Total tracked duration mapped by tag ID.
  Map<int, Duration> get tagTotals {
    final totals = <int, Duration>{};
    for (final entry in _entries) {
      final tagId = entry.tagId;
      if (tagId == null) continue;
      totals[tagId] =
          (totals[tagId] ?? Duration.zero) + Duration(minutes: entry.minutes);
    }
    return totals;
  }

  void _onAppViewModelChanged() {
    final newKeys = appViewModel.visibleDateKeys;
    if (!listEquals(_currentVisibleKeys, newKeys)) {
      _subscribeToRange(newKeys);
    }
    notifyListeners();
  }

  void _initStreams() {
    _tagsSub = tagRepository.watchAll().listen((tags) {
      _tags = tags;
      notifyListeners();
    });
    _subscribeToRange(appViewModel.visibleDateKeys);
  }

  void _subscribeToRange(List<String> keys) {
    _currentVisibleKeys = keys;
    _tasksSub?.cancel();
    _entriesSub?.cancel();

    _tasksSub = taskRepository.watchDateRange(keys).listen((tasks) {
      _tasks = tasks;
      notifyListeners();
    });

    _entriesSub = timeEntryRepository.watchDateRange(keys).listen((entries) {
      _entries = entries;
      notifyListeners();
    });
  }

  /// Navigates the calendar period forward or backward.
  void navigate({required bool forward}) {
    final anchor = appViewModel.calendarAnchor;
    final target = switch (appViewModel.calendarViewMode) {
      CalendarView.week => anchor.add(Duration(days: forward ? 7 : -7)),
      CalendarView.month => DateTime(
        anchor.year,
        anchor.month + (forward ? 1 : -1),
        1,
      ),
    };
    appViewModel.setCalendarAnchor(target);
  }

  /// Jumps the calendar view and selected date to today.
  void goToToday() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    appViewModel.setCalendarAnchor(today);
    appViewModel.setSelectedDate(today);
  }

  @override
  void dispose() {
    appViewModel.removeListener(_onAppViewModelChanged);
    _tagsSub?.cancel();
    _tasksSub?.cancel();
    _entriesSub?.cancel();
    super.dispose();
  }
}
