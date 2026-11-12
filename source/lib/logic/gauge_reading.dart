import 'formatters.dart';
import 'personal_range.dart';

/// Where a half-circle gauge is filled to and where its "usual" notch sits.
///
/// The notch is always at the same place (three quarters along), so the
/// arc reads as "compared with usual", not as a goal to fill.
class GaugeReading {
  const GaugeReading({
    required this.value,
    required this.usual,
    required this.range,
  });

  /// Returns null when there is no value yet, or no usual to compare with.
  static GaugeReading? from(MetricSignal signal) {
    final value = signal.value;
    final range = signal.range;
    if (value == null || range == null || range.median <= 0) return null;
    return GaugeReading(
      value: value.toDouble(),
      usual: range.median,
      range: range,
    );
  }

  /// Where the "usual" notch sits along the arc (0 = start, 1 = end).
  static const usualPosition = 0.75;

  final double value;

  /// Your usual value: the middle of your last 28 days.
  final double usual;
  final PersonalRange range;

  double get fraction => (value / usual * usualPosition).clamp(0.03, 1.0);

  double get difference => value - usual;

  RangeStatus get status => range.statusOf(value);
}

/// "48 min less", "12 min more" or "About usual".
String sleepDifferenceText(double minutes) {
  final rounded = minutes.round();
  if (rounded.abs() < 5) return 'About usual';
  return '${formatHm(rounded)} ${rounded < 0 ? 'less' : 'more'}';
}

/// "3 bpm higher", "2 bpm lower" or "About usual".
String heartRateDifferenceText(double bpm) {
  final rounded = bpm.round();
  if (rounded == 0) return 'About usual';
  return '${rounded.abs()} bpm ${rounded < 0 ? 'lower' : 'higher'}';
}

/// "310 more", "1,200 fewer" or "About usual".
String stepsDifferenceText(double steps) {
  final rounded = steps.round();
  if (rounded.abs() < 50) return 'About usual';
  return '${formatThousands(rounded.abs())} ${rounded < 0 ? 'fewer' : 'more'}';
}

/// "below your range", "within your range" or "above your range".
String rangeStatusText(RangeStatus status) => switch (status) {
      RangeStatus.below => 'below your range',
      RangeStatus.within => 'within your range',
      RangeStatus.above => 'above your range',
    };

/// For example "above your 56–59 range".
String rangeStatusWithBounds(RangeStatus status, PersonalRange range) {
  final word = switch (status) {
    RangeStatus.below => 'below',
    RangeStatus.within => 'within',
    RangeStatus.above => 'above',
  };
  return '$word your ${range.low.round()}–${range.high.round()} range';
}

/// How today's steps compare with your usual pace by this time.
String paceStatusText(RangeStatus status) => switch (status) {
      RangeStatus.below => 'behind your usual pace',
      RangeStatus.within => 'on your usual pace',
      RangeStatus.above => 'ahead of pace',
    };

/// Short note for a value measured once a day, such as HRV.
String dailyStatusText(RangeStatus status) => switch (status) {
      RangeStatus.below => 'lower today',
      RangeStatus.within => 'in your range',
      RangeStatus.above => 'higher today',
    };
