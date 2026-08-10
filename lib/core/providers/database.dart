/// Database and DAO providers.
///
/// These are the lowest-level providers — every other provider depends on
/// them. Splitting them into their own file keeps the dependency graph
/// obvious.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../database/app_database.dart';
import '../../database/database.dart';

/// The application's SQLite database, opened once at startup.
final databaseProvider = Provider<ClockworkDatabase>((ref) {
  final db = openDatabase();
  ref.onDispose(db.close);
  return db;
});

final tagDaoProvider = Provider((ref) => ref.watch(databaseProvider).tagDao);
final taskDaoProvider = Provider((ref) => ref.watch(databaseProvider).taskDao);
final timeEntryDaoProvider = Provider(
  (ref) => ref.watch(databaseProvider).timeEntryDao,
);

/// Reactive list of all tags, driven by Drift's `watch()`.
final tagsProvider = StreamProvider<List<Tag>>(
  (ref) => ref.watch(tagDaoProvider).watchAll(),
);
