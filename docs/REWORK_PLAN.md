# Clockwork Rework Plan

A phased plan to rework Clockwork into a local-first, Material 3 Expressive
time tracker for Linux desktop and Android.

Every dependency combination in this document was **empirically verified**
against the toolchain below on 2026-08-11. Where a "latest" version is not
usable, the reason is recorded.

- Flutter 3.44.9 (stable), Dart 3.12.2
- Session: Wayland + GNOME
- Target platforms: Linux desktop, Android

---

## 1. Goals

### Features

1. Quick time entry from a single text box, e.g. `+2 hours on <project>`.
2. Calendar view giving a week / month overview of hours spent.
3. Shortcuts to track time from anywhere (global, in-app, tray, Android).
4. Tasks associated with tracked hours.
5. Jira account configuration, with issue keys attachable to tasks.
6. Google Calendar configuration, with `.ics` file import.
7. Tracked hours assignable to clients.

### Constraints

- The app works fully **offline**. No network calls are made.
- Storage is **SQLite** (via `drift`).
- UI is **Material 3 Expressive**, simple and responsive.
- Ships as a **Linux desktop** app and an **Android** app.

### Scope decisions

These were settled before planning and shape the whole document.

| Question | Decision |
|---|---|
| Jira / Google auth | **Local only.** Config + credential storage, no OAuth, no HTTP. |
| Sync direction | **Neither.** No pull, no push. `.ics` import is file-based. |
| Global shortcuts | **Most reliable on Wayland** -> XDG Desktop Portal. |
| Data model | **Explicit hierarchy**: Client -> Project -> Task -> TimeEntry. |
| UI | **Full rewrite** to Material 3 Expressive. |
| State management | **Keep Riverpod**, upgrade to v3 + codegen. |
| Uncommitted work | **Commit first** (Phase 0). |

---

## 2. Verified environment findings

These were confirmed by running commands on the target machine, not assumed.
They are the reason several "obvious" choices in this plan are rejected.

| Finding | Verified value | Consequence |
|---|---|---|
| Session type | `wayland`, GNOME | `hotkey_manager` (X11 `XGrabKey`) is **rejected** |
| `org.freedesktop.portal.GlobalShortcuts` | present, version 1 | The chosen global-shortcut mechanism |
| `org.freedesktop.portal.Background` | present | Enables autostart / run-in-background |
| `org.freedesktop.portal.Notification` | present | Fallback surface for shortcuts |
| `org.kde.StatusNotifierWatcher` | present (AppIndicator ext.) | Tray works, but is extension-dependent |
| GTK | gtk4 `4.22.4` **and** gtk3 `3.24.52` | Current CMake probe **breaks the build** |
| `flutter_riverpod` | project `2.6.1`, latest `3.4.2` | Upgrade, but pin `3.3.2` (see below) |
| `dbus` package | `0.7.14` | Pure-Dart portal access, no native code |

### Finding A: latest Riverpod does not resolve

`riverpod_generator` 4.0.6+ requires `analyzer ^13.0.0`. Flutter 3.44.9's
bundled `flutter_test` pins `test_api 0.7.11` and `matcher 0.12.19`, which
transitively caps `analyzer` below 13. Resolution **fails**.

The highest working set, verified by `flutter pub get`, `build_runner build`
and `dart analyze` (which reported *No issues found*):

```
flutter_riverpod:    3.3.2
riverpod_annotation: ^4.0.3
riverpod_generator:  4.0.4
riverpod_lint:       ^3.1.4
-> resolves analyzer 12.1.0
```

This still delivers Riverpod 3 with codegen. Revisit when Flutter's bundled
`test_api` advances.

### Finding B: `test: ^1.31.0` must be removed

The explicit `test` dev-dependency in `pubspec.yaml:60` is the direct cause of
the resolution failure above, and is redundant because `flutter_test`
re-exports the same API. Removing it requires updating two imports:

- `test/database_test.dart:5`
- `test/parsing_test.dart:2`

### Finding C: `custom_lint` must NOT be added

`riverpod_lint` 3.1.x is a **native analyzer plugin** (`analyzer_plugin`
0.14) and no longer depends on `custom_lint`. Adding `custom_lint: ^0.8.1`
produces a hard conflict (`analyzer_plugin` 0.13 vs 0.14). Enable it through
the `plugins:` key in `analysis_options.yaml` instead.

### Finding D: `--delete-conflicting-outputs` is removed

`build_runner` 2.15.1 prints `These options have been removed and were
ignored: --delete-conflicting-outputs`. The README and AGENTS.md still
document it. Use plain `dart run build_runner build`.

### Finding E: the Linux GTK4 probe is actively harmful

