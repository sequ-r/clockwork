# Clockwork

Daily task management and project time tracking, built with Flutter.

- **Overview screen**: task list for the selected day + a week calendar view
  with per-day tracked time.
- **Manual time tracking** via the "Track time" button (tag, optional task,
  date, start/end).
- **Tag system** for projects and subprojects (parent tags), with color
  coding and filtering.
- **SQLite database** (drift) shared between the GUI and the CLI.
- **System tray** (desktop only): quick-add tracked time per tag from the
  tray menu; closing the window hides the app to the tray.

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
clockwork tag add Project [--parent P] [--color RRGGBB]
clockwork tag list | clockwork tag rm NAME_OR_ID

clockwork task add "Title" [--tag T] [--date YYYY-MM-DD]
clockwork task list [--date YYYY-MM-DD]
clockwork task done ID | clockwork task rm ID

clockwork time add 1h30m --tag Project [--notes "..."]
clockwork time add --tag Project --start 09:00 --end 11:15 [--date D]

clockwork today        # today's tasks + tracked time
clockwork week         # week summary by day and tag
```

## Development

```sh
dart run build_runner build --delete-conflicting-outputs  # after schema changes
flutter analyze
flutter test
```
