import 'package:flutter/material.dart';

import '../app_state.dart';
import '../logic/formatters.dart';
import '../logic/gauge_reading.dart';
import '../logic/going_well.dart';
import '../logic/patterns.dart';
import '../logic/personal_range.dart';
import '../logic/scores.dart';
import '../logic/today_summary.dart';
import '../ui/app_font.dart';
import '../ui/charts.dart';
import '../ui/components.dart';
import '../ui/palette.dart';

/// The morning summary: today against your usual, in one glance.
class TodayScreen extends StatelessWidget {
  const TodayScreen({
    super.key,
    required this.onOpenSleep,
    required this.onOpenPatterns,
    required this.onOpenYou,
  });

  final VoidCallback onOpenSleep;
  final VoidCallback onOpenPatterns;
  final VoidCallback onOpenYou;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final summary = TodaySummary.fromDays(app.days, now: app.now);
    final wins = findGoingWell(summary);
    final patterns = findPatterns(app.days);
    final scores = DailyScores.fromDays(app.days);

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: ScreenHeader(
              eyebrow: formatEyebrowDate(app.now),
              title: 'Today',
              trailing: Avatar(onTap: onOpenYou),
            ),
          ),
          const SizedBox(height: 18),
          _ScoreDashboard(scores: scores),
          const SizedBox(height: 14),
          _BriefingCard(text: dailyBriefing(scores)),
          const SizedBox(height: 14),
          _UsualCard(summary: summary, onOpenSleep: onOpenSleep),
          if (wins.isNotEmpty) ...[
            const SizedBox(height: 14),
            _GoingWellCard(wins: wins),
          ],
          const SizedBox(height: 14),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: _HrvCard(summary: summary)),
                const SizedBox(width: 12),
                Expanded(child: _ActiveCard(summary: summary)),
              ],
            ),
          ),
          if (patterns.isNotEmpty) ...[
            const SizedBox(height: 14),
            _PatternTeaser(pattern: patterns.first, onTap: onOpenPatterns),
          ],
        ],
      ),
    );
  }
}

/// Recovery, Effort and Sleep as three rings, each with one plain reason.
class _ScoreDashboard extends StatelessWidget {
  const _ScoreDashboard({required this.scores});

  final DailyScores scores;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final recovery = scores.recovery;
    final effort = scores.effort;
    final sleep = scores.sleep;

    return AppCard(
      raised: true,
      padding: const EdgeInsets.fromLTRB(8, 18, 8, 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: _ScoreDial(
              label: 'RECOVERY',
              value: recovery?.score,
              unit: '%',
              colors: recovery == null
                  ? [p.faint]
                  : _soft(p.scoreColor(recovery.level)),
              valueColor: recovery == null ? null : p.scoreColor(recovery.level),
              reason: recovery?.reason ?? 'Not enough data yet',
              onTap: recovery == null
                  ? null
                  : () => showRecoveryBreakdown(context, recovery),
            ),
          ),
          Expanded(
            child: _ScoreDial(
              label: 'EFFORT',
              value: effort?.score,
              colors: p.effort,
              reason: effort?.reason ?? 'No activity yet',
            ),
          ),
          Expanded(
            child: _ScoreDial(
              label: 'SLEEP',
              value: sleep?.percent,
              unit: '%',
              colors: p.sleep.gradient,
              reason: sleep?.reason ?? 'No sleep tracked',
            ),
          ),
        ],
      ),
    );
  }
}

/// A gentle two-tone gradient from one colour, for the ring stroke.
List<Color> _soft(Color color) => [Color.lerp(color, Colors.white, 0.35)!, color];

