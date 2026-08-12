import 'dart:async';
import 'dart:developer' as developer;
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';

import '../core/providers/database.dart';
import '../core/providers/ui_state.dart';

/// Resolves a bundled asset to an absolute path, as required by the
/// native tray APIs on desktop.
String resolvedAssetPath(String asset) {
  final exeDir = File(Platform.resolvedExecutable).parent.path;
  return p.join(exeDir, 'data', 'flutter_assets', asset);
}

/// Singleton tray service. Created once by the framework.
final trayServiceProvider = Provider<TrayService>((ref) {
  final service = TrayService(ref);
  ref.onDispose(service.dispose);
  return service;
});

/// Manages the system tray icon and its quick-add action.
class TrayService with TrayListener {
  /// Creates the service. Use [trayServiceProvider] to obtain an instance.
  TrayService(this._ref);

  final Ref _ref;
  bool _initialized = false;

  /// Whether the tray is available on this platform and outside tests.
  static bool get isSupported =>
      (Platform.isLinux || Platform.isMacOS || Platform.isWindows) &&
      !Platform.environment.containsKey('FLUTTER_TEST');

  /// Initializes the tray icon and menu.
  ///
  /// Safe to call repeatedly: a successful init flips an internal guard
  /// and subsequent calls become no-ops. On failure the exception is
  /// logged via `dart:developer` and rethrown so the caller can decide
  /// whether to abort, leaving the guard unset so retries are possible.
  Future<void> init() async {
    if (!isSupported || _initialized) return;
    try {
      await trayManager.setIcon(
        resolvedAssetPath('assets/images/tray_icon.png'),
      );
      await _configurePlatformExtras();
      await _rebuildMenu();
      trayManager.addListener(this);
      _initialized = true;
    } catch (error, stack) {
      developer.log(
        'tray init failed',
        name: 'tray',
        level: 1000,
        error: error,
        stackTrace: stack,
      );
      rethrow;
    }
  }

  /// Removes the tray listener. Safe to call even if [init] never ran.
  void dispose() {
    if (_initialized) trayManager.removeListener(this);
  }

  /// Applies platform-specific tray properties.
  ///
  /// The Linux implementation only supports a title, while Windows and
  /// macOS also support tooltips. Failures are logged but do not abort
  /// init, because the menu and icon are the critical surfaces.
  Future<void> _configurePlatformExtras() async {
    try {
      if (Platform.isLinux) {
        await trayManager.setTitle('Clockwork');
      } else {
        await trayManager.setToolTip('Clockwork');
      }
    } catch (error, stack) {
      developer.log(
        'tray platform extras failed',
        name: 'tray',
        level: 900,
        error: error,
        stackTrace: stack,
      );
    }
  }

  Future<void> _rebuildMenu() async {
    final menu = Menu(
      items: [
        MenuItem(key: 'quick-add', label: 'Add time...'),
        MenuItem.separator(),
        MenuItem(key: 'show', label: 'Show Clockwork'),
        MenuItem(key: 'quit', label: 'Quit'),
      ],
    );
    await trayManager.setContextMenu(menu);
  }

  @override
  void onTrayMenuItemClick(MenuItem menuItem) {
    switch (menuItem.key) {
      case 'quick-add':
        unawaited(_openQuickAdd());
      case 'show':
        unawaited(_showMainWindow());
      case 'quit':
        unawaited(_quit());
    }
  }

  @override
  void onTrayIconMouseDown() {
    unawaited(_openQuickAdd());
  }

  /// Shows the main window with the minimal quick-add dialog on top.
  Future<void> _openQuickAdd() async {
    await _showMainWindow();
    final notifier = _ref.read(quickAddRequestProvider.notifier);
    notifier.request();
  }

  Future<void> _showMainWindow() async {
    await windowManager.show();
    await windowManager.focus();
  }

  Future<void> _quit() async {
    await _ref.read(databaseProvider).close();
    exit(0);
  }
}
