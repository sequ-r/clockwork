/// Backwards-compatible barrel for providers.
///
/// New code should import the focused modules in `lib/core/providers/`.
/// This file re-exports their public API so existing call sites keep
/// compiling during the migration.
library;

export '../core/providers/database.dart';
export '../core/providers/tasks.dart';
export '../core/providers/time_entries.dart';
export '../core/providers/ui_state.dart';
