/// Tests for the pre-migration backup helper.
library;

import 'dart:io';

import 'package:clockwork/database/backup.dart';
import 'package:path/path.dart' as p;
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('backupDatabase', () {
    late Directory tmp;

    setUp(() {
      tmp = Directory.systemTemp.createTempSync('clockwork_backup_test_');
    });

    tearDown(() {
      if (tmp.existsSync()) tmp.deleteSync(recursive: true);
    });

    test('copies the file into a timestamped sibling', () {
      final src = File(p.join(tmp.path, 'src.db'))
        ..writeAsBytesSync(<int>[1, 2, 3]);
      final backupDir = Directory(p.join(tmp.path, 'backups'))..createSync();

      final out = backupDatabase(src, backupDir: backupDir);

      expect(out.existsSync(), isTrue);
      expect(out.path, contains('backups'));
      expect(out.path, contains('clockwork-'));
      expect(out.path, endsWith('.db'));
      expect(out.readAsBytesSync(), <int>[1, 2, 3]);
    });

    test('no-op when source does not exist (returns target only)', () {
      final src = File(p.join(tmp.path, 'missing.db'));
      final backupDir = Directory(p.join(tmp.path, 'backups'))..createSync();

      final out = backupDatabase(src, backupDir: backupDir);

      expect(out.path, contains('clockwork-'));
      expect(out.existsSync(), isFalse);
    });

    test('prunes to the retention limit', () {
      File(p.join(tmp.path, 'src.db')).writeAsBytesSync(<int>[0]);
      final backupDir = Directory(p.join(tmp.path, 'backups'))..createSync();

      // Create 8 backups, then take 2 more with retention=3.
      for (var i = 0; i < 8; i++) {
        File(
          p.join(backupDir.path, 'clockwork-2026-08-12T10-00-0$i.db'),
        ).writeAsBytesSync(<int>[i]);
      }
      pruneBackups(backupDir, retention: 3);

      final remaining = backupDir
          .listSync()
          .whereType<File>()
          .where((f) => p.basename(f.path).startsWith('clockwork-'))
          .toList();
      expect(remaining.length, 3);
    });
  });
}
