/// Backups the SQLite database file before a schema migration runs.
///
/// Phase 5 step 5.10. Before any `onUpgrade` mutates the database, the
/// existing file is copied to a timestamped sibling so a botched
/// migration can be reverted by hand. Backups older than
/// [retention] are pruned (default 5).
///
/// The backup is a plain file copy — no SQLite "VACUUM INTO" or online
/// backup API. SQLite is resilient against copies of a file that is not
/// currently being written to; we always copy before opening the file
/// with drift, so there is no live writer.
library;

import 'dart:io';

import 'package:clockwork/database/paths.dart';
import 'package:path/path.dart' as p;

/// Default number of backups to keep on disk.
const defaultRetention = 5;

/// Returns a stable per-database backup directory next to the data dir.
///
/// Layout: `<dataDir>/clockwork/backups/clockwork-<timestamp>.db`
Directory backupDirectory() {
  final dir = Directory(p.join(dataDirectory().path, 'backups'));
  if (!dir.existsSync()) dir.createSync(recursive: true);
  return dir;
}

/// Copies [source] into [backupDir] with a timestamped filename.
///
/// Returns the backup file. The file is closed before being copied, so
/// it is safe to call this before opening [source] with drift.
File backupDatabase(File source, {Directory? backupDir}) {
  final dir = backupDir ?? backupDirectory();
  final stamp = DateTime.now().toIso8601String().replaceAll(':', '-');
  final target = File(p.join(dir.path, 'clockwork-$stamp.db'));
  if (!source.existsSync()) return target;
  source.copySync(target.path);
  pruneBackups(dir, retention: defaultRetention);
  return target;
}

/// Removes old backups in [dir], keeping the [retention] newest ones.
void pruneBackups(Directory dir, {int retention = defaultRetention}) {
  if (!dir.existsSync()) return;
  final entries =
      dir
          .listSync()
          .whereType<File>()
          .where((f) => p.basename(f.path).startsWith('clockwork-'))
          .where((f) => f.path.endsWith('.db'))
          .toList()
        ..sort((a, b) => b.path.compareTo(a.path));
  for (final stale in entries.skip(retention)) {
    try {
      stale.deleteSync();
    } on FileSystemException {
      // Best-effort cleanup; never let pruning fail the migration.
    }
  }
}
