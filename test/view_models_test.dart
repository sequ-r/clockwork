import 'package:clockwork/core/view_models/app_view_model.dart';
import 'package:clockwork/data/repositories/tag_repository.dart';
import 'package:clockwork/data/repositories/task_repository.dart';
import 'package:clockwork/data/repositories/time_entry_repository.dart';
import 'package:clockwork/database/database.dart';
import 'package:clockwork/database/dates.dart';
import 'package:clockwork/features/calendar/calendar_view_model.dart';
import 'package:clockwork/features/today/today_view_model.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late ClockworkDatabase db;
  late TagRepository tagRepo;
  late TaskRepository taskRepo;
  late TimeEntryRepository timeEntryRepo;
  late AppViewModel appVm;

  setUp(() {
    db = ClockworkDatabase(NativeDatabase.memory());
    tagRepo = TagRepository(tagDao: db.tagDao);
    taskRepo = TaskRepository(taskDao: db.taskDao);
    timeEntryRepo = TimeEntryRepository(timeEntryDao: db.timeEntryDao);
    appVm = AppViewModel(initialSelectedDate: DateTime(2026, 8, 14));
  });

  tearDown(() async {
    appVm.dispose();
    await db.close();
  });

  group('AppViewModel', () {
    test('updates selected date and notifies listeners', () {
      var notified = false;
      appVm.addListener(() => notified = true);

      appVm.setSelectedDate(DateTime(2026, 8, 15));
      expect(appVm.selectedDate, DateTime(2026, 8, 15));
      expect(notified, isTrue);
    });

    test('switches calendar view mode and computes visible date keys', () {
      appVm.setCalendarViewMode(CalendarView.week);
      expect(appVm.visibleDateKeys.length, 7);

      appVm.setCalendarViewMode(CalendarView.month);
      expect(appVm.visibleDateKeys.length, 31);
    });

    test('triggers quick add request notifications', () {
      var count = 0;
      appVm.quickAddRequestNotifier.addListener(() => count++);

      appVm.requestQuickAdd();
      expect(count, 1);
      expect(appVm.quickAddRequestNotifier.value, 1);
    });
  });

  group('TodayViewModel', () {
    test('creates and filters tasks for the selected date', () async {
      final todayVm = TodayViewModel(
        taskRepository: taskRepo,
        timeEntryRepository: timeEntryRepo,
        tagRepository: tagRepo,
        appViewModel: appVm,
      );

      final tagId = await tagRepo.createTag(
        TagsCompanion.insert(name: 'Project A', color: 0xFF123456),
      );

      await todayVm.addTask('General task');
      appVm.setTagFilter(tagId);
      await todayVm.addTask('Tagged task');

      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(todayVm.filteredTasks.length, 1);
      expect(todayVm.filteredTasks.single.title, 'Tagged task');

      appVm.setTagFilter(null);
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(todayVm.filteredTasks.length, 2);

      todayVm.dispose();
    });

    test('tracks totals and deletes entries', () async {
      final todayVm = TodayViewModel(
        taskRepository: taskRepo,
        timeEntryRepository: timeEntryRepo,
        tagRepository: tagRepo,
        appViewModel: appVm,
      );

      final entryId = await timeEntryRepo.createEntry(
        TimeEntriesCompanion.insert(
          date: dateKey(appVm.selectedDate),
          minutes: 90,
          tagId: const Value(null),
        ),
      );

      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(todayVm.selectedDateTotal, const Duration(minutes: 90));

      await todayVm.deleteEntry(entryId);
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(todayVm.selectedDateTotal, Duration.zero);

      todayVm.dispose();
    });
  });

  group('CalendarViewModel', () {
    test('calculates daily totals and navigates weeks', () async {
      final calendarVm = CalendarViewModel(
        taskRepository: taskRepo,
        timeEntryRepository: timeEntryRepo,
        tagRepository: tagRepo,
        appViewModel: appVm,
      );

      await timeEntryRepo.createEntry(
        TimeEntriesCompanion.insert(
          date: '2026-08-14',
          minutes: 120,
          tagId: const Value(null),
        ),
      );

      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(calendarVm.dailyTotals['2026-08-14'], const Duration(hours: 2));

      calendarVm.navigate(forward: true);
      expect(appVm.calendarAnchor, DateTime(2026, 8, 21));

      calendarVm.goToToday();
      final now = DateTime.now();
      expect(appVm.calendarAnchor, DateTime(now.year, now.month, now.day));

      calendarVm.dispose();
    });
  });
}
