import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';

import '../providers/providers.dart';

/// Resolves a bundled asset to an absolute path, as required by the
/// native tray APIs on desktop.
String resolvedAssetPath(String asset) {
  final exeDir = File(Platform.resolvedExecutable).parent.path;
  return p.join(exeDir, 'data', 'flutter_assets', asset);
}

final trayServiceProvider = Provider<TrayService>((ref) {
  final service = TrayService(ref);
  ref.onDispose(service.dispose);
  return service;
});

/// Manages the system tray icon and its quick-add action.
class TrayService with TrayListener {
  TrayService(this._ref);

  final Ref _ref;
  bool _initialized = false;

  /// Whether the tray is available on this platform and outside tests.
  static bool get isSupported =>
      (Platform.isLinux || Platform.isMacOS || Platform.isWindows) &&
      !Platform.environment.containsKey('FLUTTER_TEST');

  Future<void> init() async {
    if (!isSupported || _initialized) return;
    _initialized = true;
    try {
      await trayManager.setIcon(
        resolvedAssetPath('assets/images/tray_icon.png'),
      );
    } catch (error) {
      return;
    }
    await _configurePlatformExtras();
    await _rebuildMenu();
    trayManager.addListener(this);
  }

  void dispose() {
    if (_initialized) trayManager.removeListener(this);
  }

  /// Applies platform-specific tray properties.
  ///
  /// The Linux implementation only supports a title, while Windows and
  /// macOS also support tooltips. Failures are ignored so that the menu
  /// is always installed.
  Future<void> _configurePlatformExtras() async {
    try {
      if (Platform.isLinux) {
        await trayManager.setTitle('Clockwork');
      } else {
        await trayManager.setToolTip('Clockwork');
      }
    } catch (_) {
      // Not critical: the menu still works without a tooltip/title.
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
    notifier.state++;
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
