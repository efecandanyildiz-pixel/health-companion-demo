import '../models/daily_metrics.dart';
import 'formatters.dart';
import 'patterns.dart';
import 'personal_range.dart';
import 'stats.dart';

/// An answer from the coach, with the numbers behind it.
///
/// For now these are written by fixed rules. When the Claude connection is
/// built, Claude will receive the same numbers and write the text; the
/// "numbers used" list stays the same, so every answer stays checkable.
class CoachAnswer {
  const CoachAnswer({
    required this.title,
    required this.text,
    required this.numbersUsed,
    this.chartNights = const [],
  });

  /// A short heading for the insight card, for example "Your sleep this week".
  final String title;

  final String text;

  /// Label and value pairs shown under the answer.
  final List<(String, String)> numbersUsed;

  /// Nights to show in the small chart, oldest first. May be empty.
  final List<DailyMetrics> chartNights;
}

abstract final class CoachQuestions {
  static const sleepWeek = 'Why did I sleep badly this week?';
  static const recovery = 'How was my recovery this week?';
  static const lastWeek = 'Compare with last week';

  static const all = [sleepWeek, recovery, lastWeek];
}

/// [days] newest first.
CoachAnswer answerCoachQuestion(String question, List<DailyMetrics> days) {
  return switch (question) {
    CoachQuestions.recovery => _recovery(days),
    CoachQuestions.lastWeek => _comparedWithLastWeek(days),
    _ => _sleepThisWeek(days),
  };
}

const _notEnoughData = CoachAnswer(
  title: 'Not enough data yet',
  text: 'There is not enough data yet. Wear your Fitbit Air for a week, '
      'then ask again.',
  numbersUsed: [],
);

CoachAnswer _sleepThisWeek(List<DailyMetrics> days) {
  final week = days.take(7).toList();
  final sleep = presentValues(week.map((d) => d.sleepMinutes));
  final usualRange =
      PersonalRange.tryFrom(days.skip(1).map((d) => d.sleepMinutes));
  if (sleep.isEmpty || usualRange == null) return _notEnoughData;

  final average = mean(sleep).round();
  final usual = usualRange.median.round();
  final lateNights = week.where(isLateNight).toList();
  final lateSleep = presentValues(lateNights.map((d) => d.sleepMinutes));
  final shortBy = usual - average;

  final sleptLess = shortBy >= 10;
  final text = StringBuffer(
    sleptLess
        ? 'You averaged ${formatHm(average)}, which is ${formatHm(shortBy)} '
            'below your usual ${formatHm(usual)}.'
        : 'You averaged ${formatHm(average)}, close to your usual '
            '${formatHm(usual)}, so this week was not unusually short.',
  );
  if (lateNights.isNotEmpty) {
    text.write(
      sleptLess
          ? ' The biggest difference: you went to bed after 00:45 on '
              '${lateNights.length} of ${week.length} nights.'
          : ' You went to bed after 00:45 on ${lateNights.length} of '
              '${week.length} nights.',
    );
  }

  return CoachAnswer(
    title: 'Your sleep this week',
    text: text.toString(),
    numbersUsed: [
      ('Average sleep, ${week.length} nights', formatHm(average)),
      ('Your usual (28 days)', formatHm(usual)),
      ('Nights in bed after 00:45', '${lateNights.length} of ${week.length}'),
      if (lateSleep.isNotEmpty)
        ('Sleep on those nights', formatHm(mean(lateSleep).round())),
    ],
    chartNights: week.reversed.toList(),
  );
}

CoachAnswer _recovery(List<DailyMetrics> days) {
  final week = days.take(7).toList();
  final history = days.skip(1);
  final rates = presentValues(week.map((d) => d.restingHeartRate));
  final hrv = presentValues(week.map((d) => d.heartRateVariability));
  final usualRate =
      PersonalRange.tryFrom(history.map((d) => d.restingHeartRate));
  final usualHrv =
      PersonalRange.tryFrom(history.map((d) => d.heartRateVariability));
  if (rates.isEmpty || hrv.isEmpty || usualRate == null || usualHrv == null) {
    return _notEnoughData;
  }

  final rate = mean(rates).round();
  final usual = usualRate.median.round();
  final difference = rate - usual;
  final comparison = difference == 0
      ? 'the same as'
      : '${difference.abs()} bpm ${difference > 0 ? 'above' : 'below'}';
  final averageHrv = mean(hrv).round();

  final text = StringBuffer(
    'Your resting heart rate averaged $rate bpm this week, $comparison '
    'your usual $usual. HRV averaged $averageHrv ms, against your usual '
    '${usualHrv.median.round()} ms.',
  );
  if (difference.abs() <= 2) {
    text.write(' Small changes like this are normal from week to week.');
  }

  return CoachAnswer(
    title: 'Your recovery this week',
    text: text.toString(),
    numbersUsed: [
      ('Resting HR, 7 nights', '$rate bpm'),
      ('Your usual resting HR', '$usual bpm'),
      ('HRV, 7 nights', '$averageHrv ms'),
      ('Your usual HRV', '${usualHrv.median.round()} ms'),
    ],
  );
}

CoachAnswer _comparedWithLastWeek(List<DailyMetrics> days) {
  final thisWeek = presentValues(days.take(7).map((d) => d.sleepMinutes));
  final lastWeek =
      presentValues(days.skip(7).take(7).map((d) => d.sleepMinutes));
  // Full days only, so today's unfinished steps don't count.
  final stepsThisWeek = presentValues(days.skip(1).take(7).map((d) => d.steps));
  final stepsLastWeek = presentValues(days.skip(8).take(7).map((d) => d.steps));
  if (thisWeek.isEmpty ||
      lastWeek.isEmpty ||
      stepsThisWeek.isEmpty ||
      stepsLastWeek.isEmpty) {
    return _notEnoughData;
  }

  final sleepNow = mean(thisWeek).round();
  final sleepBefore = mean(lastWeek).round();
  final difference = sleepNow - sleepBefore;
  final sleepChange = difference.abs() < 5
      ? 'about the same as last week'
      : '${formatHm(difference)} ${difference > 0 ? 'more' : 'less'} '
          'than last week';
  final stepsNow = mean(stepsThisWeek).round();
  final stepsBefore = mean(stepsLastWeek).round();

  return CoachAnswer(
    title: 'This week vs last week',
    text: 'This week you slept ${formatHm(sleepNow)} a night, $sleepChange '
        '(${formatHm(sleepBefore)}). You averaged '
        '${formatThousands(stepsNow)} steps a day, compared with '
        '${formatThousands(stepsBefore)}.',
    numbersUsed: [
      ('Sleep, this week', formatHm(sleepNow)),
      ('Sleep, last week', formatHm(sleepBefore)),
      ('Steps a day, this week', formatThousands(stepsNow)),
      ('Steps a day, last week', formatThousands(stepsBefore)),
    ],
  );
}
