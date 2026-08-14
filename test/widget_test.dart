import 'package:clockwork/core/di/app_dependencies.dart';
import 'package:clockwork/database/database.dart';
import 'package:clockwork/database/dates.dart';
import 'package:clockwork/main.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _Harness {
  _Harness({required this.dependencies});

  final AppDependencies dependencies;
}

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 5; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<_Harness> _pumpApp(WidgetTester tester) async {
  final db = ClockworkDatabase(NativeDatabase.memory());
  final dependencies = AppDependencies.create(database: db);

  await tester.pumpWidget(ClockworkApp(dependencies: dependencies));
  await _settle(tester);
  return _Harness(dependencies: dependencies);
}

Future<void> _tearDown(WidgetTester tester, _Harness harness) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(milliseconds: 100));
  await harness.dependencies.dispose();
  await tester.pump(const Duration(milliseconds: 100));
}

void main() {
  testWidgets('home screen shows welcome message and add button', (
    tester,
  ) async {
    final harness = await _pumpApp(tester);

    expect(find.textContaining('Good '), findsOneWidget);
    expect(find.text('Add time'), findsOneWidget);
    expect(find.text('Add a task...'), findsOneWidget);
    expect(find.text('Week'), findsOneWidget);
    expect(find.text('Month'), findsOneWidget);

    await _tearDown(tester, harness);
  });

  testWidgets('adding a task shows it in the list', (tester) async {
    final harness = await _pumpApp(tester);

    await tester.enterText(find.byType(TextField), 'Write report');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await _settle(tester);

    expect(find.text('Write report'), findsWidgets);

    await _tearDown(tester, harness);
  });

  testWidgets('add time dialog accepts hours', (tester) async {
    final harness = await _pumpApp(tester);

    await tester.tap(find.text('Add time'));
    await _settle(tester);

    expect(find.text('Hours'), findsOneWidget);
    expect(find.text('Comment'), findsOneWidget);
    await tester.tap(find.text('Add'));
    await _settle(tester);

    final entries = await harness.dependencies.database.timeEntryDao.getForDate(
      dateKey(DateTime.now()),
    );
    expect(entries.single.minutes, 60);

    await _tearDown(tester, harness);
  });
}
