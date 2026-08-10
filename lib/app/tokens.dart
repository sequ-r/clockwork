/// Pure design tokens that are safe to import from non-Flutter contexts
/// (CLI, scripts, tests).
///
/// Anything that depends on `package:flutter/*` lives in `theme.dart`.
/// Anything here is portable.
library;

/// Primary brand color used as the seed for the Material 3 color scheme.
const int kSeedColorArgb = 0xFF3E6B8C;

/// libadwaita uses an 8-pixel grid with rounded corners. We mirror that
/// here so widgets feel at home on GNOME.
const double kRadiusSmall = 6;
const double kRadiusMedium = 12;
const double kRadiusLarge = 16;

/// Standard vertical/horizontal spacing scale.
const double kSpacingXs = 4;
const double kSpacingSm = 8;
const double kSpacingMd = 12;
const double kSpacingLg = 16;
const double kSpacingXl = 24;

/// Color seed used to pick a color for newly auto-created tags. Kept in a
/// single place so the GUI, CLI and tests agree.
const List<int> kAutoTagColors = [
  0xFF64B5F6,
  0xFF81C784,
  0xFFFFB74D,
  0xFFBA68C8,
  0xFF4DD0E1,
  0xFFE57373,
  0xFFFFD54F,
  0xFF90A4AE,
];
