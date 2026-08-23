import 'package:flutter/foundation.dart';

/// Supported application flavors in Clockwork.
enum AppFlavor {
  /// Linux desktop flavor with Canonical Yaru design and system integration.
  linux,

  /// Android flavor with Material 3 Expressive UI and foldable responsiveness.
  android,

  /// Apple flavor (macOS / iOS) with Cupertino design and native styling.
  apple,

  /// Windows desktop flavor with Microsoft Fluent Design System.
  windows,
}

/// Global flavor configuration holding metadata and platform capabilities.
class FlavorConfig {
  /// Creates a flavor configuration.
  FlavorConfig({
    required this.flavor,
    required this.appTitle,
    this.applicationIdSuffix = '',
  });

  /// The active application flavor.
  final AppFlavor flavor;

  /// Display title of the application.
  final String appTitle;

  /// Application identifier suffix for native packaging.
  final String applicationIdSuffix;

  static FlavorConfig? _current;

  /// Current active flavor configuration.
  static FlavorConfig get current =>
      _current ??
      FlavorConfig(flavor: _detectPlatformFlavor(), appTitle: 'Clockwork');

  /// Sets the active flavor configuration.
  static set current(FlavorConfig config) {
    _current = config;
  }

  static AppFlavor _detectPlatformFlavor() {
    const flavorEnv = String.fromEnvironment('FLAVOR');
    if (flavorEnv.isNotEmpty) {
      switch (flavorEnv.toLowerCase()) {
        case 'linux':
          return AppFlavor.linux;
        case 'android':
          return AppFlavor.android;
        case 'apple':
        case 'macos':
        case 'ios':
        case 'cupertino':
          return AppFlavor.apple;
        case 'windows':
        case 'fluent':
          return AppFlavor.windows;
      }
    }

    if (kIsWeb) return AppFlavor.android;

    switch (defaultTargetPlatform) {
      case TargetPlatform.linux:
        return AppFlavor.linux;
      case TargetPlatform.android:
        return AppFlavor.android;
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        return AppFlavor.apple;
      case TargetPlatform.windows:
        return AppFlavor.windows;
      case TargetPlatform.fuchsia:
        return AppFlavor.android;
    }
  }

  /// Whether running under the Linux flavor.
  bool get isLinux => flavor == AppFlavor.linux;

  /// Whether running under the Android flavor.
  bool get isAndroid => flavor == AppFlavor.android;

  /// Whether running under the Apple (macOS/iOS) flavor.
  bool get isApple => flavor == AppFlavor.apple;

  /// Whether running under the Windows flavor.
  bool get isWindows => flavor == AppFlavor.windows;

  /// Whether running on a desktop-oriented platform flavor.
  bool get isDesktop => isLinux || isWindows || flavor == AppFlavor.apple;

  /// Whether system tray popups are supported by this flavor.
  bool get supportsSystemTray =>
      !kIsWeb &&
      (flavor == AppFlavor.linux ||
          flavor == AppFlavor.windows ||
          flavor == AppFlavor.apple);

  /// Whether foldable multi-pane features should be active.
  bool get supportsFoldables => flavor == AppFlavor.android;
}
