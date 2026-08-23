import 'package:clockwork/app/app.dart';
import 'package:clockwork/core/di/app_dependencies.dart';
import 'package:clockwork/database/database.dart';
import 'package:clockwork/flavors/android/android_foldable_home_shell.dart';
import 'package:clockwork/flavors/apple/apple_home_shell.dart';
import 'package:clockwork/flavors/flavor_config.dart';
import 'package:clockwork/flavors/linux/linux_home_shell.dart';
import 'package:clockwork/flavors/windows/windows_home_shell.dart';
import 'package:drift/native.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FlavorConfig', () {
    test('provides correct metadata for all flavors', () {
      final linuxConfig = FlavorConfig(
        flavor: AppFlavor.linux,
        appTitle: 'Clockwork (Linux)',
        applicationIdSuffix: '.linux',
      );
      expect(linuxConfig.isLinux, isTrue);
      expect(linuxConfig.isDesktop, isTrue);
      expect(linuxConfig.supportsSystemTray, isTrue);
      expect(linuxConfig.supportsFoldables, isFalse);

      final androidConfig = FlavorConfig(
        flavor: AppFlavor.android,
        appTitle: 'Clockwork (Android)',
        applicationIdSuffix: '.android',
      );
      expect(androidConfig.isAndroid, isTrue);
      expect(androidConfig.supportsFoldables, isTrue);

      final appleConfig = FlavorConfig(
        flavor: AppFlavor.apple,
        appTitle: 'Clockwork (Apple)',
        applicationIdSuffix: '.apple',
      );
      expect(appleConfig.isApple, isTrue);

      final windowsConfig = FlavorConfig(
        flavor: AppFlavor.windows,
        appTitle: 'Clockwork (Windows)',
        applicationIdSuffix: '.windows',
      );
      expect(windowsConfig.isWindows, isTrue);
      expect(windowsConfig.isDesktop, isTrue);
    });
  });

  group('ClockworkApp Flavor Rendering', () {
    late ClockworkDatabase db;
    late AppDependencies deps;

    setUp(() {
      db = ClockworkDatabase(NativeDatabase.memory());
      deps = AppDependencies.create(database: db);
    });

    tearDown(() async {
      await deps.dispose();
    });

    Future<void> unmount(WidgetTester tester) async {
      await tester.pumpWidget(const SizedBox());
      for (var i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
    }

    testWidgets('mounts Linux flavor with Canonical Yaru home shell', (
      tester,
    ) async {
      final config = FlavorConfig(
        flavor: AppFlavor.linux,
        appTitle: 'Clockwork Linux',
      );

      await tester.pumpWidget(
        ClockworkApp(dependencies: deps, flavorConfig: config),
      );
      for (var i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      expect(find.byType(LinuxHomeShell), findsOneWidget);
      await unmount(tester);
    });

    testWidgets(
      'mounts Android flavor with Material 3 Expressive foldable shell',
      (tester) async {
        final config = FlavorConfig(
          flavor: AppFlavor.android,
          appTitle: 'Clockwork Android',
        );

        await tester.pumpWidget(
          ClockworkApp(dependencies: deps, flavorConfig: config),
        );
        for (var i = 0; i < 5; i++) {
          await tester.pump(const Duration(milliseconds: 100));
        }

        expect(find.byType(AndroidFoldableHomeShell), findsOneWidget);
        await unmount(tester);
      },
    );

    testWidgets('mounts Apple flavor with Cupertino shell', (tester) async {
      final config = FlavorConfig(
        flavor: AppFlavor.apple,
        appTitle: 'Clockwork Apple',
      );

      await tester.pumpWidget(
        ClockworkApp(dependencies: deps, flavorConfig: config),
      );
      for (var i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      expect(find.byType(AppleHomeShell), findsOneWidget);
      expect(find.byType(CupertinoPageScaffold), findsWidgets);
      await unmount(tester);
    });

    testWidgets('mounts Windows flavor with Fluent UI shell', (tester) async {
      final config = FlavorConfig(
        flavor: AppFlavor.windows,
        appTitle: 'Clockwork Windows',
      );

      await tester.pumpWidget(
        ClockworkApp(dependencies: deps, flavorConfig: config),
      );
      for (var i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      expect(find.byType(WindowsHomeShell), findsOneWidget);
      await unmount(tester);
    });
  });
}