/// The coach's note on today, written from the three scores.
class _BriefingCard extends StatelessWidget {
  const _BriefingCard({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return AppCard(
      color: p.surfaceAccent,
      padding: const EdgeInsets.fromLTRB(16, 16, 18, 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(colors: p.brand)),
            child: const Icon(Icons.auto_awesome_rounded, size: 17, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'DAILY BRIEFING',
                  style: AppFont.style(size: 11, weight: FontWeight.w700, letterSpacing: 1.6, color: p.muted),
                ),
                const SizedBox(height: 6),
                Text(text, style: AppFont.style(size: 15, height: 1.45, color: p.ink)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ScoreDial extends StatelessWidget {
  const _ScoreDial({
    required this.label,
    required this.value,
    required this.colors,
    required this.reason,
    this.unit,
    this.valueColor,
    this.onTap,
  });

  final String label;
  final int? value;
  final String? unit;
  final List<Color> colors;
  final Color? valueColor;
  final String reason;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final number = value;
    final content = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      child: Column(
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: AppFont.style(size: 11, weight: FontWeight.w700, letterSpacing: 1.6, color: p.muted),
                ),
                if (onTap != null) Icon(Icons.chevron_right_rounded, size: 14, color: p.muted),
              ],
            ),
          ),
          const SizedBox(height: 10),
          ScoreRing(
            fraction: number == null ? null : number / 100,
            colors: colors,
            size: 92,
            strokeWidth: 8,
            glow: true,
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(text: number?.toString() ?? '—'),
                  if (number != null && unit != null)
                    TextSpan(text: unit, style: AppFont.style(size: 14, weight: FontWeight.w700, color: p.muted)),
                ],
              ),
              style: AppFont.style(
                size: 28,
                weight: FontWeight.w800,
                letterSpacing: -1,
                color: valueColor ?? p.ink,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            reason,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppFont.style(size: 12, height: 1.3, color: p.muted),
          ),
        ],
      ),
    );
    final semanticValue = number == null ? 'no value' : '$number${unit ?? ''}';
    return Semantics(
      button: onTap != null,
      label: '${label[0]}${label.substring(1).toLowerCase()} $semanticValue. $reason',
      excludeSemantics: true,
      child: onTap == null
          ? content
          : InkWell(borderRadius: BorderRadius.circular(16), onTap: onTap, child: content),
    );
  }
}

/// "Why this score": how HRV, resting HR and sleep moved recovery from 50.
Future<void> showRecoveryBreakdown(BuildContext context, RecoveryScore recovery) {
  final p = context.palette;
  String signed(double points) {
    final rounded = points.round();
    return rounded > 0 ? '+$rounded' : (rounded < 0 ? '−${rounded.abs()}' : '0');
  }

  Widget row(String label, String detail, String value, {Color? color, bool bold = false}) {
    return Container(
      constraints: const BoxConstraints(minHeight: 52),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: p.border))),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(label, style: AppFont.style(size: 15, weight: bold ? FontWeight.w700 : FontWeight.w600, color: p.ink)),
                if (detail.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(detail, style: AppFont.style(size: 12, color: p.muted)),
                ],
              ],
            ),
          ),
          Text(
            value,
            style: AppFont.style(size: 17, weight: FontWeight.w800, color: color ?? p.ink),
          ),
        ],
      ),
    );
  }

  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: p.surfaceRaised,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (context) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 0, 22, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'WHY THIS SCORE',
              style: AppFont.style(size: 12, weight: FontWeight.w600, letterSpacing: 2.4, color: p.muted),
            ),
            const SizedBox(height: 4),
            Text(
              'Recovery ${recovery.score}%',
              style: AppFont.style(size: 30, weight: FontWeight.w800, letterSpacing: -1, color: p.scoreColor(recovery.level)),
            ),
            const SizedBox(height: 6),
            Text(
              'A normal day for you is 50. Each part adds or takes points, '
              'based on last night against your last 28 days.',
              style: AppFont.style(size: 13, height: 1.4, color: p.muted),
            ),
            const SizedBox(height: 8),
            row('Start', 'Your normal', '50'),
            for (final c in recovery.contributions)
              row(
                c.factor.label,
                '${c.reason} · weight ${(c.weight * 100).round()}%',
                signed(c.points),
                color: c.points.round() > 0
                    ? p.recoveryHigh
                    : (c.points.round() < 0 ? p.recoveryLow : null),
              ),
            row('Recovery', 'Kept between 0 and 100', '${recovery.score}', bold: true),
          ],
        ),
      ),
    ),
  );
}

