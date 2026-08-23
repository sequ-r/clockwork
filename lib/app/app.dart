import 'package:clockwork/core/di/app_dependencies.dart';
import 'package:clockwork/flavors/android/android_expressive_theme.dart';
import 'package:clockwork/flavors/android/android_foldable_home_shell.dart';
import 'package:clockwork/flavors/apple/apple_home_shell.dart';
import 'package:clockwork/flavors/apple/apple_theme.dart';
import 'package:clockwork/flavors/flavor_config.dart';
import 'package:clockwork/flavors/linux/linux_home_shell.dart';
import 'package:clockwork/flavors/linux/linux_theme.dart';
import 'package:clockwork/flavors/windows/windows_home_shell.dart';
import 'package:clockwork/flavors/windows/windows_theme.dart';
import 'package:clockwork/l10n/generated/app_localizations.dart';
import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// Root widget of Clockwork.
///
/// Adapts the UI presentation and styling according to the active
/// [flavorConfig].
class ClockworkApp extends StatelessWidget {
  /// Creates the application root with optional injected [dependencies]
  /// and [flavorConfig].
  const ClockworkApp({super.key, this.dependencies, this.flavorConfig});

  /// Injected application dependencies; created automatically when omitted.
  final AppDependencies? dependencies;

  /// Injected flavor configuration; defaults to [FlavorConfig.current].
  final FlavorConfig? flavorConfig;

  @override
  Widget build(BuildContext context) {
    final deps = dependencies ?? AppDependencies.create();
    final config = flavorConfig ?? FlavorConfig.current;

    return ClockworkScope(
      dependencies: deps,
      child: switch (config.flavor) {
        AppFlavor.linux => MaterialApp(
          title: config.appTitle,
          theme: LinuxTheme.lightTheme,
          darkTheme: LinuxTheme.darkTheme,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const LinuxHomeShell(),
        ),
        AppFlavor.android => MaterialApp(
          title: config.appTitle,
          theme: AndroidExpressiveTheme.lightTheme,
          darkTheme: AndroidExpressiveTheme.darkTheme,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const AndroidFoldableHomeShell(),
        ),
        AppFlavor.apple => CupertinoApp(
          title: config.appTitle,
          theme: AppleTheme.lightTheme,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const AppleHomeShell(),
        ),
        AppFlavor.windows => fluent.FluentApp(
          title: config.appTitle,
          theme: WindowsTheme.lightTheme,
          darkTheme: WindowsTheme.darkTheme,
          localizationsDelegates: [
            ...AppLocalizations.localizationsDelegates,
            fluent.FluentLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: const WindowsHomeShell(),
        ),
      },
    );
  }
}
