import 'package:clockwork/app/tokens.dart';
import 'package:flutter/cupertino.dart';

/// Builder for Apple (macOS / iOS) Cupertino theme.
class AppleTheme {
  const AppleTheme._();

  /// Light Cupertino theme.
  static CupertinoThemeData get lightTheme {
    return const CupertinoThemeData(
      brightness: Brightness.light,
      primaryColor: Color(kSeedColorArgb),
      primaryContrastingColor: CupertinoColors.white,
      scaffoldBackgroundColor: CupertinoColors.systemGroupedBackground,
      barBackgroundColor: CupertinoColors.systemBackground,
    );
  }

  /// Dark Cupertino theme.
  static CupertinoThemeData get darkTheme {
    return const CupertinoThemeData(
      brightness: Brightness.dark,
      primaryColor: Color(kSeedColorArgb),
      primaryContrastingColor: CupertinoColors.white,
      scaffoldBackgroundColor: CupertinoColors.black,
      barBackgroundColor: CupertinoColors.darkBackgroundGray,
    );
  }
}
