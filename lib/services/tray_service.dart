import 'dart:async';
import 'dart:developer' as developer;
import 'dart:io';
import 'dart:ui' show Size;

import 'package:clockwork/core/view_models/app_view_model.dart';
import 'package:clockwork/database/database.dart';
import 'package:path/path.dart' as p;
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';

/// Resolves a bundled asset to an absolute path, as required by the
/// native tray APIs on desktop.
String resolvedAssetPath(String asset) {
  final exeDir = File(Platform.resolvedExecutable).parent.path;
  return p.join(exeDir, 'data', 'flutter_assets', asset);
}

/// Manages the system tray icon and its quick-add action.
class TrayService with TrayListener {
  /// Creates the service with [appViewModel] and [database].
  TrayService({required this.appViewModel, required this.database});

  /// Application view model reference.
  final AppViewModel appViewModel;

  /// Database reference.
  final ClockworkDatabase database;
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
        MenuItem(key: 'manage-projects', label: 'Manage projects...'),
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
        unawaited(openQuickAddPopup());
      case 'manage-projects':
        unawaited(openManageProjectsPopup());
      case 'show':
        unawaited(showMainWindow());
      case 'quit':
        unawaited(_quit());
    }
  }

  @override
  void onTrayIconMouseDown() {
    unawaited(openQuickAddPopup());
  }

  /// Opens the quick add standalone popup window.
  Future<void> openQuickAddPopup() async {
    appViewModel.setActiveTrayPopup(TrayPopupMode.quickAdd);
    await _showPopupWindow(const Size(420, 240));
  }

  /// Opens the manage projects standalone popup window.
  Future<void> openManageProjectsPopup() async {
    appViewModel.setActiveTrayPopup(TrayPopupMode.manageProjects);
    await _showPopupWindow(const Size(480, 500));
  }

  /// Restores and focuses the main application window.
  Future<void> showMainWindow() async {
    appViewModel.setActiveTrayPopup(TrayPopupMode.none);
    if (!isSupported) return;
    await windowManager.setAlwaysOnTop(false);
    await windowManager.setSize(const Size(800, 560));
    await windowManager.center();
    await windowManager.show();
    await windowManager.focus();
  }

  /// Closes any active tray popup window and hides back to the tray.
  Future<void> closeTrayPopup() async {
    appViewModel.setActiveTrayPopup(TrayPopupMode.none);
    if (!isSupported) return;
    await windowManager.setAlwaysOnTop(false);
    await windowManager.hide();
  }

  Future<void> _showPopupWindow(Size size) async {
    if (!isSupported) return;
    await windowManager.setAlwaysOnTop(true);
    await windowManager.setSize(size);
    await windowManager.center();
    await windowManager.show();
    await windowManager.focus();
  }

  Future<void> _quit() async {
    await database.close();
    exit(0);
  }
}
