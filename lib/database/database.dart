import 'package:drift/drift.dart';

part 'database.g.dart';

class Tags extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1)();
  IntColumn get color => integer()();
  IntColumn get parentId =>
      integer().nullable().references(Tags, #id, onDelete: KeyAction.setNull)();
}

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
  IntColumn get taskId => integer()
      .nullable()
      .references(Tasks, #id, onDelete: KeyAction.setNull)();
  TextColumn get date => text().withLength(min: 10, max: 10)();
  IntColumn get minutes => integer()();
  TextColumn get notes => text().nullable()();
}

@DriftAccessor(tables: [Tags])
class TagDao extends DatabaseAccessor<ClockworkDatabase> with _$TagDaoMixin {
  TagDao(super.db);

  Stream<List<Tag>> watchAll() => select(tags).watch();

  Future<List<Tag>> getAll() => select(tags).get();

  Future<int> createTag(TagsCompanion companion) =>
      into(tags).insert(companion);

  Future<bool> updateTag(Tag tag) => update(tags).replace(tag);

  Future<int> deleteTag(int id) =>
      (delete(tags)..where((t) => t.id.equals(id))).go();
}

@DriftAccessor(tables: [Tasks])
class TaskDao extends DatabaseAccessor<ClockworkDatabase> with _$TaskDaoMixin {
  TaskDao(super.db);

  Stream<List<Task>> watchForDate(String date) =>
      (select(tasks)..where((t) => t.date.equals(date))).watch();

  Stream<List<Task>> watchDateRange(Iterable<String> dates) =>
      (select(tasks)..where((t) => t.date.isIn(dates.toList()))).watch();

  Future<List<Task>> getForDate(String date) =>
      (select(tasks)..where((t) => t.date.equals(date))).get();

  Future<int> createTask(TasksCompanion companion) =>
      into(tasks).insert(companion);

  Future<bool> updateTask(Task task) => update(tasks).replace(task);

  Future<int> setDone(int id, bool done) =>
      (update(tasks)..where((t) => t.id.equals(id)))
          .write(TasksCompanion(done: Value(done)));

  Future<int> deleteTask(int id) =>
      (delete(tasks)..where((t) => t.id.equals(id))).go();
}

@DriftAccessor(tables: [TimeEntries])
class TimeEntryDao extends DatabaseAccessor<ClockworkDatabase>
    with _$TimeEntryDaoMixin {
  TimeEntryDao(super.db);

  Stream<List<TimeEntry>> watchForDate(String date) =>
      (select(timeEntries)..where((t) => t.date.equals(date))).watch();

  Stream<List<TimeEntry>> watchDateRange(Iterable<String> dates) =>
      (select(timeEntries)..where((t) => t.date.isIn(dates.toList())))
          .watch();

  Future<List<TimeEntry>> getForDate(String date) =>
      (select(timeEntries)..where((t) => t.date.equals(date))).get();

  Stream<List<TimeEntry>> watchForTaskIds(Iterable<int> taskIds) =>
      (select(timeEntries)..where((t) => t.taskId.isIn(taskIds.toList())))
          .watch();

  Future<int> createEntry(TimeEntriesCompanion companion) =>
      into(timeEntries).insert(companion);

  Future<int> deleteEntry(int id) =>
      (delete(timeEntries)..where((t) => t.id.equals(id))).go();
}

@DriftDatabase(
    tables: [Tags, Tasks, TimeEntries],
    daos: [TagDao, TaskDao, TimeEntryDao])
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
    await customStatement('ALTER TABLE time_entries RENAME TO time_entries_old');
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