class _UsualCard extends StatelessWidget {
  const _UsualCard({required this.summary, required this.onOpenSleep});

  final TodaySummary summary;
  final VoidCallback onOpenSleep;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    final sleep = GaugeReading.from(summary.sleep);
    final heart = GaugeReading.from(summary.restingHeartRate);
    final steps = GaugeReading.from(summary.stepsSoFar);

    return AppCard(
      raised: true,
      padding: const EdgeInsets.fromLTRB(12, 20, 12, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Today vs your usual',
                  style: AppFont.style(size: 17, weight: FontWeight.w700, color: p.ink),
                ),
                const SizedBox(height: 2),
                Text(
                  'Usual = the middle of your last 28 days',
                  style: AppFont.style(size: 12, color: p.muted),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _GaugeColumn(
                  title: 'Sleep',
                  colors: p.sleep,
                  reading: sleep,
                  value: summary.sleep.value == null
                      ? '—'
                      : formatHm(summary.sleep.value!.round()),
                  chip: sleep == null ? null : sleepDifferenceText(sleep.difference),
                  note: sleep == null
                      ? _missingNote(summary.sleep, 'No sleep tracked')
                      : 'Usual ${formatHm(sleep.usual.round())} · '
                          '${rangeStatusText(sleep.status)}',
                  onTap: onOpenSleep,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _GaugeColumn(
                  title: 'Resting HR',
                  colors: p.heart,
                  reading: heart,
                  value: summary.restingHeartRate.value?.toString() ?? '—',
                  unit: 'bpm',
                  chip: heart == null ? null : heartRateDifferenceText(heart.difference),
                  note: heart == null
                      ? _missingNote(summary.restingHeartRate, 'Not measured')
                      : 'Usual ${heart.usual.round()} · '
                          '${rangeStatusWithBounds(heart.status, heart.range)}',
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _GaugeColumn(
                  title: 'Steps',
                  colors: p.activity,
                  reading: steps,
                  value: summary.stepsSoFar.value == null
                      ? '—'
                      : formatThousands(summary.stepsSoFar.value!.round()),
                  chip: steps == null ? null : stepsDifferenceText(steps.difference),
                  note: steps == null
                      ? (summary.stepsSoFar.range != null &&
                              summary.stepsSoFar.range!.median <= 0
                          ? 'Your day has just started'
                          : _missingNote(summary.stepsSoFar, 'No steps yet'))
                      : 'Usual ${formatThousands(steps.usual.round())} by now · '
                          '${paceStatusText(steps.status)}',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static String _missingNote(MetricSignal signal, String noValue) =>
      signal.value == null ? noValue : 'Learning your usual';
}

class _GaugeColumn extends StatelessWidget {
  const _GaugeColumn({
    required this.title,
    required this.colors,
    required this.reading,
    required this.value,
    required this.note,
    this.unit,
    this.chip,
    this.onTap,
  });

  final String title;
  final CategoryColors colors;
  final GaugeReading? reading;
  final String value;
  final String? unit;
  final String? chip;
  final String note;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final content = Padding(
      padding: const EdgeInsets.fromLTRB(2, 6, 2, 8),
      child: Column(
        children: [
          ArcGauge(
            fraction: reading?.fraction,
            usualFraction: reading == null ? null : GaugeReading.usualPosition,
            colors: colors.gradient,
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(text: value),
                  if (unit != null)
                    TextSpan(
                      text: ' $unit',
                      style: AppFont.style(size: 11, color: p.muted),
                    ),
                ],
              ),
              style: AppFont.style(
                size: 18,
                weight: FontWeight.w800,
                letterSpacing: -0.5,
                color: p.ink,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            onTap == null ? title : '$title ›',
            style: AppFont.style(size: 13, weight: FontWeight.w700, color: colors.label),
          ),
          if (chip != null) ...[
            const SizedBox(height: 4),
            DiffChip(chip!, background: colors.soft, foreground: colors.onSoft),
          ],
          const SizedBox(height: 4),
          Text(
            note,
            textAlign: TextAlign.center,
            style: AppFont.style(size: 12, height: 1.3, color: p.muted),
          ),
        ],
      ),
    );
    if (onTap == null) return content;
    return Semantics(
      button: true,
      hint: 'Opens sleep details',
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: content,
      ),
    );
  }
}

class _GoingWellCard extends StatelessWidget {
  const _GoingWellCard({required this.wins});

  final List<Highlight> wins;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return AppCard(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      borderColor: p.activity.label.withValues(alpha: 0.3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Going well',
            style: AppFont.style(size: 15, weight: FontWeight.w700, color: p.activity.label),
          ),
          for (final win in wins) ...[
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.check_circle_outline_rounded, size: 20, color: p.activity.label),
                const SizedBox(width: 12),
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(text: win.before),
                        TextSpan(
                          text: win.bold,
                          style: AppFont.style(weight: FontWeight.w700),
                        ),
                        TextSpan(text: win.after),
                      ],
                    ),
                    style: AppFont.style(size: 14, height: 1.4, color: p.ink),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _SmallMetricCard extends StatelessWidget {
  const _SmallMetricCard({
    required this.icon,
    required this.title,
    required this.colors,
    required this.value,
    required this.unit,
    required this.chart,
    required this.note,
  });

  final IconData icon;
  final String title;
  final CategoryColors colors;
  final String value;
  final String unit;
  final Widget chart;
  final String note;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: colors.label),
              const SizedBox(width: 6),
              Text(
                title,
                style: AppFont.style(size: 13, weight: FontWeight.w700, color: colors.label),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(text: value),
                TextSpan(
                  text: ' $unit',
                  style: AppFont.style(size: 13, weight: FontWeight.w500, color: p.muted),
                ),
              ],
            ),
            style: AppFont.style(size: 28, weight: FontWeight.w800, letterSpacing: -1, color: p.ink),
          ),
          const SizedBox(height: 8),
          chart,
          const Spacer(),
          const SizedBox(height: 8),
          Text(note, style: AppFont.style(size: 12, color: p.muted)),
        ],
      ),
    );
  }
}

