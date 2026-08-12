import 'dart:io';

import 'package:clockwork/database/backup.dart';
import 'package:clockwork/database/database.dart';
import 'package:clockwork/database/paths.dart';
import 'package:drift/native.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart';

/// Opens the database for the current platform.
///
/// Android: app-private directory chosen by `drift_flutter`.
/// Desktop: a background-isolate SQLite file under XDG data dir.
///
/// If the on-disk file is at a lower `user_version` than
/// [ClockworkDatabase.schemaVersion], a timestamped copy is made under
/// `<dataDir>/clockwork/backups/` before drift opens it (Phase 5 step
/// 5.10). This keeps a recoverable snapshot of the pre-migration state
/// without paying the cost on every cold start.
ClockworkDatabase openDatabase() {
  if (Platform.isAndroid) {
    return ClockworkDatabase(driftDatabase(name: 'clockwork'));
  }
  final file = databaseFile();
  file.parent.createSync(recursive: true);
  maybeBackupBeforeMigration(file);
  return ClockworkDatabase(NativeDatabase.createInBackground(file));
}

/// Overridable location, used by tests.
ClockworkDatabase openDatabaseAt(String path) {
  final file = File(p.join(path, 'clockwork.db'));
  file.parent.createSync(recursive: true);
  maybeBackupBeforeMigration(file);
  return ClockworkDatabase(NativeDatabase(file));
}

/// Copies [file] to the backup directory if it holds an older schema
/// than [targetSchemaVersion]. The copy is best-effort: a failure to
/// back up never blocks the migration.
void maybeBackupBeforeMigration(
  File file, {
  int targetSchemaVersion = currentSchemaVersion,
}) {
  if (!file.existsSync()) return;
  try {
    final raw = sqlite3.open(file.path, mode: OpenMode.readOnly);
    try {
      final row = raw.select('PRAGMA user_version').firstOrNull;
      final version = (row?.columnAt(0) as int?) ?? 0;
      if (version < targetSchemaVersion) {
        backupDatabase(file);
      }
    } finally {
      raw.close();
    }
  } on Object {
    // The backup is a safety net, not a precondition. If we cannot open
    // the file in read-only mode, drift will surface the real error
    // when it tries to migrate.
  }
}

/// Target schema version of the bundled database.
///
/// Keep in lockstep with `ClockworkDatabase.schemaVersion`. Bumping the
/// drift schema requires bumping this constant so the pre-migration
/// backup triggers before drift opens the file.
const int currentSchemaVersion = 2;
