import 'package:flutter/material.dart';

import 'app_font.dart';
import 'palette.dart';

ThemeData buildAppTheme(AppPalette palette) {
  final brightness = palette.isDark ? Brightness.dark : Brightness.light;
  final base = ThemeData(
    brightness: brightness,
    colorScheme: ColorScheme.fromSeed(
      seedColor: palette.sleep.gradient.first,
      brightness: brightness,
      surface: palette.surface,
    ),
    scaffoldBackgroundColor: palette.background,
    extensions: [palette],
  );
  return base.copyWith(
    textTheme: AppFont.textTheme(base.textTheme),
    dialogTheme: DialogThemeData(
      backgroundColor: palette.surfaceRaised,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: palette.ink,
      contentTextStyle: AppFont.style(size: 14, color: palette.background),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
  );
}
