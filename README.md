# Clockwork

Daily task management and project time tracking, built with Flutter.

- **Left pane**: a welcome message, your tasks for the selected day with the
  hours spent on each, and the time entries you logged.
- **Right pane**: a calendar overview of your tasks and tracked time, with a
  **week / month toggle**.
- **Quick logging**: press the **+** button, choose how many hours to add,
  attach an optional comment or tag, and confirm.
- **Working-hours warning**: days over 8 hours get a warning indicator next
  to the total.
- **Projects**: tag system for projects and subprojects, with color coding
  and filtering.
- **SQLite database** (drift) shared between the GUI and the CLI.
- **System tray** (desktop only): "Add time..." opens a minimal hours + plus
  widget; closing/minimizing hides the app to the tray.

Platforms: Linux desktop and Android.

## Run the GUI

```sh
flutter run -d linux
flutter run            # Android device/emulator
```

## Build the CLI

```sh
dart build cli -o build/cli
# binary: build/cli/bundle/bin/clockwork
```

On desktop, GUI and CLI share the same database at
`$XDG_DATA_HOME/clockwork/clockwork.db` (default `~/.local/share/clockwork/clockwork.db`).

### CLI usage

```sh
clockwork add +2 --project p-name --day today
clockwork add 90m --project p-name -c "code review"
clockwork add 1h30m --project other --day yesterday

clockwork list [--day D]            # time entries for a day
clockwork today                     # today's tasks + tracked time
clockwork week                      # week summary by day and project

clockwork task add "Title" [--project P] [--day D]
clockwork task list [--day D]
clockwork task done ID | clockwork task rm ID

clockwork project add Name [--parent P] [--color RRGGBB]
clockwork project list | clockwork project rm NAME_OR_ID
```

Duration formats: `+2`, `2`, `1.5h`, `90m`, `1h30m`. A bare number is hours.
Day formats: `today`, `yesterday`, `YYYY-MM-DD`.

## Development

```sh
dart run build_runner build                 # after schema changes
flutter gen-l10n                            # after adding strings
flutter analyze
flutter test
```

## Project layout

```
lib/
  app/             # bootstrap, theming, design tokens (Phase 0/1)
    app.dart       # ClockworkApp root
    theme.dart     # Material 3 / libadwaita-flavored ThemeData
    tokens.dart    # Flutter-free design tokens (used by CLI too)

  core/
    database/      # drift schema, DAOs, paths, dates (unchanged)
    providers/     # Riverpod providers, split per concern:
      database.dart  # DB & DAO providers
      ui_state.dart  # selected date, filter, calendar view
      tasks.dart     # task streams & computed views
      time_entries.dart  # entry streams & aggregates

  features/        # one folder per UI feature
    today/         # left pane (today_screen.dart + tag_filter_bar)
    calendar/      # right pane (calendar_panel + week/month views)
    tags/          # tag manager dialog
    quick_add/     # add-time & quick-add dialogs + dialog host
    tasks/         # task edit dialog

  shell/
    home_shell.dart  # responsive layout, AppBar, FAB, tray lifecycle
    windowing.dart   # GTK4/libadwaita headerbar hook (MethodChannel)

  services/
    tray_service.dart  # system tray integration
  providers/
    providers.dart  # backwards-compat barrel re-exporting core/providers
```

The CLI lives in `bin/clockwork.dart` and shares the data layer (database,
dates, paths, tokens) with the GUI.

## Rework in progress

A multi-phase rework is underway; see `docs/REWORK_PLAN.md`. The current
Linux build uses the GTK3 Flutter embedder. The libadwaita headerbar
described in earlier revisions is not implemented and the
`MethodChannel('dev.sequ.clockwork/headerbar')` calls are intentionally
no-ops until a native shim is added.
