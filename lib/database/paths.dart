import 'dart:io';

import 'package:path/path.dart' as p;

/// Returns the directory where Clockwork stores its database on desktop.
///
/// Honors the XDG base directory spec so the GUI and the CLI always
/// operate on the same file.
Directory dataDirectory() {
  final env = Platform.environment;
  final xdg = env['XDG_DATA_HOME'];
  final base = (xdg != null && xdg.isNotEmpty)
      ? xdg
      : p.join(env['HOME'] ?? '.', '.local', 'share');
  return Directory(p.join(base, 'clockwork'));
}

/// Resolves the SQLite file the GUI and CLI share on desktop.
File databaseFile() => File(p.join(dataDirectory().path, 'clockwork.db'));
