import '../models/daily_metrics.dart';
import 'formatters.dart';
import 'today_summary.dart';

/// A 7-night test of one change, for example "In bed by 00:30".
class BedtimeExperiment {
  const BedtimeExperiment({
    required this.targetAfterEvening,
    required this.lengthNights,
    required this.results,
  });

  /// The sample experiment, started [startedNightsAgo] nights ago.
  /// [days] newest first.
  factory BedtimeExperiment.sample(
    List<DailyMetrics> days, {
    int startedNightsAgo = 2,
    int targetAfterEvening = 6 * 60 + 30,
  }) {
    final nights = days.take(startedNightsAgo).toList().reversed;
    return BedtimeExperiment(
      targetAfterEvening: targetAfterEvening,
      lengthNights: 7,
      results: [
        for (final night in nights)
          night.bedtime != null &&
              minutesAfterEvening(night.bedtime!) <= targetAfterEvening,
      ],
    );
  }

  /// Target bedtime as minutes after 18:00 (00:30 = 390).
  final int targetAfterEvening;
  final int lengthNights;

  /// One entry per finished night, oldest first: true = made it.
  final List<bool> results;

  int get nightsDone => results.length;
  int get nightsMet => results.where((made) => made).length;
  int get tonight => nightsDone + 1;

  String get title =>
      'In bed by ${formatClock(targetAfterEvening + 18 * 60)} '
      'for $lengthNights nights';
}
