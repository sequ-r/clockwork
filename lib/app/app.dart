import 'package:clockwork/app/theme.dart';
import 'package:clockwork/core/di/app_dependencies.dart';
import 'package:clockwork/l10n/generated/app_localizations.dart';
import 'package:clockwork/shell/home_shell.dart';
import 'package:flutter/material.dart';

/// Root widget of Clockwork.
///
/// Configures theme, internationalization, dependency scoping, and
/// delegates presentation to [HomeShell].
class ClockworkApp extends StatelessWidget {
  /// Creates the application root with optional injected [dependencies].
  const ClockworkApp({super.key, this.dependencies});

  /// Injected application dependencies; created automatically when omitted.
  final AppDependencies? dependencies;

  @override
  Widget build(BuildContext context) {
    final deps = dependencies ?? AppDependencies.create();

    return ClockworkScope(
      dependencies: deps,
      child: MaterialApp(
        title: 'Clockwork',
        theme: buildLightTheme(),
        darkTheme: buildDarkTheme(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const HomeShell(),
      ),
    );
  }
}
