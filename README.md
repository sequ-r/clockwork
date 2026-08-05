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
dart run build_runner build --delete-conflicting-outputs  # after schema changes
flutter analyze
flutter test
```
