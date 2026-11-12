import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Text styles in Inter Tight.
///
/// Tests turn [useGoogleFonts] off, because they run without internet.
abstract final class AppFont {
  static bool useGoogleFonts = true;

  static TextStyle style({
    double? size,
    FontWeight weight = FontWeight.w400,
    Color? color,
    double? height,
    double? letterSpacing,
  }) {
    final base = TextStyle(
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    return useGoogleFonts ? GoogleFonts.interTight(textStyle: base) : base;
  }

  static TextTheme textTheme(TextTheme base) => useGoogleFonts
      ? base.apply(fontFamily: GoogleFonts.interTight().fontFamily)
      : base;
}
