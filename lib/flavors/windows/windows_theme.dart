import 'package:clockwork/app/tokens.dart';
import 'package:fluent_ui/fluent_ui.dart';

/// Builder for Windows Fluent Design System themes.
class WindowsTheme {
  const WindowsTheme._();

  /// Light Fluent theme.
  static FluentThemeData get lightTheme {
    return FluentThemeData(
      brightness: Brightness.light,
      accentColor: AccentColor('normal', const {
        'darkest': Color(0xff122b10),
        'darker': Color(0xff1c451a),
        'dark': Color(0xff296525),
        'normal': Color(kSeedColorArgb),
        'light': Color(0xff4a9744),
        'lighter': Color(0xff67b661),
        'lightest': Color(0xff88d382),
      }),
      visualDensity: VisualDensity.adaptivePlatformDensity,
    );
  }

  /// Dark Fluent theme.
  static FluentThemeData get darkTheme {
    return FluentThemeData(
      brightness: Brightness.dark,
      accentColor: AccentColor('normal', const {
        'darkest': Color(0xff122b10),
        'darker': Color(0xff1c451a),
        'dark': Color(0xff296525),
        'normal': Color(kSeedColorArgb),
        'light': Color(0xff4a9744),
        'lighter': Color(0xff67b661),
        'lightest': Color(0xff88d382),
      }),
      visualDensity: VisualDensity.adaptivePlatformDensity,
    );
  }
}
