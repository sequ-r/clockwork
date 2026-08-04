import 'package:clockwork/database/database.dart';
import 'package:clockwork/database/dates.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:test/test.dart';

void main() {
  late ClockworkDatabase db;

  setUp(() {
    db = ClockworkDatabase(NativeDatabase.memory());
  });

  tearDown(() => db.close());

  test('date helpers', () {
    expect(dateKey(DateTime(2026, 8, 4)), '2026-08-04');
    final monday = startOfWeek(DateTime(2026, 8, 6));
    expect(monday, DateTime(2026, 8, 3));
    expect(weekKeys(DateTime(2026, 8, 6)).first, '2026-08-03');
    expect(weekKeys(DateTime(2026, 8, 6)).length, 7);
    expect(formatDuration(const Duration(hours: 1, minutes: 5)), '1h 05m');
    expect(formatDuration(const Duration(minutes: 45)), '45m');
  });

  test('tag CRUD and cascades', () async {
    final parent = await db.tagDao.createTag(
      TagsCompanion.insert(name: 'Project', color: 0xFF112233),
    );
    final child = await db.tagDao.createTag(
      TagsCompanion.insert(
        name: 'Sub',
        color: 0xFF445566,
        parentId: Value(parent),
      ),
    );
    var tags = await db.tagDao.getAll();
    expect(tags.length, 2);

    await db.tagDao.deleteTag(parent);
    tags = await db.tagDao.getAll();
    expect(tags.length, 1);
    expect(tags.single.id, child);
    expect(tags.single.parentId, isNull);
  });

  test('task CRUD and filtering', () async {
    final tag = await db.tagDao.createTag(
      TagsCompanion.insert(name: 'Work', color: 0xFF000000),
    );
    await db.taskDao.createTask(
      TasksCompanion.insert(
          title: 'A', date: '2026-08-04', tagId: Value(tag)),
    );
    await db.taskDao.createTask(
      TasksCompanion.insert(title: 'B', date: '2026-08-05'),
    );

    final today = await db.taskDao.getForDate('2026-08-04');
    expect(today.single.title, 'A');

    await db.taskDao.setDone(today.single.id, true);
    final done = (await db.taskDao.getForDate('2026-08-04')).single;
    expect(done.done, isTrue);

    final ranged =
        await db.taskDao.watchDateRange(['2026-08-04', '2026-08-05']).first;
    expect(ranged.length, 2);

    await db.taskDao.deleteTask(done.id);
    expect((await db.taskDao.getForDate('2026-08-04')), isEmpty);
  });

  test('time entries range query and totals', () async {
    final tag = await db.tagDao.createTag(
      TagsCompanion.insert(name: 'Work', color: 0xFF000000),
    );
    await db.timeEntryDao.createEntry(
      TimeEntriesCompanion.insert(
        start: DateTime(2026, 8, 4, 9),
        end: DateTime(2026, 8, 4, 11, 30),
        tagId: Value(tag),
      ),
    );
    await db.timeEntryDao.createEntry(
      TimeEntriesCompanion.insert(
        start: DateTime(2026, 8, 5, 14),
        end: DateTime(2026, 8, 5, 15),
      ),
    );

    final week = await db.timeEntryDao
        .watchRange(DateTime(2026, 8, 3), DateTime(2026, 8, 10))
        .first;
    expect(week.length, 2);
    final total = week.fold<Duration>(
        Duration.zero, (sum, e) => sum + entryDuration(e.start, e.end));
    expect(total, const Duration(hours: 3, minutes: 30));

    final narrow = await db.timeEntryDao
        .watchRange(DateTime(2026, 8, 4), DateTime(2026, 8, 5))
        .first;
    expect(narrow.length, 1);

    await db.timeEntryDao.deleteEntry(week.first.id);
    final remaining = await db.timeEntryDao
        .watchRange(DateTime(2026, 8, 3), DateTime(2026, 8, 10))
        .first;
    expect(remaining.length, 1);
  });
}
