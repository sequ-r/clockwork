import 'package:clockwork/app/app.dart';
import 'package:clockwork/core/di/app_dependencies.dart';
import 'package:clockwork/flavors/flavor_config.dart';
import 'package:clockwork/shell/windowing.dart';
import 'package:flutter/material.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  FlavorConfig.current = FlavorConfig(
    flavor: AppFlavor.windows,
    appTitle: 'Clockwork (Windows)',
    applicationIdSuffix: '.windows',
  );
  await initializeWindowing();
  final dependencies = AppDependencies.create();
  runApp(ClockworkApp(dependencies: dependencies));
}