`linux/CMakeLists.txt` probes for `gtk4`, and only falls back to probing
`gtk+-3.0` when gtk4 is **absent**. On this machine gtk4 *is* present, so
`PkgConfig::GTK` is never defined, yet `linux/runner/CMakeLists.txt:24`
unconditionally links it. The runner is also pure GTK3 source. The probe is
dead code that breaks configuration on any gtk4 machine.

### Finding F: `riverpod_generator` cannot resolve types from `part` files

Drift generates its schema classes (`Tag`, `Task`, `TimeEntry`, `TagDao`,
…) inside `lib/database/database.g.dart`, which is declared as
`part of 'database.dart'` — that relationship is mandatory for drift's
builder. `riverpod_generator` 4.0.4 (the highest version that resolves
with Finding A's pinned analyzer 12.1.0) calls `DartType.toCode()` on
every resolved type, and that call throws `InvalidTypeException: The type
is invalid and cannot be converted to code.` for any `InterfaceType`
whose element is declared in a `part of` file. The exception is raised
from `riverpod_generator-4.0.4/lib/src/templates/parameters.dart:117`
and surfaces in the build log as:

```
E riverpod_generator on lib/core/providers/database.dart:
  InvalidTypeException: The type is invalid and cannot be converted to code.
```

Verified reproductions (all throw):

- `@riverpod List<Tag> tags(Ref ref) => const [];` (Tag is a `part of`)
- `@riverpod Tag probeTag(Ref ref) => throw …;`
- `@riverpod List<PartThing> probe(Ref ref) => const [];` where
  `PartThing` is declared in a plain `part of 'schema.dart'` file
  (hand-written, no drift involved)

A hand-written `class MyData extends DataClass implements Insertable<…>`
in a **non-part** file resolves and generates cleanly, so the trigger is
specifically the `part of` declaration site — not drift itself, and not
the `DataClass` hierarchy.

`riverpod_generator` 4.0.5+ pulls in `analyzer ^13`, which Finding A
proved unresolvable against Flutter 3.44.9's bundled `flutter_test`
transitive pins. Revisit when Flutter's `test_api` advances.

**Consequence for Phase 4.** Codegen is restricted to providers whose
return type and `ref.watch`-watched types are declared in ordinary
(non-part) files. That holds for `lib/core/providers/ui_state.dart`
(`DateTime`, `CalendarView` enum, `int?`, `List<String>`, generated
peer providers) but not for the drift layer. So:

- `ui_state.dart` — code-generated (`@Riverpod(keepAlive: true) class Foo`
  + one `@Riverpod(keepAlive: true) visibleDateKeys(Ref ref)` function).
  Generates `ui_state.g.dart` successfully; consumers updated; barrel
  `lib/providers/providers.dart` deleted; all 11 call sites import the
  focused modules.
- `database.dart`, `tasks.dart`, `time_entries.dart` — kept as plain
  `Provider` / `StreamProvider` / `Provider.family` declarations from
  Phase 2/3. They deliver the same Riverpod 3 idioms (typed reads via
  `ref.watch`, mutation via dedicated notifier classes where they
  already exist) without the boilerplate that codegen would otherwise
  remove. No functional gap: every consumer in the codebase already
  uses the typed Riverpod 3 read/watch API.

### Finding G: `drift_dev` CLI does not build against drift 2.34.3

`drift_dev` 2.34.0's `lib/src/services/schema/verifier_common.dart`
imports `drift_dev/src/...` paths that call
`drift3_preview/.../GeneratedDatabase` methods (`schema`,
`allSchemaEntities`) that drift 2.34.3 reorganised. Running
`dart run drift_dev schema dump` fails with:

```
_GenerateFromScratchDrift3 is missing implementations for these
members:
 - GeneratedDatabase.schema
Try to either ...
```

`drift_dev` 2.34.5 fixes the call sites but requires `analyzer ^13`,
which Finding A blocks. The `build_runner build` pipeline is
unaffected — `database.g.dart` still generates correctly.

**Consequence for Phase 5.** The `dart run drift_dev schema dump` and
`schema steps` CLI commands are unavailable. Phase 5 instead ships a
small `tool/dump_schema.dart` that opens an in-memory `ClockworkDatabase`,
queries `sqlite_master` plus `PRAGMA foreign_key_list`, and writes a
portable JSON dump into `drift_schemas/drift_schema_v<N>.json`. The
shape is intentionally simpler than drift_dev's wire format (flat table
list, no DSL features, no view/trigger DDL split) — it is just enough
to round-trip the schema through a migration test. Revisit when
drift_dev upgrades past the analyzer ^13 ceiling.

---

## 3. Current state assessment

### What is good

