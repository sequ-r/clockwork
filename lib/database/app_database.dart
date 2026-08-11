import 'dart:io';

import 'package:drift/native.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:path/path.dart' as p;

import 'database.dart';
import 'paths.dart';

/// Opens the database for the current platform.
///
/// Android: app-private directory chosen by `drift_flutter`.
/// Desktop: a background-isolate SQLite file under XDG data dir.
ClockworkDatabase openDatabase() {
  if (Platform.isAndroid) {
    return ClockworkDatabase(driftDatabase(name: 'clockwork'));
  }
  final file = databaseFile();
  file.parent.createSync(recursive: true);
  return ClockworkDatabase(NativeDatabase.createInBackground(file));
}

/// Overridable location, used by tests.
ClockworkDatabase openDatabaseAt(String path) {
  final file = File(p.join(path, 'clockwork.db'));
  file.parent.createSync(recursive: true);
  return ClockworkDatabase(NativeDatabase(file));
}
