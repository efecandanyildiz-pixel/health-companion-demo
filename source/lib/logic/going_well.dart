import 'dart:math' as math;

import 'personal_range.dart';
import 'today_summary.dart';

/// A positive note with one part in bold, for example
/// "You wore your Fitbit Air **every night this week**, so ...".
class Highlight {
  const Highlight(this.before, this.bold, [this.after = '']);

  final String before;
  final String bold;
  final String after;

  String get plain => '$before$bold$after';
}

/// Finds up to two things that are going well, so the screen does not
/// only ever talk about what is lower than usual.
List<Highlight> findGoingWell(TodaySummary summary) {
  final wins = <Highlight>[];

  final yesterdayActive = summary.activeZoneMinutes.value?.toInt();
  final lastWeek = summary.recentActiveMinutes.whereType<int>().toList();
  if (yesterdayActive != null &&
      yesterdayActive > 0 &&
      lastWeek.isNotEmpty &&
      yesterdayActive >= lastWeek.reduce(math.max)) {
    wins.add(
      Highlight(
        'Yesterday was your most active day this week: ',
        '$yesterdayActive active minutes',
        '.',
      ),
    );
  }

  final trackedNights =
      summary.lastNights.where((night) => night.sleepMinutes != null).length;
  if (summary.lastNights.length == 7 && trackedNights == 7) {
    wins.add(
      const Highlight(
        'You wore your Fitbit Air ',
        'every night this week',
        ', so your numbers are complete.',
      ),
    );
  }

  if (summary.stepsSoFar.status == RangeStatus.above) {
    wins.add(
      const Highlight("You're ", 'ahead of your usual step pace', ' today.'),
    );
  }

  final sleepStatus = summary.sleep.status;
  if (sleepStatus == RangeStatus.within || sleepStatus == RangeStatus.above) {
    wins.add(
      const Highlight('Last night your sleep was ', 'within your usual range', '.'),
    );
  }

  return wins.take(2).toList();
}