- Clean feature-folder layout under `lib/features/`.
- Zero `Widget _helper()` methods; private widget classes are used throughout.
- Only two lines exceed 80 characters in ~2000 lines of UI code.
- `quick_add_host.dart` is well designed and well documented.
- Tokens in `app/tokens.dart` are deliberately Flutter-free so the CLI can use
  them.

### What must change

| Area | Issue |
|---|---|
| Git | `lib/{app,core,features,shell,l10n}` are **untracked** |
| Build | gtk4 CMake bug (Finding E) |
| Build | `l10n.yaml` uses removed `synthetic-package: true` |
| Correctness | `today_screen.dart:226` sorts a provider's list **in `build()`** |
| Correctness | `task_edit_dialog.dart:109` shows the raw `YYYY-MM-DD` key |
| Errors | `tray_service.dart:43` swallows errors and blocks retry |
| Data model | `tags` overloaded as projects; no clients |
| Nav | No router; tab state lost on resize; not deep-linkable |
| Theme | No `ThemeExtension`, no `textTheme`, hardcoded `0x1F000000` |
| Widgets | `_DayColumn.build` 145 lines; `AddTimeDialog.build` 137 lines |
| Perf | Non-lazy `ListView`s; O(n*m) lookups per row |
| A11y | `GestureDetector` over `InkWell`; unlabelled colour swatches |
| Tests | Migrations untested; no schema snapshots; no integration tests |
| CI | None |
| Android | Template state: debug signing, stock icons, no SDK pinning |

---

## 4. Target architecture

```
lib/
  main.dart
  app/
    app.dart              MaterialApp.router
    router.dart           go_router config
    theme/
      theme.dart          ThemeData builders
      tokens.dart         Flutter-free constants
      extensions.dart     ClockworkTokens ThemeExtension
      typography.dart     TextTheme scale
      motion.dart         Expressive durations and curves
  core/
    logging/              logging setup
    result.dart           Result / failure types
    time/                 date helpers (from database/dates.dart)
  data/
    database/             drift schema, DAOs, migrations
    repositories/         interfaces + drift implementations
    secure/               credential storage
  domain/
    models/               Client, Project, Task, TimeEntry, Label
    services/             parsing, aggregation, reporting
    integrations/         Jira + calendar ports (local only)
  features/
    today/ calendar/ projects/ clients/ tasks/ quick_add/
    reports/ settings/
    shared/               reusable widgets
  platform/
    shortcuts/            portal, in-app, Android channels
    tray/ windowing/ notifications/
  l10n/
```

Layering rule: `features` -> `domain` -> `data`. `core` is shared by all.
Widgets never touch DAOs; they go through repositories via providers.

---

## 5. Verified dependency set

Add:

| Package | Version | Purpose |
|---|---|---|
| `flutter_riverpod` | `3.3.2` (pinned) | State management (Finding A) |
| `riverpod_annotation` | `^4.0.3` | Codegen annotations |
| `go_router` | `^17.5.0` | Declarative routing |
| `google_fonts` | `^8.2.1` | Typography |
| `flutter_secure_storage` | `^11.0.0` | Credential storage |
| `dbus` | `^0.7.14` | XDG portal, pure Dart |
| `logging` | `^1.3.0` | Replaces silent catches |
| `flutter_local_notifications` | `^22.3.0` | Android surface + fallback |

Dev:

| Package | Version | Purpose |
|---|---|---|
| `riverpod_generator` | `4.0.4` (pinned) | Provider codegen |
| `riverpod_lint` | `^3.1.4` | Riverpod lints |
| `integration_test` | sdk | End-to-end tests |
| `checks` | `^0.3.1` | Assertions (AGENTS.md) |

Remove: `test: ^1.31.0` (Finding B).
Do not add: `custom_lint` (Finding C), `hotkey_manager` (X11-only).

Deferred, with rationale:

- `freezed` / `json_serializable` — no JSON boundary exists while offline.
  Adopt in Phase 15 only if `.ics`/Jira mapping justifies it.
- `fl_chart` — plain widgets first; add only if reports need real charts.
- `sqlcipher_flutter_libs` — latest is `0.7.0+eol` (end-of-life). Encryption
  at rest is deferred; secrets go to `flutter_secure_storage`.

---

## 6. Phases

19 phases (0-18), 151 steps. Every phase ends with `flutter analyze` and
`flutter test` passing, and is independently committable.

Legend: **[!]** blocking risk, **[v]** verified on this machine.

### Phase 0 — Safety net

Nothing else may start until this is done.

0.1. **[!]** Commit the untracked tree. `lib/app/`, `lib/core/`,
     `lib/features/`, `lib/shell/`, `lib/l10n/`, `l10n.yaml` and
     `.agents/rules/` are untracked; the deletions of `lib/screens/` and
     `lib/widgets/` are unstaged. A single `git clean -fd` destroys the
     current architecture. Commit as "Restructure into app/core/features".
