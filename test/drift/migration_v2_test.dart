/// v2 schema baseline tests.
///
/// These tests run against the **current** schema (v2). They must pass
/// before any Phase 5 work touches the schema — they lock down the
/// baseline so that the upcoming v2->v3 migration can only be merged
/// when the baseline still holds.
library;

import 'dart:io';

import 'package:clockwork/database/database.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late ClockworkDatabase db;

  setUp(() {
    db = ClockworkDatabase(NativeDatabase.memory());
  });

  tearDown(() => db.close());

  test('schema version is 2', () {
    expect(db.schemaVersion, 2);
  });

  test('exposes the expected tables', () async {
    final tables = await db
        .customSelect(
          "SELECT name FROM sqlite_master WHERE type='table' "
          "AND name NOT LIKE 'sqlite_%' ORDER BY name",
        )
        .map((row) => row.read<String>('name'))
        .get();
    expect(tables, ['tags', 'tasks', 'time_entries']);
  });

  test('tags parent_id is a self-referencing FK with SET NULL', () async {
    final fks = await db
        .customSelect('PRAGMA foreign_key_list("tags")')
        .map((row) => row.read<String>('table'))
        .get();
    expect(fks, ['tags']);
    final actions = await db
        .customSelect("SELECT on_delete FROM pragma_foreign_key_list('tags')")
        .map((row) => row.read<String>('on_delete'))
        .get();
    expect(actions, ['SET NULL']);
  });

  test('time_entries has date and minutes columns (v2 shape)', () async {
    final cols = await db
        .customSelect('PRAGMA table_info("time_entries")')
        .map((row) => row.read<String>('name'))
        .get();
    expect(cols, containsAll(<String>['id', 'date', 'minutes']));
    expect(cols, isNot(contains('start')));
    expect(cols, isNot(contains('end')));
  });

  test('a snapshot file exists for v2', () {
    final snapshot = File('drift_schemas/drift_schema_v2.json');
    expect(
      snapshot.existsSync(),
      isTrue,
      reason: 'run `dart run tool/dump_schema.dart` to regenerate',
    );
  });
}
