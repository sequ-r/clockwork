import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'shell/windowing.dart';

// Re-exported so widget tests can pump `ClockworkApp` without reaching
// into `app/app.dart` directly.
export 'app/app.dart' show ClockworkApp;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeWindowing();
  runApp(const ProviderScope(child: ClockworkApp()));
}
