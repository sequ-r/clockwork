import 'package:clockwork/core/di/app_dependencies.dart';
import 'package:clockwork/data/repositories/time_entry_repository.dart';
import 'package:clockwork/database/database.dart';
import 'package:clockwork/database/dates.dart';
import 'package:clockwork/features/clock/weekly_clock_screen.dart';
import 'package:clockwork/features/clock/weekly_clock_view_model.dart';
import 'package:clockwork/l10n/generated/app_localizations.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('formatClockHHmmss', () {
    test('zero minutes', () {
      expect(formatClockHHmmss(0), '00:00:00');
    });

    test('hours and minutes', () {
      expect(formatClockHHmmss(90), '01:30:00');
      expect(formatClockHHmmss(480), '08:00:00');
    });

    test('negative minutes', () {
      expect(formatClockHHmmss(-30), '-00:30:00');
    });
  });

  group('formatPendingHours', () {
    test('formats half and whole hours', () {
      expect(formatPendingHours(30), '0.5h');
      expect(formatPendingHours(60), '1h');
      expect(formatPendingHours(90), '1.5h');
    });

    test('marks negative amounts', () {
      expect(formatPendingHours(-120), '-2h');
    });
  });

  group('WeeklyClockViewModel', () {
    late ClockworkDatabase db;
    late TimeEntryRepository repo;
    late WeeklyClockViewModel vm;

    setUp(() {
      db = ClockworkDatabase(NativeDatabase.memory());
      repo = TimeEntryRepository(timeEntryDao: db.timeEntryDao);
      vm = WeeklyClockViewModel(repository: repo);
    });

    tearDown(() async {
      vm.dispose();
      await db.close();
    });

    test('starts with a 0.5h pending add', () {
      expect(vm.pendingMinutes, clockStepMinutes);
      expect(vm.pendingLabel, '0.5h');
      expect(vm.isAddAction, isTrue);
      expect(vm.weekTotalMinutes, 0);
    });

    test('stepper moves in half-hour steps and can go negative', () {
      vm.increment();
      expect(vm.pendingMinutes, 60);
      vm.decrement();
      vm.decrement();
      vm.decrement();
      expect(vm.pendingMinutes, -30);
      expect(vm.isAddAction, isFalse);
      expect(vm.pendingLabel, '-0.5h');
    });

    test('confirm adds an entry for today and updates the week total',
        () async {
      vm.increment();
      vm.increment();
      await vm.confirm();

      final today = dateKey(DateTime.now());
      final entries = await repo.getForDate(today);
      expect(entries.single.minutes, 90);

      await pumpEventQueue();
      expect(vm.weekTotalMinutes, 90);
    });

    test('confirm with negative pending removes from the latest entries',
        () async {
      final today = dateKey(DateTime.now());
      await repo.createEntry(
        TimeEntriesCompanion.insert(date: today, minutes: 60),
      );
      await repo.createEntry(
        TimeEntriesCompanion.insert(
          date: today,
          minutes: 120,
          notes: const Value('later'),
        ),
      );

      // Pending starts at +30; step down to -90.
      for (var i = 0; i < 4; i++) {
        vm.decrement();
      }
      expect(vm.pendingMinutes, -90);

      await vm.confirm();

      final remaining = await repo.getForDate(today);
      expect(remaining.length, 2);
      expect(
        remaining.map((e) => e.minutes),
        containsAll(<int>[60, 30]),
      );

      await pumpEventQueue();
      expect(vm.weekTotalMinutes, 90);
    });
  });

  group('removeMinutesFromDay', () {
    late ClockworkDatabase db;
    late TimeEntryRepository repo;

    setUp(() {
      db = ClockworkDatabase(NativeDatabase.memory());
      repo = TimeEntryRepository(timeEntryDao: db.timeEntryDao);
    });

    tearDown(() => db.close());

    test('deletes entries fully consumed by the removal', () async {
      final today = dateKey(DateTime.now());
      await repo.createEntry(
        TimeEntriesCompanion.insert(date: today, minutes: 45),
      );
      await repo.removeMinutesFromDay(today, 60);
      expect(await repo.getForDate(today), isEmpty);
    });

    test('ignores non-positive amounts', () async {
      final today = dateKey(DateTime.now());
      await repo.createEntry(
        TimeEntriesCompanion.insert(date: today, minutes: 45),
      );
      await repo.removeMinutesFromDay(today, 0);
      expect((await repo.getForDate(today)).length, 1);
    });
  });

  group('WeeklyClockScreen widget', () {
    late ClockworkDatabase db;
    late AppDependencies deps;

    Future<void> settle(WidgetTester tester) async {
      for (var i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
    }

    Future<void> pumpScreen(WidgetTester tester) async {
      db = ClockworkDatabase(NativeDatabase.memory());
      deps = AppDependencies.create(database: db);

      await tester.pumpWidget(
        ClockworkScope(
          dependencies: deps,
          child: const MaterialApp(
            home: WeeklyClockScreen(),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
          ),
        ),
      );
      await settle(tester);
    }

    Future<void> finish(WidgetTester tester) async {
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 100));
      await deps.dispose();
      await tester.pump(const Duration(milliseconds: 100));
    }

    testWidgets('renders heading, clock and controls', (tester) async {
      await pumpScreen(tester);

      expect(find.textContaining('Total worked hours'), findsOneWidget);
      expect(find.text('00:00:00'), findsOneWidget);
      expect(find.text('0.5h'), findsOneWidget);
      expect(find.text('Add'), findsOneWidget);

      await finish(tester);
    });

    testWidgets('stepper updates the pending amount', (tester) async {
      await pumpScreen(tester);

      await tester.tap(find.byIcon(Icons.add));
      await tester.pump();

      expect(find.text('1h'), findsOneWidget);

      await finish(tester);
    });

    testWidgets('Add logs time and updates the week total', (tester) async {
      await pumpScreen(tester);

      await tester.tap(find.text('Add'));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('00:30:00'), findsOneWidget);

      final today = dateKey(DateTime.now());
      final entries = await db.timeEntryDao.getForDate(today);
      expect(entries.single.minutes, 30);

      // Let the confirmation snackbar finish so no timers stay pending.
      await tester.pump(const Duration(seconds: 3));
      await tester.pump(const Duration(seconds: 1));

      await finish(tester);
    });
  });
}