0.2. Tag the pre-rework state: `git tag pre-rework`.
0.3. Add `.github/workflows/ci.yaml`: `flutter analyze`, `flutter test`,
     `flutter build linux`, `flutter build apk --debug`. Pin Flutter 3.44.9.
0.4. Add a DB backup helper that copies `clockwork.db` to
     `clockwork.db.bak-<schemaVersion>` before any migration runs.

### Phase 1 — Critical fixes

Independent of the rework; each is a real defect found during analysis.

1.1. **[v]** Fix `linux/CMakeLists.txt` (Finding E). Probe gtk3
     unconditionally and link `PkgConfig::GTK`. Delete the gtk4/libadwaita
     probe and the unread `CLOCKWORK_GTK_HEADERBAR` comment.
1.2. Remove `synthetic-package: true` from `l10n.yaml`; add
     `output-dir: lib/l10n/generated` and `synthetic-package: false`.
     Verify `flutter gen-l10n` succeeds.
1.3. Fix `today_screen.dart:226`. The cascade binds to the `??` result and
     sorts the provider's cached list in place during `build()`. Replace with
     `[...entries]..sort(...)`, or sort in the provider.
1.4. Fix `task_edit_dialog.dart:109` to format via `DateFormat.yMMMd()`.
1.5. Fix `tray_service.dart:43`: log the error, and do not set
     `_initialized = true` until init actually succeeds.
1.6. Decide the headerbar `MethodChannel`. The native side does not exist, so
     `requestHeaderBar()` is always a silent no-op. Either delete it or
     document it as intentionally inert.
1.7. Reconcile `README.md` with reality: drop the libadwaita claims and the
     removed `--delete-conflicting-outputs` flag (Finding D).

### Phase 2 — Dependencies

2.1. **[v]** Remove `test: ^1.31.0` (Finding B).
2.2. **[v]** Switch `test/database_test.dart:5` and `test/parsing_test.dart:2`
     from `package:test/test.dart` to `package:flutter_test/flutter_test.dart`.
2.3. **[v]** Pin `flutter_riverpod: 3.3.2`, add `riverpod_annotation: ^4.0.3`.
2.4. **[v]** Add dev deps `riverpod_generator: 4.0.4`, `riverpod_lint: ^3.1.4`.
     Do **not** add `custom_lint` (Finding C).
2.5. Add `logging`, `go_router`, `google_fonts`, `flutter_secure_storage`,
     `dbus`, `flutter_local_notifications`, `integration_test`, `checks`.
2.6. Run `flutter pub get` and confirm the lockfile resolves `analyzer 12.1.0`.
2.7. Fix the empty-asset risk: `assets/images/` holds only `tray_icon.png`.
     Confirm the declaration still matches.

### Phase 3 — Lints, logging, docs

3.1. Tighten `analysis_options.yaml`: `lines_longer_than_80_chars`,
     `public_member_api_docs`, `prefer_const_constructors`,
     `always_declare_return_types`, `avoid_print`, `prefer_single_quotes`,
     `unawaited_futures`.
3.2. **[v]** Enable `riverpod_lint` via the `plugins:` key (Finding C).
3.3. Add `core/logging/logger.dart` wrapping `package:logging` onto
     `dart:developer` `log`.
3.4. Replace every silent `catch (_) {}` with a logged handler.
3.5. Fix the two >80-char lines: `week_view.dart:218-219`.
3.6. Add missing dartdoc: `TagFilterBar`, `TagManagerDialog`, `TagEditDialog`,
     `TaskEditDialog`.
3.7. Run `dart fix --apply`, then `dart format .`.

### Phase 4 — Riverpod 3 + codegen

4.1. Read the v2->v3 migration notes; the `Ref` type is now unified.
4.2. Convert `core/providers/database.dart` to `@riverpod`, giving the DAO
     providers explicit types (currently inferred). — *Blocked by Finding F.*
     Drift's schema classes live in a `part of` file that
     `riverpod_generator` 4.0.4 cannot resolve. Kept manual; Riverpod 3
     typed reads are already in place from Phase 2.
4.3. Convert `ui_state.dart`. The `StateProvider`s become `@riverpod` classes
     with named mutation methods instead of `.state =` writes. — *Done.*
     `SelectedDate`, `CalendarAnchor`, `CalendarViewMode`, `TagFilter`,
     `QuickAddRequest`, and `HomeTab` are now `@Riverpod(keepAlive: true)
     class … extends _$…`. `visibleDateKeys` becomes
     `@Riverpod(keepAlive: true) List<String> visibleDateKeys(Ref ref)`.
