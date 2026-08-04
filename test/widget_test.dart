import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:clockwork/main.dart';
import 'package:clockwork/database/database.dart';
import 'package:clockwork/providers/providers.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class _Harness {
  _Harness({required this.db, required this.container});

  final ClockworkDatabase db;
  final ProviderContainer container;
}

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 5; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<_Harness> _pumpApp(WidgetTester tester) async {
  final db = ClockworkDatabase(NativeDatabase.memory());
  final container = ProviderContainer(
    overrides: [databaseProvider.overrideWithValue(db)],
  );

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const ClockworkApp(),
    ),
  );
  await _settle(tester);
  return _Harness(db: db, container: container);
}

Future<void> _tearDown(WidgetTester tester, _Harness harness) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(milliseconds: 100));
  harness.container.dispose();
  await tester.pump(const Duration(milliseconds: 100));
  await harness.db.close();
  await tester.pump(const Duration(milliseconds: 100));
}

void main() {
  testWidgets('home screen renders overview', (tester) async {
    final harness = await _pumpApp(tester);

    expect(find.text('Clockwork'), findsOneWidget);
    expect(find.text('Track time'), findsOneWidget);
    expect(find.text('Add a task...'), findsOneWidget);
    expect(find.textContaining('Week total'), findsOneWidget);

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
}
