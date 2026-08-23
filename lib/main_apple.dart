import 'package:clockwork/app/app.dart';
import 'package:clockwork/core/di/app_dependencies.dart';
import 'package:clockwork/flavors/flavor_config.dart';
import 'package:clockwork/shell/windowing.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  FlavorConfig.current = FlavorConfig(
    flavor: AppFlavor.apple,
    appTitle: 'Clockwork (Apple)',
    applicationIdSuffix: '.apple',
  );
  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.macOS) {
    await initializeWindowing();
  }
  final dependencies = AppDependencies.create();
  runApp(ClockworkApp(dependencies: dependencies));
}