4.4. Convert `tasks.dart` and `time_entries.dart`; `.family` becomes
     annotated parameters. — *Blocked by Finding F.* Kept manual.
4.5. Replace the `String`-joined key hack in `_taskEntriesProvider` with a
     typed parameter now that codegen handles equality. — *Deferred.*
     Requires codegen on `time_entries.dart` (Finding F). Tracked in
     the risk register.
4.6. Move `_HomeShellState._tab` into a provider so the tab survives resize.
     — *Done.* `HomeTab` notifier added to `ui_state.dart`;
     `_NarrowLayout` is now a `ConsumerWidget` keyed on
     `homeTabProvider`. (Note: the field lived in `_NarrowLayoutState`,
     not `_HomeShellState` as the original plan text said; same intent.)
4.7. **[v]** Run `dart run build_runner build` (no removed flag). — *Done.*
     Generates `ui_state.g.dart` cleanly. Drift layer is untouched by
     riverpod_generator because it carries no `@riverpod` annotations.
4.8. Delete the `lib/providers/providers.dart` compatibility barrel and
     update imports. — *Done.* 11 call sites in `lib/` + 1 in `test/`
     now import the focused modules directly. `dart analyze` clean,
     16 tests pass.
4.9. Update `test/widget_test.dart` overrides for v3. — *No change needed.*
     The existing `databaseProvider.overrideWithValue(db)` still works
     because the manual `databaseProvider` has the same API surface.

Net effect: the project's Riverpod 3 migration is complete; codegen is
shipped for the layer where it works. Revisit when Finding F is fixed.

### Phase 5 — Schema v3

Highest-risk phase. Snapshots and tests come before the migration.

5.1. Add `build.yaml` enabling drift schema snapshots. — *Done.*
     `build.yaml` declares `schema_dir: drift_schemas`, `test_dir:
     test/drift`, and the `clockwork` database mapping. The drift_dev
     CLI itself does not build (Finding G); the build builder is
     unaffected.
5.2. **[!]** Dump the current v2 schema to `drift_schemas/`. Only v2 can be
     dumped; reconstruct v1 by hand from `_migrateToDurationEntries` if a
     v1 test is wanted. — *Done via `tool/dump_schema.dart` (Finding G).*
     Output: `drift_schemas/drift_schema_v2.json` — a flat
     `sqlite_master` + `PRAGMA foreign_key_list` representation. v1
     reconstruction deferred (the existing v1->v2 path is not exercised
     in CI; tests cover the v2 baseline shape instead).
5.3. Write migration tests for v2 that pass **before** any schema change.
     — *Done.* `test/drift/migration_v2_test.dart` locks down the
     baseline: `schemaVersion == 2`, the three table names, the
     self-referencing `tags.parent_id` FK with `SET NULL`, the v2
     `time_entries` column shape (`date`, `minutes`, no `start`/`end`),
     and the existence of the snapshot file.
5.4. Define new tables:
     - `clients(id, name, color, archived, notes)`
     - `projects(id, name, color, client_id?, parent_id?, archived)`
     - `labels(id, name, color)`
     - `task_labels(task_id, label_id)` join
     - `settings(key, value)`
     - `integration_accounts(id, kind, display_name, config_json, enabled)`
     — *Pending.* Tracked for the next session.
5.5. Alter `tasks`: add `project_id?`, `client_id?`, `jira_issue_key?`,
     `estimate_minutes?`, `created_at`, `updated_at`. Keep `tag_id` during
     migration, drop it at the end. — *Pending.*
5.6. Alter `time_entries`: add `project_id?`, `client_id?`, `created_at`,
     `updated_at`, `source` (manual / shortcut / import). — *Pending.*
5.7. Add indices on the hot paths: `time_entries(date)`, `tasks(date)`,
     `time_entries(task_id)`, `projects(client_id)`. — *Pending.*
5.8. **[!]** Write the v2->v3 migration. Root tags become projects; child tags
     become projects with `parent_id`; `tasks.tag_id` and
     `time_entries.tag_id` map to `project_id`. — *Pending.*
5.9. **[!]** Wrap table rewrites in `PRAGMA foreign_keys = OFF` plus
     `defer_foreign_keys`. The existing v1->v2 migration omits this and only
     survives because it runs before `beforeOpen`. Any rewrite of `tags` or
     `tasks` now has inbound references. — *Pending.*
5.10. Call the Phase 0 backup helper before migrating. — *Done.*
     `lib/database/backup.dart` exposes `backupDatabase(File)` and
     `pruneBackups(...)`. `openDatabase()` and `openDatabaseAt()` now
     peek at `PRAGMA user_version` via `package:sqlite3` (read-only)
     and call the backup helper before handing the file to drift.
     `currentSchemaVersion` is a top-level constant kept in lockstep
     with `ClockworkDatabase.schemaVersion`. Backed by
     `test/database_backup_test.dart` (3 cases).
