/// Dumps the current schema of `ClockworkDatabase` as JSON into
/// `drift_schemas/`.
///
/// The drift_dev CLI (`dart run drift_dev schema dump`) does not build in
/// this environment: drift_dev 2.34.0 references drift3-preview APIs that
/// drift 2.34.3 reorganised, and drift_dev 2.34.5 needs analyzer ^13
/// (Finding A). This tool is the pragmatic stand-in until the toolchain
/// catches up.
///
/// Usage:
///
///   dart run tool/dump_schema.dart
///
/// Writes `drift_schemas/drift_schema_v<version>.json`. The JSON shape
/// is a flat, portable representation of `sqlite_master` augmented with
/// foreign-key info — enough to round-trip the schema through a
/// v2->v3 migration test.
library;

import 'dart:convert';
import 'dart:io';

import 'package:clockwork/database/database.dart';
import 'package:drift/native.dart';

Future<void> main() async {
  final db = ClockworkDatabase(NativeDatabase.memory());

  final schemaJson = await _dumpSchema(db);

  final outDir = Directory('drift_schemas');
  if (!outDir.existsSync()) outDir.createSync(recursive: true);
  final file = File('${outDir.path}/drift_schema_v${db.schemaVersion}.json');
  await file.writeAsString(
    const JsonEncoder.withIndent('  ').convert(schemaJson),
  );
  stdout.writeln('wrote ${file.path}');

  await db.close();
}

Future<Map<String, Object?>> _dumpSchema(ClockworkDatabase db) async {
  final master = await db
      .customSelect(
        'SELECT type, name, tbl_name, sql FROM sqlite_master '
        "WHERE name NOT LIKE 'sqlite_%' ORDER BY type, name",
      )
      .map(
        (row) => {
          'type': row.read<String>('type'),
          'name': row.read<String>('name'),
          'tbl_name': row.readNullable<String>('tbl_name'),
          'sql': row.read<String>('sql'),
        },
      )
      .get();

  // Group by type for readability.
  final byType = <String, List<Map<String, Object?>>>{};
  for (final row in master) {
    byType.putIfAbsent(row['type']!, () => []).add(row);
  }

  // Pull FK info from PRAGMA foreign_key_list — one row per FK column.
  final tables = master
      .where((r) => r['type'] == 'table')
      .map((r) => r['name']!)
      .toList();

  final foreignKeys = <String, List<Map<String, Object?>>>{};
  for (final table in tables) {
    final fks = await db
        .customSelect('PRAGMA foreign_key_list("$table")')
        .map(
          (row) => {
            'id': row.read<int>('id'),
            'seq': row.read<int>('seq'),
            'table': row.read<String>('table'),
            'from': row.read<String>('from'),
            'to': row.read<String>('to'),
            'on_update': row.read<String>('on_update'),
            'on_delete': row.read<String>('on_delete'),
          },
        )
        .get();
    if (fks.isNotEmpty) foreignKeys[table] = fks;
  }

  return {
    'format_version': 1,
    'database': 'ClockworkDatabase',
    'schema_version': db.schemaVersion,
    'objects': byType,
    'foreign_keys': foreignKeys,
  };
}
