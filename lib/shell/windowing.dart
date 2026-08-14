/// Desktop window and tray lifecycle.
///
/// On desktop (Linux/macOS/Windows), we want closing the window to hide to
/// the tray rather than quit. This helper centralizes that logic so neither
/// `main.dart` nor `HomeShell` has to know about it.
///
/// On Linux, when running under a GTK4/libadwaita shell, [requestHeaderBar]
/// asks the native side (added in Phase 4 of the rewrite plan) to install
/// an Adwaita-style headerbar. The call is a no-op on platforms that
/// don't have the native plugin.
library;

import 'dart:developer' as developer;

import 'package:clockwork/services/tray_service.dart';
import 'package:flutter/services.dart';
import 'package:window_manager/window_manager.dart';

/// MethodChannel for the optional libadwaita headerbar native plugin.
///
/// The plugin itself isn't included in this sandbox build; it would be a
/// tiny C/Vala shim around `AdwApplicationWindow` registered in
/// `linux/runner/`. Until that lands, every method on this channel is
/// gracefully absorbed.
const _headerBarChannel = MethodChannel('dev.sequ.clockwork/headerbar');

/// Initialize desktop windowing. Must be awaited before `runApp`.
Future<void> initializeWindowing() async {
  if (!_isDesktopTraySupported) return;
  await windowManager.ensureInitialized();
  // Hide instead of quit when the user clicks the close button. The actual
  // listener that re-shows the window lives in `HomeShell`.
  await windowManager.setPreventClose(true);
  await requestHeaderBar();
}

/// Asks the native side to install a libadwaita-style headerbar.
///
/// Intentionally inert in the current build: the native plugin
/// (`linux/runner/`) does not register this channel, so every call
/// raises `MissingPluginException`. The handler exists so that when
/// the plugin is later registered no Dart changes are required.
Future<void> requestHeaderBar() async {
  try {
    await _headerBarChannel.invokeMethod<void>('install');
  } on MissingPluginException {
    // Plugin not registered: no-op.
  } on PlatformException catch (error, stack) {
    developer.log(
      'headerbar install failed',
      name: 'windowing',
      level: 900,
      error: error,
      stackTrace: stack,
    );
  }
}

bool get _isDesktopTraySupported => TrayService.isSupported;