5.11. Write v2->v3 migration tests over a seeded v2 database. — *Pending.*
     Will follow 5.8 / 5.9.
5.12. Regenerate and verify `streamUpdateRules` cover the new FKs.
     — *Pending.* Stream update rules are a drift runtime feature; they
     follow automatically from `@DriftDatabase(tables: [...])`.
     Verification deferred to the schema-redesign step.

### Phase 6 — Repository layer

6.1. Define `domain/models/` as immutable classes, decoupled from drift rows.
6.2. Define repository interfaces: `ClientRepository`, `ProjectRepository`,
     `TaskRepository`, `TimeEntryRepository`, `LabelRepository`,
     `SettingsRepository`.
6.3. Implement each over the DAOs; map rows to domain models.
6.4. Move aggregation (daily totals, per-task hours, tag totals) out of
     providers into repositories or domain services, so it is unit-testable
     without Flutter.
6.5. Replace the O(n*m) `firstOrNull` scans with map lookups built once.
6.6. Add in-memory fakes for every repository (AGENTS.md prefers fakes).
6.7. Repoint providers at repositories; no widget touches a DAO.
6.8. Unit-test each repository against a memory database.

### Phase 7 — Design system (Material 3 Expressive)

7.1. Extend `tokens.dart` with spacing, radius, elevation, motion and opacity
     scales. Keep it Flutter-free.
7.2. Add `ClockworkTokens extends ThemeExtension` with `copyWith` and `lerp`,
     and register it in both themes.
7.3. Remove the `export 'tokens.dart'` from `theme.dart`; import tokens
     directly so widgets do not pull Flutter in for integers.
7.4. Build a real `textTheme` with `google_fonts`, line heights 1.4-1.6 and
     an explicit type scale.
7.5. **[!]** Replace the hardcoded `Color(0x1F000000)` AppBar border at
     `theme.dart:68` with `scheme.outlineVariant`; it is invisible in dark
     mode.
7.6. Adopt expressive shapes: larger, differentiated corner radii per
     component role.
7.7. Add `motion.dart` with expressive durations and emphasised easing;
     use it for nav transitions and FAB morphs.
7.8. Add a `themeMode` provider plus a Settings toggle
     (system / light / dark).
7.9. Unify the two colour palettes: `tag_manager_dialog.dart:9-26` defines 16
     colours entirely separate from `kAutoTagColors` in `tokens.dart:26-35`.
     One source of truth.
7.10. Build `features/shared/` widgets: `DurationText`, `ColorSwatchPicker`
      (with `Semantics` labels), `EmptyState`, `SectionHeader`,
      `OverLimitBadge` (replacing three near-identical tooltip blocks).
7.11. Replace remaining hardcoded paddings with tokens, including the
      `kSpacingXs + 2` arithmetic in `month_view.dart:128,133`.

### Phase 8 — Navigation

8.1. Add `app/router.dart` with routes `/today`, `/calendar`, `/projects`,
     `/clients`, `/reports`, `/settings`.
8.2. Switch to `MaterialApp.router`.
8.3. Build an adaptive shell: `NavigationBar` under 600dp,
     `NavigationRail` 600-1240dp, extended rail above.
8.4. Move the `720` and `380` magic numbers into named breakpoint tokens and
     add the missing medium tier.
8.5. Hoist the filter bar above the layout branch so it stops remounting.
8.6. Keep dialogs on the plain `Navigator` (explicitly allowed by AGENTS.md).
8.7. Preserve the selected date and view across navigation.
8.8. Add deep links: `/calendar?date=YYYY-MM-DD`, `/projects/:id`.

### Phase 9 — Quick add and time entry

9.1. Move duration parsing from `lib/cli/parsing.dart` into
     `domain/services/duration_parser.dart`; keep the CLI using it.
9.2. Write a natural-language parser for `+2 hours on <project>` supporting
     `+2h`, `2h30m`, `90m`, `1.5h`, plus `on <project>`, `#label`,
     `@client`, `for <task>`, `yesterday`.
9.3. Unit-test the parser hard, including failure cases.
9.4. Build `QuickAddBar` with live parse preview and `Autocomplete` over
     projects, clients and tasks.
9.5. Auto-create projects on first use, mirroring the CLI's
     `findOrCreateTag`.
9.6. **[!]** Decompose the 137-line `AddTimeDialog.build` into
     `_HoursStepper`, `_QuickPickChips`, `_TargetSelectors`, `_DateField`.
9.7. Move the 12-line cross-validation closure out of `onChanged` into a
     notifier method.
