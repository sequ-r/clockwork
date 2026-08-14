import 'package:clockwork/app/app.dart';
import 'package:clockwork/core/di/app_dependencies.dart';
import 'package:clockwork/shell/windowing.dart';
import 'package:flutter/material.dart';

// Re-exported so widget tests can pump `ClockworkApp` without reaching
// into `app/app.dart` directly.
export 'package:clockwork/app/app.dart' show ClockworkApp;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeWindowing();
  final dependencies = AppDependencies.create();
  runApp(ClockworkApp(dependencies: dependencies));
}
