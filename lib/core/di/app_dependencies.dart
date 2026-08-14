import 'package:clockwork/core/view_models/app_view_model.dart';
import 'package:clockwork/data/repositories/tag_repository.dart';
import 'package:clockwork/data/repositories/task_repository.dart';
import 'package:clockwork/data/repositories/time_entry_repository.dart';
import 'package:clockwork/database/app_database.dart';
import 'package:clockwork/database/database.dart';
import 'package:clockwork/services/tray_service.dart';
import 'package:flutter/widgets.dart';

/// Container for core application singletons and repositories.
class AppDependencies {
  /// Creates the dependency container.
  AppDependencies({
    required this.database,
    required this.tagRepository,
    required this.taskRepository,
    required this.timeEntryRepository,
    required this.appViewModel,
    required this.trayService,
  });

  /// Factory that constructs production dependencies from a [database].
  factory AppDependencies.create({ClockworkDatabase? database}) {
    final db = database ?? openDatabase();
    final tagRepo = TagRepository(tagDao: db.tagDao);
    final taskRepo = TaskRepository(taskDao: db.taskDao);
    final timeEntryRepo = TimeEntryRepository(timeEntryDao: db.timeEntryDao);
    final appVm = AppViewModel();
    final traySvc = TrayService(appViewModel: appVm, database: db);

    return AppDependencies(
      database: db,
      tagRepository: tagRepo,
      taskRepository: taskRepo,
      timeEntryRepository: timeEntryRepo,
      appViewModel: appVm,
      trayService: traySvc,
    );
  }

  /// The SQLite database instance.
  final ClockworkDatabase database;

  /// Tag and project repository.
  final TagRepository tagRepository;

  /// Task repository.
  final TaskRepository taskRepository;

  /// Logged time entries repository.
  final TimeEntryRepository timeEntryRepository;

  /// Application-wide view model.
  final AppViewModel appViewModel;

  /// System tray management service.
  final TrayService trayService;

  /// Disposes resources held by the dependencies.
  Future<void> dispose() async {
    trayService.dispose();
    appViewModel.dispose();
    await database.close();
  }
}

/// InheritedWidget making [AppDependencies] accessible down the tree.
class ClockworkScope extends InheritedWidget {
  /// Wraps [child] with access to [dependencies].
  const ClockworkScope({
    super.key,
    required this.dependencies,
    required super.child,
  });

  /// The provided application dependencies.
  final AppDependencies dependencies;

  /// Obtains the nearest [AppDependencies] from [context].
  static AppDependencies of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<ClockworkScope>();
    assert(scope != null, 'No ClockworkScope found in context');
    return scope!.dependencies;
  }

  @override
  bool updateShouldNotify(ClockworkScope oldWidget) =>
      dependencies != oldWidget.dependencies;
}