9.8. Add inline validation with visible error text; today it fails silently.
9.9. Add undo via `SnackBar` after create and delete.
9.10. Add confirmation dialogs before destructive deletes in
      `tag_manager_dialog.dart:194` and `task_edit_dialog.dart:122`.

### Phase 10 — Calendar

10.1. **[!]** Rewrite `_DayColumn.build` (145 lines) as `_DayHeader`,
      `_DayTaskRow`, `_DayEntryChip`.
10.2. Split `MonthView.build` (79) and `_DayCell.build` (74).
10.3. Remove the `Builder`-as-scope hack in `week_view.dart:30-62` and
      `month_view.dart:37-52`.
10.4. Precompute per-day buckets once instead of rescanning per day.
10.5. Replace non-lazy `ListView`s with `.builder`.
10.6. **[!]** Replace the hardcoded English weekday names at
      `month_view.dart:59` with `DateFormat.E()`; they block localisation.
10.7. Swap `GestureDetector` for `InkWell` and add `Semantics` labels.
10.8. Make cells height-flexible so large text scales do not overflow.
10.9. Add month navigation, a today affordance, and per-day totals with the
      over-limit badge.

### Phase 11 — Tasks

11.1. Task list with filters by project, client, label and done state.
11.2. Task detail: title, notes, project, client, labels, estimate, date.
11.3. Associate time entries with tasks; show roll-up totals per task.
11.4. Add a `jira_issue_key` field with format validation (`ABC-123`),
      stored locally only.
11.5. Label management UI backed by the `task_labels` join.
11.6. Move a task between dates.

### Phase 12 — Clients and projects

12.1. Client CRUD with colour and archive.
12.2. Project CRUD with client assignment and optional parent.
12.3. Assign tracked hours to a client, directly or inherited from project.
12.4. Reassignment flow, including bulk move.
12.5. Guard against cycles in the project parent chain.
12.6. Per-client and per-project totals for the visible range.

### Phase 13 — Global shortcuts (Wayland-correct)

13.1. **[v]** Implement `GlobalShortcutsPortalService` over
      `org.freedesktop.portal.GlobalShortcuts` using `package:dbus`.
      Verified present on this machine at version 1, exposing
      `CreateSession`, `BindShortcuts`, `ListShortcuts`,
      `ConfigureShortcuts`, and the `Activated` / `Deactivated` /
      `ShortcutsChanged` signals. Pure Dart; no native code.
13.2. Bind `start-or-stop`, `quick-add` and `show-window`; let the compositor
      own the actual key assignment.
13.3. Listen for `Activated` and route to the same intents the tray uses.
13.4. **[!]** Handle the unsandboxed case. Portals may require an app-id hint;
      if `CreateSession` fails, degrade rather than crash.
13.5. Fallback chain: portal -> in-app `Shortcuts`/`Actions` -> tray ->
      notification action. Log which tier is active.
13.6. Add in-app `Shortcuts`/`Actions` for new task, quick add, today,
      next/previous period, search.
13.7. Add a Settings page showing the active tier, bound shortcuts, and a
      `ConfigureShortcuts` button.
13.8. Use `org.freedesktop.portal.Background` for optional autostart.
13.9. Keep the tray, but treat it as optional: on GNOME it depends on the
      user's AppIndicator extension.

### Phase 14 — Android surfaces

14.1. **[!]** Pin `compileSdk`, `minSdk`, `targetSdk` to explicit integers.
      They currently defer to the Flutter plugin, so builds are not
      reproducible. Target minSdk 23+ for `flutter_secure_storage`.
14.2. **[!]** Add a real signing config via `key.properties`; release
      currently signs with the **debug** key.
14.3. Add `shortcuts.xml` static app shortcuts for Quick Add and Today.
14.4. Add a quick-settings `TileService` for start/stop.
14.5. Add an ongoing notification with quick actions via
      `flutter_local_notifications`, including the Android 13
      `POST_NOTIFICATIONS` permission request.
14.6. Wire a `MethodChannel` in `MainActivity.kt` (currently the bare
      template) to route shortcut and tile intents into the same intents.
14.7. Generate proper launcher icons, including adaptive icons.
14.8. Verify the responsive layout on phone and tablet.

### Phase 15 — Integrations (local only)

No network calls. Ports exist so a future sync layer needs no schema change.

15.1. Settings section for integration accounts.
15.2. Store credentials in `flutter_secure_storage`; never in SQLite. Persist
      only non-secret config in `integration_accounts.config_json`.
15.3. Define `IssueTrackerPort` and `CalendarPort` interfaces, with the sync
      methods present but unimplemented and documented as such.
15.4. Jira: store site URL, email and API token; validate format only, do not
      call the network. Attach issue keys to tasks and render them as
      deep links to the browser.
