/// Where today's value sits compared with the user's own normal range.
enum RangeStatus { below, within, above }

/// The user's normal range for one metric, learned from their own history.
///
/// Instead of a score like "69 Fair", we show whether today is inside the
/// range the user usually has. The range covers the middle 70% of past days
/// (15th to 85th percentile), so one unusual day does not stretch it.
class PersonalRange {
  const PersonalRange({
    required this.low,
    required this.high,
    required this.median,
    required this.min,
    required this.max,
  });

  /// Builds a range from past values. Missing values are skipped.
  ///
  /// Returns null when there are fewer than [minimumDays] values, because a
  /// "normal" learned from a few days would not mean much.
  static PersonalRange? tryFrom(
    Iterable<num?> values, {
    int minimumDays = 7,
  }) {
    final sorted = values.whereType<num>().map((v) => v.toDouble()).toList()
      ..sort();
    if (sorted.length < minimumDays) return null;

    return PersonalRange(
      low: percentile(sorted, 0.15),
      high: percentile(sorted, 0.85),
      median: percentile(sorted, 0.5),
      min: sorted.first,
      max: sorted.last,
    );
  }

  /// Value below which [fraction] of the sorted values fall.
  static double percentile(List<double> sorted, double fraction) {
    final position = (sorted.length - 1) * fraction;
    final lower = position.floor();
    final upper = position.ceil();
    final weight = position - lower;
    return sorted[lower] + (sorted[upper] - sorted[lower]) * weight;
  }

  final double low;
  final double high;
  final double median;
  final double min;
  final double max;

  RangeStatus statusOf(num value) {
    if (value < low) return RangeStatus.below;
    if (value > high) return RangeStatus.above;
    return RangeStatus.within;
  }
}

/// One metric for one day, together with the user's normal range.
class MetricSignal {
  const MetricSignal({this.value, this.range});

  factory MetricSignal.of(num? value, Iterable<num?> history) =>
      MetricSignal(value: value, range: PersonalRange.tryFrom(history));

  final num? value;
  final PersonalRange? range;

  RangeStatus? get status {
    final current = value;
    final normal = range;
    if (current == null || normal == null) return null;
    return normal.statusOf(current);
  }
}
