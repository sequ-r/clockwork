/// v3 schema design — NOT YET WIRED INTO @DriftDatabase.
///
/// This file documents the schema that Phase 5 will introduce. It is
/// deliberately kept out of `database.dart`'s `@DriftDatabase(tables: [...])`
/// annotation until the v2→v3 migration (5.8-5.9) is written and reviewed,
/// because bumping `schemaVersion` without a working migration would break
/// existing v2 databases on first open.
///
/// Review checklist for this file (Phase 5.4-5.7):
///
/// [ ] clients table — top-level entity (e.g. "Acme Corp")
/// [ ] projects table — replaces `tags`; hierarchical via parent_id,
///       optionally belongs to a client
/// [ ] labels table — flat, distinct from projects
/// [ ] task_labels join — many-to-many tasks ↔ labels
/// [ ] settings table — key/value application config
/// [ ] integration_accounts table — Phase 15 wiring (Jira, CalDAV, ...)
/// [ ] tasks alterations — project_id, client_id, jira_issue_key,
///       estimate_minutes, created_at, updated_at; tag_id kept for now
/// [ ] time_entries alterations — project_id, client_id, created_at,
///       updated_at, source; tag_id kept for now
/// [ ] indices on time_entries(date), tasks(date), projects(client_id)
/// [ ] new DAOs (ClientDao, ProjectDao, LabelDao, SettingsDao,
///       IntegrationAccountDao) — Phase 6 will wrap them in repositories
///
/// Open questions to confirm before writing the migration:
///
/// 1. `tag_id` on tasks/time_entries: the plan says "keep during migration,
///    drop at the end." Dropping it breaks ~20 consumer sites
///    (tag_filter_bar, tag_manager_dialog, bin/clockwork.dart). Phases
///    10-12 update those consumers. Two options:
///    a) Drop tag_id in the v2→v3 migration; UI is broken until Phase 10.
///    b) Keep tag_id as a legacy nullable column in v3; drop in a later
///       migration once consumers migrate. (Recommended for this session.)
///
/// 2. `client_id` on tasks/time_entries is denormalised from
///    `project.client_id`. The migration populates it from the project
///    after the tag→project copy. Later writes must keep them in sync —
///    the DAO layer (Phase 6) handles this.
///
/// 3. `source` on time_entries is text with default 'manual'. Valid
///    values: 'manual', 'shortcut', 'import'. No CHECK constraint — the
///    DAOs enforce. (Could add a CHECK if reviewers want DB-level
///    enforcement; tradeoff is a less portable schema.)
///
/// 4. `created_at` / `updated_at` are DateTime (stored as int seconds by
///    drift's default). A trigger on tasks/time_entries that auto-updates
///    `updated_at` on row UPDATE is nice but adds complexity. Defer to
///    the DAO layer.
///
/// 5. The `tasks.date` and `time_entries.date` columns are stored as
///    `TEXT` (`YYYY-MM-DD`). String comparison is fine for the date
///    range queries we run; no need to change.
library;

// ignore_for_file: public_member_api_docs, lines_longer_than_80_chars

import 'package:drift/drift.dart';

// =====================================================================
// New tables (5.4)
// =====================================================================

/// Top-level entity a project may belong to (e.g. "Acme Corp").
///
/// Soft-archived via [archived]; notes are free-form context for the
/// user. Maps to a `Client` domain model in Phase 6.
class Clients extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1)();
  IntColumn get color => integer()();
  BoolColumn get archived => boolean().withDefault(const Constant(false))();
  TextColumn get notes => text().nullable()();
}

/// Primary work unit. Replaces v2 `tags`.
///
/// Hierarchical via self-referencing [parentId]; optionally belongs to a
/// [Client]. The v2→v3 migration copies `tags` rows into this table:
/// root tags → top-level projects, child tags → projects with
/// `parent_id` set. Maps to a `Project` domain model in Phase 6.
@DataClassName('Project')
class Projects extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1)();
  IntColumn get color => integer()();
  IntColumn get clientId => integer().nullable().references(
    Clients,
    #id,
    onDelete: KeyAction.setNull,
  )();
  IntColumn get parentId => integer().nullable().references(
    Projects,
    #id,
    onDelete: KeyAction.setNull,
  )();
  BoolColumn get archived => boolean().withDefault(const Constant(false))();
}

/// Flat label for categorisation. Many-to-many with tasks via
/// [TaskLabels]. Distinct from projects: a label is a tag, a project is
/// a billable work unit.
class Labels extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1)();
  IntColumn get color => integer()();
}