class _HrvCard extends StatelessWidget {
  const _HrvCard({required this.summary});

  final TodaySummary summary;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final signal = summary.heartRateVariability;
    final range = signal.range;
    final status = signal.status;
    return _SmallMetricCard(
      icon: Icons.favorite_border_rounded,
      title: 'HRV',
      colors: p.heart,
      value: signal.value?.toString() ?? '—',
      unit: 'ms',
      chart: Sparkline(
        values: summary.recentHrv,
        colors: p.heart.gradient,
        bandLow: range?.low,
        bandHigh: range?.high,
      ),
      note: signal.value == null
          ? 'Not measured · needs a full night of wear'
          : range == null || status == null
              ? 'Learning your usual'
              : 'Usual ${range.low.round()}–${range.high.round()} · '
                  '${dailyStatusText(status)}',
    );
  }
}

class _ActiveCard extends StatelessWidget {
  const _ActiveCard({required this.summary});

  final TodaySummary summary;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return _SmallMetricCard(
      icon: Icons.bolt_rounded,
      title: 'Active',
      colors: p.activity,
      value: summary.activeZoneMinutes.value?.toString() ?? '—',
      unit: 'min',
      chart: MiniBars(values: summary.recentActiveMinutes, colors: p.activity),
      note: 'Yesterday · last 7 days',
    );
  }
}

class _PatternTeaser extends StatelessWidget {
  const _PatternTeaser({required this.pattern, required this.onTap});

  final FoundPattern pattern;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return AppCard(
      onTap: onTap,
      color: p.surfaceAccent,
      borderColor: p.sleep.label.withValues(alpha: 0.25),
      padding: const EdgeInsets.fromLTRB(18, 16, 14, 16),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: LinearGradient(colors: p.brand),
            ),
            child: const Icon(Icons.insights_rounded, size: 20, color: Colors.white),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Pattern in your data', style: AppFont.style(size: 12, color: p.muted)),
                Text(
                  pattern.title,
                  style: AppFont.style(size: 15, weight: FontWeight.w700, color: p.ink),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: p.muted),
        ],
      ),
    );
  }
}
