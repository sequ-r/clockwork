import 'dart:async';

import 'package:clockwork/core/view_models/app_view_model.dart';
import 'package:clockwork/data/repositories/tag_repository.dart';
import 'package:clockwork/data/repositories/task_repository.dart';
import 'package:clockwork/data/repositories/time_entry_repository.dart';
import 'package:clockwork/database/database.dart';
import 'package:clockwork/database/dates.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/foundation.dart';

/// ViewModel managing state and operations for the Today pane.
class TodayViewModel extends ChangeNotifier {
  /// Creates the Today view model with required dependencies.
  TodayViewModel({
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
  StreamSubscription<List<TimeEntry>>? _taskEntriesSub;

  List<Tag> _tags = [];
  List<Task> _tasks = [];
  List<TimeEntry> _entries = [];
  Map<int, Duration> _taskHours = {};
  String? _currentDateKey;

  /// All tags in the system.
  List<Tag> get tags => _tags;

  /// Tasks for the currently selected date, filtered by the active tag filter.
  List<Task> get filteredTasks {
    final filter = appViewModel.tagFilter;
    if (filter == null) return _tasks;
    return _tasks.where((t) => t.tagId == filter).toList();
  }

  /// Time entries logged on the selected date.
  List<TimeEntry> get entries => _entries;

  /// Total tracked duration for the selected date.
  Duration get selectedDateTotal =>
      totalMinutes(_entries.map((e) => e.minutes));

  /// Map of task IDs to their lifetime tracked duration.
  Map<int, Duration> get taskHours => _taskHours;

  /// Currently selected date from the application view model.
  DateTime get selectedDate => appViewModel.selectedDate;

  void _onAppViewModelChanged() {
    final newDateKey = dateKey(appViewModel.selectedDate);
    if (_currentDateKey != newDateKey) {
      _subscribeToDate(newDateKey);
    }
    notifyListeners();
  }

  void _initStreams() {
    _tagsSub = tagRepository.watchAll().listen((tags) {
      _tags = tags;
      notifyListeners();
    });
    _subscribeToDate(dateKey(appViewModel.selectedDate));
  }

  void _subscribeToDate(String date) {
    _currentDateKey = date;
    _tasksSub?.cancel();
    _entriesSub?.cancel();

    _tasksSub = taskRepository.watchForDate(date).listen((tasks) {
      _tasks = tasks;
      _subscribeTaskHours(tasks);
      notifyListeners();
    });

    _entriesSub = timeEntryRepository.watchForDate(date).listen((entries) {
      final sorted = [...entries]..sort((a, b) => b.id.compareTo(a.id));
      _entries = List<TimeEntry>.unmodifiable(sorted);
      notifyListeners();
    });
  }

  void _subscribeTaskHours(List<Task> tasks) {
    _taskEntriesSub?.cancel();
    if (tasks.isEmpty) {
      _taskHours = {};
      notifyListeners();
      return;
    }
    final ids = tasks.map((t) => t.id).toList();
    _taskEntriesSub = timeEntryRepository.watchForTaskIds(ids).listen((
      entries,
    ) {
      final totals = <int, Duration>{};
      for (final entry in entries) {
        final taskId = entry.taskId;
        if (taskId == null) continue;
        totals[taskId] =
            (totals[taskId] ?? Duration.zero) +
            Duration(minutes: entry.minutes);
      }
      _taskHours = totals;
      notifyListeners();
    });
  }

  /// Adds a new task scheduled for the selected day.
  Future<void> addTask(String title) async {
    final trimmed = title.trim();
    if (trimmed.isEmpty) return;
    await taskRepository.createTask(
      TasksCompanion.insert(
        title: trimmed,
        date: dateKey(appViewModel.selectedDate),
        tagId: Value(appViewModel.tagFilter),
      ),
    );
  }

  /// Sets the done status for the task matching [taskId].
  Future<void> setTaskDone(int taskId, bool done) =>
      taskRepository.setDone(taskId, done);

  /// Deletes the time entry matching [entryId].
  Future<void> deleteEntry(int entryId) =>
      timeEntryRepository.deleteEntry(entryId);

  @override
  void dispose() {
    appViewModel.removeListener(_onAppViewModelChanged);
    _tagsSub?.cancel();
    _tasksSub?.cancel();
    _entriesSub?.cancel();
    _taskEntriesSub?.cancel();
    super.dispose();
  }
}