/// Join table for many-to-many between tasks and labels. CASCADE on
/// both sides so deleting a task or label cleans up the join rows.
@DataClassName('TaskLabel')
class TaskLabels extends Table {
  IntColumn get taskId => integer().references(
    Tasks,
    #id,
    onDelete: KeyAction.cascade,
  )();
  IntColumn get labelId => integer().references(
    Labels,
    #id,
    onDelete: KeyAction.cascade,
  )();

  @override
  Set<Column> get primaryKey => {taskId, labelId};
}

/// Key/value application settings. `value` is JSON-encoded so the table
/// can hold arbitrary structured config (e.g. theme mode, working hours
/// limit). The SettingsDao (Phase 6) handles encode/decode.
@DataClassName('Setting')
class SettingsTable extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}

/// External service connections (Phase 15).
///
/// `kind` discriminates the provider ('jira', 'caldav', ...); `configJson`
/// holds provider-specific opaque config. Maps to an
/// `IntegrationAccount` domain model in Phase 6.
class IntegrationAccounts extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get kind => text().withLength(min: 1)();
  TextColumn get displayName => text().withLength(min: 1)();
  TextColumn get configJson => text()();
  BoolColumn get enabled => boolean().withDefault(const Constant(true))();
}

// =====================================================================
// Altered tables (5.5, 5.6)
// =====================================================================

/// A unit of work scheduled on a single day.
///
/// v3 additions: [projectId] (replaces [tagId] over time),
/// [clientId] (denormalised from project), [jiraIssueKey],
/// [estimateMinutes], [createdAt], [updatedAt]. [tagId] is kept in v3
/// as a legacy nullable column to avoid breaking the v2 UI until
/// Phases 10-12 migrate consumers.
@DataClassName('Task')
class Tasks extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text().withLength(min: 1)();
  TextColumn get date => text().withLength(min: 10, max: 10)();
  BoolColumn get done => boolean().withDefault(const Constant(false))();

  // Legacy v2 column. Kept during v3 so existing UI keeps compiling.
  // Will be dropped in a later migration once Phases 10-12 land.
  IntColumn get tagId => integer().nullable().references(
    Tags,
    #id,
    onDelete: KeyAction.setNull,
  )();

  IntColumn get projectId => integer().nullable().references(
    Projects,
    #id,
    onDelete: KeyAction.setNull,
  )();
  IntColumn get clientId => integer().nullable().references(
    Clients,
    #id,
    onDelete: KeyAction.setNull,
  )();
  TextColumn get jiraIssueKey => text().nullable()();
  IntColumn get estimateMinutes => integer().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  TextColumn get notes => text().nullable()();
}

/// A block of worked time on a given day.
///
/// v3 additions mirror tasks: [projectId], [clientId], [createdAt],
/// [updatedAt], [source]. [tagId] is kept for the same reason as on
/// tasks.
@DataClassName('TimeEntry')
class TimeEntries extends Table {
  IntColumn get id => integer().autoIncrement()();

  // Legacy v2 column. See note on Tasks.tagId.
  IntColumn get tagId => integer().nullable().references(
    Tags,
    #id,
    onDelete: KeyAction.setNull,
  )();

  IntColumn get projectId => integer().nullable().references(
    Projects,
    #id,
    onDelete: KeyAction.setNull,
  )();
  IntColumn get clientId => integer().nullable().references(
    Clients,
    #id,
    onDelete: KeyAction.setNull,
  )();
  IntColumn get taskId => integer().nullable().references(
    Tasks,
    #id,
    onDelete: KeyAction.setNull,
  )();
  TextColumn get date => text().withLength(min: 10, max: 10)();
  IntColumn get minutes => integer()();
  TextColumn get notes => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  /// Origin of the entry: 'manual' | 'shortcut' | 'import'. Default
  /// 'manual'. DAOs (Phase 6) enforce the set; no CHECK constraint so
  /// the schema stays portable.
  TextColumn get source => text().withDefault(const Constant('manual'))();
}

// =====================================================================
// Unchanged legacy table — kept for the migration (5.8)
// =====================================================================

/// v2 `tags` table. Present in v3 because the migration references it
/// and dropping it breaks ~20 consumer sites. Will be removed in a
/// later migration after Phases 10-12 migrate consumers to projects.
@DataClassName('Tag')
class Tags extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1)();
  IntColumn get color => integer()();
  IntColumn get parentId => integer().nullable().references(
    Tags,
    #id,
    onDelete: KeyAction.setNull,
  )();
}
