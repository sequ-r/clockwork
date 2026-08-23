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
- **System tray** (desktop): "Add time..." opens a minimal hours + plus
  widget; closing/minimizing hides the app to the tray.

---

## Flavors & Platform Design Systems

Clockwork supports multi-platform flavors, each tailored with its native design system and capabilities:

| Flavor | Target | UI Framework / Packages | Highlights |
| :--- | :--- | :--- | :--- |
| **Linux Desktop** | Linux | `package:yaru` (Canonical) | Canonical Yaru theme, `YaruTitleBar`, system tray integration, and desktop windowing. |
| **Android** | Android / Mobile | `Material 3 Expressive` + `package:dual_screen` | Expressive M3 theme, squircle curves, tonal elevation, and foldable phone hinge responsiveness. |
| **Apple** | macOS / iOS | `package:flutter/cupertino.dart` | Apple HIG Cupertino design, `CupertinoPageScaffold`, `CupertinoNavigationBar`, `CupertinoTabBar`, `CupertinoActionSheet`. |
| **Windows** | Windows | `package:fluent_ui` | Microsoft Fluent Design System, `NavigationView` with acrylic sidebar, Windows 11 controls, and tray support. |

---

## Run the App

### Linux Flavor (Canonical Yaru)
```sh
flutter run -t lib/main_linux.dart -d linux
```

### Android Flavor (Material 3 Expressive & Foldables)
```sh
flutter run --flavor android -t lib/main_android.dart -d android
```

### Apple Flavor (macOS / iOS Cupertino)
```sh
# macOS Desktop
flutter run -t lib/main_apple.dart -d macos

# iOS Simulator / Device
flutter run -t lib/main_apple.dart -d ios
```

### Windows Flavor (Microsoft Fluent UI)
```sh
flutter run -t lib/main_windows.dart -d windows
```

### Auto-detect / Default
```sh
flutter run
```

---

## Build Instructions

### Linux Desktop Binary
```sh
flutter build linux -t lib/main_linux.dart --release
# Output: build/linux/x64/release/bundle/
```

### Android APK / App Bundle
```sh
# Build APK
flutter build apk --flavor android -t lib/main_android.dart --release

# Build App Bundle (AAB)
flutter build appbundle --flavor android -t lib/main_android.dart --release
```

### macOS Application / iOS IPA
```sh
# macOS App
flutter build macos -t lib/main_apple.dart --release

# iOS Bundle
flutter build ipa -t lib/main_apple.dart --release
```

### Windows Desktop Executable
```sh
flutter build windows -t lib/main_windows.dart --release
# Output: build/windows/x64/runner/Release/
```

---

## Build & Run the CLI

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

---

## Development & Testing

```sh
# Run static analysis
dart analyze

# Run test suite
flutter test

# Rebuild code generation & Drift schema migrations (after schema changes)
dart run build_runner build --delete-conflicting-outputs

# Generate localization files
flutter gen-l10n
```

---

## Project Layout

```
lib/
  app/                    # Core app bootstrapping and design tokens
    app.dart              # ClockworkApp root with flavor switching
    theme.dart            # Base theme definitions
    tokens.dart           # Design tokens (shared with CLI)
  flavors/                # Platform flavors and UI shells
    flavor_config.dart    # FlavorConfig enum and platform capability detection
    linux/                # Linux Desktop (Canonical Yaru design & titlebar)
      linux_theme.dart
      linux_home_shell.dart
    android/              # Android (Material 3 Expressive & Foldable two-pane)
      android_expressive_theme.dart
      android_foldable_home_shell.dart
    apple/                # Apple macOS / iOS (Cupertino design system)
      apple_theme.dart
      apple_home_shell.dart
    windows/              # Windows (Microsoft Fluent UI & NavigationView)
      windows_theme.dart
      windows_home_shell.dart
  core/
    di/                   # Dependency injection scoping (ClockworkScope)
    view_models/          # Core AppViewModel (ChangeNotifier)
  data/
    repositories/         # Task, Tag, and TimeEntry repositories
  database/               # Drift schema, DAOs, dates, and database backup
  features/               # Feature widgets
    today/                # Today task list & logged time section
    calendar/             # Calendar panel with week/month grid
    tags/                 # Project & tag manager dialogs
    quick_add/            # Quick-add & add-time dialogs
    tasks/                # Task edit dialog
  services/
    tray_service.dart     # Desktop system tray integration
  main_linux.dart         # Linux flavor entry point
  main_android.dart       # Android flavor entry point
  main_apple.dart         # Apple macOS/iOS flavor entry point
  main_windows.dart       # Windows flavor entry point
  main.dart               # Default entry point
```
