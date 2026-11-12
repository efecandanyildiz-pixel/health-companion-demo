import 'package:flutter/material.dart';

import '../logic/patterns.dart';
import '../logic/scores.dart';
import '../models/daily_metrics.dart';

/// The colors of one area: sleep, heart or activity.
@immutable
class CategoryColors {
  const CategoryColors({
    required this.label,
    required this.gradient,
    required this.soft,
    required this.onSoft,
    required this.flat,
    required this.stripe,
  });

  /// Text and icon color for the area's name.
  final Color label;

  /// Highlighted values: today, the current hour, the arc.
  final List<Color> gradient;

  /// Chip background, and the text on it.
  final Color soft;
  final Color onSoft;

  /// Past values that should stay quiet.
  final Color flat;

  /// Second color for striped bars (late nights).
  final Color stripe;

  LinearGradient get horizontal => LinearGradient(colors: gradient);

  LinearGradient get vertical => LinearGradient(
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
        colors: gradient,
      );
}

/// All app colors for one mode. Read it with `context.palette`.
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.isDark,
    required this.background,
    required this.frame,
    required this.surface,
    required this.surfaceRaised,
    required this.surfaceAccent,
    required this.border,
    required this.track,
    required this.ink,
    required this.muted,
    required this.faint,
    required this.navBackground,
    required this.navSelected,
    required this.usualMark,
    required this.danger,
    required this.dangerFill,
    required this.sleep,
    required this.heart,
    required this.activity,
    required this.brand,
    required this.experiment,
    required this.deepSleep,
    required this.lightSleep,
    required this.remSleep,
    required this.awake,
    required this.recoveryHigh,
    required this.recoveryMid,
    required this.recoveryLow,
    required this.effort,
  });

  final bool isDark;
  final Color background;

  /// Around the app when the window is wider than a phone.
  final Color frame;
  final Color surface;
  final Color surfaceRaised;
  final Color surfaceAccent;
  final Color border;
  final Color track;
  final Color ink;
  final Color muted;
  final Color faint;
  final Color navBackground;
  final Color navSelected;

  /// The "usual" notch and dashed lines.
  final Color usualMark;
  final Color danger;
  final Color dangerFill;

  final CategoryColors sleep;
  final CategoryColors heart;
  final CategoryColors activity;

  final List<Color> brand;
  final List<Color> experiment;

  final Color deepSleep;
  final Color lightSleep;
  final Color remSleep;
  final Color awake;

  /// Score colours: high is green-teal, middle is amber, low is coral.
  final Color recoveryHigh;
  final Color recoveryMid;
  final Color recoveryLow;

  /// The Effort ring.
  final List<Color> effort;

  Color scoreColor(ScoreLevel level) => switch (level) {
        ScoreLevel.high => recoveryHigh,
        ScoreLevel.mid => recoveryMid,
        ScoreLevel.low => recoveryLow,
      };

  CategoryColors category(PatternCategory category) => switch (category) {
        PatternCategory.sleep => sleep,
        PatternCategory.heart => heart,
        PatternCategory.activity => activity,
      };

  Color stage(SleepStage stage) => switch (stage) {
        SleepStage.deep => deepSleep,
        SleepStage.light => lightSleep,
        SleepStage.rem => remSleep,
        SleepStage.awake => awake,
      };

  static const dark = AppPalette(
    isDark: true,
    background: Color(0xFF07090F),
    frame: Color(0xFF030408),
    surface: Color(0xFF10141D),
    surfaceRaised: Color(0xFF141925),
    surfaceAccent: Color(0xFF1A2030),
    border: Color(0x12FFFFFF),
    track: Color(0x17FFFFFF),
    ink: Color(0xFFF5F7FA),
    muted: Color(0xFF8D96A8),
    faint: Color(0xFF7C8598),
    navBackground: Color(0xFF0B0E15),
    navSelected: Color(0x1AFFFFFF),
    usualMark: Color(0xFFFFFFFF),
    danger: Color(0xFFFF6B6B),
    dangerFill: Color(0xFFE5484D),
    sleep: CategoryColors(
      label: Color(0xFF9DA8FF),
      gradient: [Color(0xFF4F6BFF), Color(0xFFA06BFF)],
      soft: Color(0x2E6E7BFF),
      onSoft: Color(0xFFB9C1FF),
      flat: Color(0xFF3E4691),
      stripe: Color(0xFF232650),
    ),
    heart: CategoryColors(
      label: Color(0xFFFF7A93),
      gradient: [Color(0xFFFF8A3D), Color(0xFFFF3DA8)],
      soft: Color(0x29FF6371),
      onSoft: Color(0xFFFFA0AE),
      flat: Color(0xFF5A2A3A),
      stripe: Color(0xFF3A1C26),
    ),
    activity: CategoryColors(
      label: Color(0xFF8CF56B),
      gradient: [Color(0xFF3BD16F), Color(0xFFA6F45A)],
      soft: Color(0x2478F05A),
      onSoft: Color(0xFFA9F78F),
      flat: Color(0xFF2D4A2C),
      stripe: Color(0xFF1C2E1B),
    ),
    brand: [Color(0xFF6E7BFF), Color(0xFFC845FF)],
    experiment: [Color(0xFFC845FF), Color(0xFF8B5CF6), Color(0xFF5B6CFF)],
    deepSleep: Color(0xFF3B2FD9),
    lightSleep: Color(0xFF7C83FF),
    remSleep: Color(0xFF4FD1FF),
    awake: Color(0xFFFF8A3D),
    recoveryHigh: Color(0xFF2EE6A6),
    recoveryMid: Color(0xFFFFC145),
    recoveryLow: Color(0xFFFF6B5E),
    effort: [Color(0xFF2F80FF), Color(0xFF38C6F4)],
  );

  static const light = AppPalette(
    isDark: false,
    background: Color(0xFFF6F6F8),
    frame: Color(0xFFE4E2EA),
    surface: Color(0xFFFFFFFF),
    surfaceRaised: Color(0xFFFFFFFF),
    surfaceAccent: Color(0xFFEEEDFB),
    border: Color(0xFFECEBF1),
    track: Color(0xFFECEAF2),
    ink: Color(0xFF15121C),
    muted: Color(0xFF5F5A6E),
    faint: Color(0xFF6E6880),
    navBackground: Color(0xFFFFFFFF),
    navSelected: Color(0xFFECEAF2),
    usualMark: Color(0xFF15121C),
    danger: Color(0xFFC62828),
    dangerFill: Color(0xFFE5484D),
    sleep: CategoryColors(
      label: Color(0xFF3E4FE0),
      gradient: [Color(0xFF3F55F0), Color(0xFF8A4DF0)],
      soft: Color(0xFFE7E9FD),
      onSoft: Color(0xFF2F3BB8),
      flat: Color(0xFFCDD2F8),
      stripe: Color(0xFFEDEFFD),
    ),
    heart: CategoryColors(
      label: Color(0xFFC93A5E),
      gradient: [Color(0xFFF26A1B), Color(0xFFE0338C)],
      soft: Color(0xFFFCE6EA),
      onSoft: Color(0xFFA3284B),
      flat: Color(0xFFF6D3DC),
      stripe: Color(0xFFFBEAEE),
    ),
    activity: CategoryColors(
      label: Color(0xFF1C8A3E),
      gradient: [Color(0xFF1FA84F), Color(0xFF6DC93A)],
      soft: Color(0xFFE1F5E0),
      onSoft: Color(0xFF1A6E33),
      flat: Color(0xFFCDEBC6),
      stripe: Color(0xFFE8F6E5),
    ),
    brand: [Color(0xFF4F5BF0), Color(0xFFA43BE8)],
    experiment: [Color(0xFFA43BE8), Color(0xFF7448E6), Color(0xFF4F5BF0)],
    deepSleep: Color(0xFF2F25B8),
    lightSleep: Color(0xFF8E95FF),
    remSleep: Color(0xFF2BA8E0),
    awake: Color(0xFFF08A3D),
    recoveryHigh: Color(0xFF0E9F74),
    recoveryMid: Color(0xFFC98A00),
    recoveryLow: Color(0xFFD9443A),
    effort: [Color(0xFF1F6FE0), Color(0xFF1AA6D9)],
  );

  @override
  AppPalette copyWith() => this;

  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) =>
      other is AppPalette && t >= 0.5 ? other : this;
}

extension AppPaletteContext on BuildContext {
  AppPalette get palette =>
      Theme.of(this).extension<AppPalette>() ?? AppPalette.dark;
}