15.5. Google Calendar: implement `.ics` **file** import. Parse `VEVENT`
      (`DTSTART`, `DTEND`, `SUMMARY`, `UID`), map to read-only calendar
      overlays.
15.6. Store imported events in a dedicated table with a `source` marker so
      they never mix with tracked time.
15.7. Show imported events in the calendar with distinct styling, and offer
      one-tap conversion into a time entry.
15.8. Make it obvious in the UI that nothing is synced.
15.9. Only if `.ics` mapping proves messy, add `json_serializable`.

### Phase 16 — Reporting

16.1. Week and month rollups grouped by client, project and task.
16.2. Keep the 8h/day over-limit warning; make the limit configurable.
16.3. CSV export with a date range and a grouping choice.
16.4. Use the existing platform file dialog; no new dependency.
16.5. Simple bar visualisation with plain widgets; reconsider `fl_chart`
      only if this proves insufficient.

### Phase 17 — Testing

17.1. Unit-test the duration and NL parsers, including failures.
17.2. Unit-test repositories against a memory database.
17.3. **[!]** Test the v2->v3 migration against seeded data; migrations are
      currently untested and every test starts from `createAll`.
17.4. Test aggregation and date helpers.
17.5. Widget-test quick add, calendar, task edit and navigation.
17.6. Add `integration_test` for: log time end to end, assign to client,
      switch week/month, import `.ics`.
17.7. Test at 2.0x text scale and at 320dp width.
17.8. Migrate assertions to `package:checks` per AGENTS.md.
17.9. Collect coverage and wire it into CI.

### Phase 18 — Packaging and docs

18.1. Add `dev.sequ.clockwork.desktop` and an AppStream metainfo file.
18.2. Install the icon from CMake; nothing installs one today.
18.3. Add a Flatpak manifest. This also gives the portal a proper app id,
      which helps Phase 13.
18.4. Verify the Android release build with real signing.
18.5. Rewrite the README around the new architecture.
18.6. Document the CLI, which shares the data layer and must be updated for
      clients and projects.
18.7. Add `docs/ARCHITECTURE.md` and `docs/SHORTCUTS.md`.

---

## 7. Risk register

| # | Risk | Impact | Mitigation |
|---|---|---|---|
| R1 | Schema v3 migration corrupts data | High | Snapshots, tests before the change, automatic backup, FK-safe rewrite (5.9) |
| R2 | Portal shortcuts fail unsandboxed | Medium | Four-tier fallback (13.5); Flatpak (18.3) |
| R3 | Riverpod 3 breaking changes | Medium | Isolated in Phase 4; pinned versions (Finding A) |
| R4 | GNOME tray needs an extension | Low | Tray optional; notification fallback |
| R5 | Analyzer pin blocks future upgrades | Low | Documented; revisit when Flutter's `test_api` moves |
| R6 | Expressive rewrite regresses UX | Medium | Phase by phase, app green throughout |
| R7 | `.ics` parsing edge cases | Low | Strict subset; skip unparseable events with a log |
| R8 | Android release signing | High | Phase 14.2 before any release |
| R9 | Scope creep into real sync | Medium | Ports unimplemented by contract; no HTTP dependency |

---

## 8. Sequencing

Phase 0 must complete first. Phases 1-3 are independent cleanups and can be
reordered. Phase 4 precedes Phase 6 (providers before repositories). Phase 5
precedes Phases 10-12 (schema before features). Phase 7 precedes Phases 8-12
(design system before UI). Phase 13 is independent after Phase 3. Phases 17
and 18 are continuous rather than terminal: add tests with each phase.

Suggested milestones:

- **M1 — Stable base**: Phases 0-4. App builds, CI green, Riverpod 3.
- **M2 — New data model**: Phases 5-6. Clients and projects exist.
- **M3 — New UI**: Phases 7-10. Material 3 Expressive, routed, responsive.
- **M4 — Full features**: Phases 11-16. Clients, shortcuts, integrations.
- **M5 — Shippable**: Phases 17-18. Tested and packaged.

## 9. Commands

```sh
flutter pub get
dart run build_runner build          # no --delete-conflicting-outputs
flutter gen-l10n
flutter analyze
flutter test
flutter test integration_test
dart format .
dart fix --apply

flutter run -d linux
flutter run                          # Android
flutter build linux --release
flutter build apk --release
```

## 10. Open items

1. Encryption at rest is deferred; `sqlcipher_flutter_libs` is end-of-life.
2. The CLI needs updating for clients and projects (18.6); its command
   surface should mirror the GUI hierarchy.
3. Localisation currently has only `app_en.arb` with 9 unused messages.
   Decide whether to complete or defer it.
4. The headerbar `MethodChannel` decision from 1.6.
