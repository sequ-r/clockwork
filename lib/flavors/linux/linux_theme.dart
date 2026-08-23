import 'package:flutter/material.dart';
import 'package:yaru/yaru.dart';

/// Builder for Linux desktop Canonical Yaru theme.
class LinuxTheme {
  const LinuxTheme._();

  /// Canonical Yaru light theme.
  static ThemeData get lightTheme {
    final theme = yaruLight;
    return theme.copyWith(
      visualDensity: VisualDensity.adaptivePlatformDensity,
      appBarTheme: theme.appBarTheme.copyWith(
        elevation: 0,
        scrolledUnderElevation: 0.5,
        centerTitle: false,
      ),
    );
  }

  /// Canonical Yaru dark theme.
  static ThemeData get darkTheme {
    final theme = yaruDark;
    return theme.copyWith(
      visualDensity: VisualDensity.adaptivePlatformDensity,
      appBarTheme: theme.appBarTheme.copyWith(
        elevation: 0,
        scrolledUnderElevation: 0.5,
        centerTitle: false,
      ),
    );
  }
}
