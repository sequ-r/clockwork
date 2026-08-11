import 'package:drift/drift.dart';

// Column getters below are part of drift's framework contract, not a
// hand-authored public API; suppress the dartdoc lint for this file.
// ignore_for_file: public_member_api_docs

part 'database.g.dart';

/// Project / label hierarchy, optionally nested via [parentId].
class Tags extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1)();
  IntColumn get color => integer()();
  IntColumn get parentId =>
      integer().nullable().references(Tags, #id, onDelete: KeyAction.setNull)();
}

/// A unit of work scheduled on a single day.
class Tasks extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text().withLength(min: 1)();
  TextColumn get date => text().withLength(min: 10, max: 10)();
  BoolColumn get done => boolean().withDefault(const Constant(false))();
  IntColumn get tagId =>
      integer().nullable().references(Tags, #id, onDelete: KeyAction.setNull)();
  TextColumn get notes => text().nullable()();
}

/// A block of worked time on a given day.
class TimeEntries extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get tagId =>
      integer().nullable().references(Tags, #id, onDelete: KeyAction.setNull)();
  IntColumn get taskId => integer().nullable().references(
    Tasks,
    #id,
    onDelete: KeyAction.setNull,
  )();
  TextColumn get date => text().withLength(min: 10, max: 10)();
  IntColumn get minutes => integer()();
  TextColumn get notes => text().nullable()();
}

/// Data-access object for [Tags].
@DriftAccessor(tables: [Tags])
class TagDao extends DatabaseAccessor<ClockworkDatabase> with _$TagDaoMixin {
  TagDao(super.db);

  /// Reactive list of every tag, unordered.
  Stream<List<Tag>> watchAll() => select(tags).watch();

  /// One-shot fetch of every tag.
  Future<List<Tag>> getAll() => select(tags).get();

  /// Inserts [companion] and returns the new rowid.
  Future<int> createTag(TagsCompanion companion) =>
      into(tags).insert(companion);

  /// Replaces the row whose primary key matches [tag]. Returns whether
  /// a row was updated.
  Future<bool> updateTag(Tag tag) => update(tags).replace(tag);

  /// Deletes the tag with [id]. Children's [Tags.parentId] become null
  /// via foreign-key cascade.
  Future<int> deleteTag(int id) =>
      (delete(tags)..where((t) => t.id.equals(id))).go();
}

/// Data-access object for [Tasks].
@DriftAccessor(tables: [Tasks])
class TaskDao extends DatabaseAccessor<ClockworkDatabase> with _$TaskDaoMixin {
  TaskDao(super.db);

  /// Reactive list of tasks scheduled on [date] (day-key `YYYY-MM-DD`).
  Stream<List<Task>> watchForDate(String date) =>
      (select(tasks)..where((t) => t.date.equals(date))).watch();

  /// Reactive list of tasks scheduled on any of [dates].
  Stream<List<Task>> watchDateRange(Iterable<String> dates) =>
      (select(tasks)..where((t) => t.date.isIn(dates.toList()))).watch();

  /// One-shot fetch of tasks scheduled on [date].
  Future<List<Task>> getForDate(String date) =>
      (select(tasks)..where((t) => t.date.equals(date))).get();

  /// Inserts [companion] and returns the new rowid.
  Future<int> createTask(TasksCompanion companion) =>
      into(tasks).insert(companion);

  /// Replaces the row whose primary key matches [task].
  Future<bool> updateTask(Task task) => update(tasks).replace(task);

  /// Updates only the `done` column for the task with [id].
  Future<int> setDone(int id, bool done) => (update(
    tasks,
  )..where((t) => t.id.equals(id))).write(TasksCompanion(done: Value(done)));

  /// Deletes the task with [id]. Dependent `time_entries.task_id`
  /// become null via foreign-key cascade.
  Future<int> deleteTask(int id) =>
      (delete(tasks)..where((t) => t.id.equals(id))).go();
}

/// Data-access object for [TimeEntries].
@DriftAccessor(tables: [TimeEntries])
class TimeEntryDao extends DatabaseAccessor<ClockworkDatabase>
    with _$TimeEntryDaoMixin {
  TimeEntryDao(super.db);

  /// Reactive list of entries logged on [date].
  Stream<List<TimeEntry>> watchForDate(String date) =>
      (select(timeEntries)..where((t) => t.date.equals(date))).watch();

  /// Reactive list of entries logged on any of [dates].
  Stream<List<TimeEntry>> watchDateRange(Iterable<String> dates) =>
      (select(timeEntries)..where((t) => t.date.isIn(dates.toList()))).watch();

  /// One-shot fetch of entries logged on [date].
  Future<List<TimeEntry>> getForDate(String date) =>
      (select(timeEntries)..where((t) => t.date.equals(date))).get();

  /// Reactive list of entries whose `task_id` is in [taskIds], across
  /// all dates. Used for per-task lifetime totals.
  Stream<List<TimeEntry>> watchForTaskIds(Iterable<int> taskIds) => (select(
    timeEntries,
  )..where((t) => t.taskId.isIn(taskIds.toList()))).watch();

  /// Inserts [companion] and returns the new rowid.
  Future<int> createEntry(TimeEntriesCompanion companion) =>
      into(timeEntries).insert(companion);

  /// Deletes the entry with [id].
  Future<int> deleteEntry(int id) =>
      (delete(timeEntries)..where((t) => t.id.equals(id))).go();
}

/// Drift database backing the GUI and the CLI.
///
/// The schema lives at v2. Schema v1 stored start/end timestamps; the
/// only existing migration converts them into per-day durations. Schema
/// v3 (clients, projects, labels) is tracked in
/// `docs/REWORK_PLAN.md` Phase 5.
@DriftDatabase(
  tables: [Tags, Tasks, TimeEntries],
  daos: [TagDao, TaskDao, TimeEntryDao],
)
class ClockworkDatabase extends _$ClockworkDatabase {
  ClockworkDatabase(super.executor);

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
    onUpgrade: (migrator, from, to) async {
      if (from < 2) {
        await _migrateToDurationEntries(migrator);
      }
    },
  );

  /// Converts schema v1 entries (start/end timestamps) into v2
  /// per-day durations.
  Future<void> _migrateToDurationEntries(Migrator migrator) async {
    await customStatement(
      'ALTER TABLE time_entries RENAME TO time_entries_old',
    );
    await migrator.createTable(timeEntries);
    await customStatement('''
      INSERT INTO time_entries (id, tag_id, task_id, date, minutes, notes)
      SELECT id, tag_id, task_id,
        date(start, 'unixepoch', 'localtime'),
        CAST((end - start) / 60 AS INTEGER),
        notes
      FROM time_entries_old
    ''');
    await customStatement('DROP TABLE time_entries_old');
  }
}
