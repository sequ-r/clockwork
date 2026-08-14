/// Adwaita-flavored theme used by the GUI.
///
/// We don't import libadwaita directly (Flutter's Material 3 renderer
/// can't read GTK tokens at runtime) — instead we mirror the libadwaita
/// design language in Dart via the tokens in `tokens.dart`.
///
/// On Linux, when running under a GTK4/libadwaita shell, the colors align
/// with `AdwStyleManager` defaults. On Android and other platforms, the
/// same tokens are used to produce Material 3 colors.
library;

import 'package:clockwork/app/tokens.dart';
import 'package:flutter/material.dart';

export 'package:clockwork/app/tokens.dart';

/// Light theme: Adwaita-styled Material 3 colors.
ThemeData buildLightTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: const Color(kSeedColorArgb),
    brightness: Brightness.light,
  );
  return _buildTheme(scheme);
}

/// Dark theme: Adwaita-styled Material 3 colors.
ThemeData buildDarkTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: const Color(kSeedColorArgb),
    brightness: Brightness.dark,
  );
  return _buildTheme(scheme);
}

ThemeData _buildTheme(ColorScheme scheme) {
  final base = ThemeData(
    colorScheme: scheme,
    useMaterial3: true,
    visualDensity: VisualDensity.adaptivePlatformDensity,
  );

  // Adwaita-style: subtle elevation, rounded corners everywhere, no
  // oversized shadows. We override component themes to apply our radii
  // consistently.
  return base.copyWith(
    cardTheme: CardThemeData(
      elevation: 0,
      margin: const EdgeInsets.all(kSpacingSm),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(kRadiusMedium),
      ),
      color: scheme.surfaceContainerLow,
    ),
    dialogTheme: DialogThemeData(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(kRadiusLarge),
      ),
      backgroundColor: scheme.surface,
    ),
    appBarTheme: AppBarTheme(
      elevation: 0,
      scrolledUnderElevation: 0.5,
      backgroundColor: scheme.surface,
      foregroundColor: scheme.onSurface,
      centerTitle: false,
      shape: const Border(
        bottom: BorderSide(color: Color(0x1F000000), width: 0.5),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(kRadiusSmall),
      ),
      isDense: true,
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: ButtonStyle(
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(kRadiusSmall),
          ),
        ),
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(kRadiusLarge),
      ),
    ),
    chipTheme: ChipThemeData(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(kRadiusSmall),
      ),
    ),
  );
}
