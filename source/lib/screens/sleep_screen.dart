import 'package:flutter/material.dart';

import '../app_state.dart';
import '../logic/formatters.dart';
import '../logic/gauge_reading.dart';
import '../logic/patterns.dart';
import '../logic/personal_range.dart';
import '../logic/sleep_comparison.dart';
import '../logic/stats.dart';
import '../models/daily_metrics.dart';
import '../ui/app_font.dart';
import '../ui/charts.dart';
import '../ui/components.dart';
import '../ui/palette.dart';

/// Sleep in detail: one night, the last week or the last four weeks.
class SleepScreen extends StatefulWidget {
  const SleepScreen({super.key});

  @override
  State<SleepScreen> createState() => _SleepScreenState();
}

class _SleepScreenState extends State<SleepScreen> {
  static const _periods = ['Day', 'Week', 'Month'];
  int _period = 1;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final p = context.palette;
    final days = app.days;
    final lastNight = days.first;

    return Scaffold(
      backgroundColor: p.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => Navigator.of(context).pop(),
                icon: Icon(Icons.chevron_left_rounded, color: p.muted),
                label: Text(
                  'Today',
                  style: AppFont.style(size: 15, weight: FontWeight.w600, color: p.muted),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: ScreenHeader(title: 'Sleep', titleColor: p.sleep.label),
            ),
            const SizedBox(height: 16),
            SegmentedSwitch(
              options: _periods,
              selectedIndex: _period,
              onChanged: (index) => setState(() => _period = index),
              selectedGradient: p.sleep.gradient,
              semanticLabel: 'Period',
            ),
            const SizedBox(height: 14),
            if (_period == 0)
              _LastNightCard(night: lastNight, large: true)
            else ...[
              _AverageCard(days: days, nights: _period == 1 ? 7 : 28),
              const SizedBox(height: 14),
              _LastNightCard(night: lastNight),
            ],
            const SizedBox(height: 14),
            _ComparisonCard(rows: compareSleepWeek(days)),
          ],
        ),
      ),
    );
  }
}

class _AverageCard extends StatelessWidget {
  const _AverageCard({required this.days, required this.nights});

  final List<DailyMetrics> days;
  final int nights;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final period = days.take(nights).toList().reversed.toList();
    final sleep = presentValues(period.map((d) => d.sleepMinutes));
    final usual = PersonalRange.tryFrom(days.skip(1).map((d) => d.sleepMinutes));
    if (sleep.isEmpty || usual == null) {
      return AppCard(
        raised: true,
        child: Text(
          'Learning your usual: comparisons appear after 7 nights.',
          style: AppFont.style(size: 14, color: p.muted),
        ),
      );
    }
    final average = mean(sleep);

    return AppCard(
      raised: true,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            nights == 7 ? 'Average this week' : 'Average, last 4 weeks',
            style: AppFont.style(size: 13, color: p.muted),
          ),
          const SizedBox(height: 4),
          Text(
            formatHm(average.round()),
            style: AppFont.style(size: 46, weight: FontWeight.w800, letterSpacing: -2, height: 1, color: p.ink),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              DiffChip(
                sleepDifferenceText(average - usual.median),
                background: p.sleep.soft,
                foreground: p.sleep.onSoft,
              ),
              Text(
                'vs your usual ${formatHm(usual.median.round())}',
                style: AppFont.style(size: 12, color: p.muted),
              ),
            ],
          ),
          const SizedBox(height: 18),
          NightBarsChart(
            height: 150,
            gap: nights == 7 ? 10 : 3,
            usualMinutes: usual.median,
            usualLabel: 'usual ${formatHm(usual.median.round())}',
            bars: [
              for (var i = 0; i < period.length; i++)
                NightBar(
                  minutes: period[i].sleepMinutes,
                  label: nights == 7 || i % 7 == 6 ? weekdayLetter(period[i].date) : '',
                  striped: isLateNight(period[i]),
                  highlighted: i == period.length - 1,
                ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 16,
            runSpacing: 6,
            children: [
              _LegendItem(swatch: BarSwatch(colors: p.sleep), label: 'In bed before 00:45'),
              _LegendItem(swatch: BarSwatch(colors: p.sleep, striped: true), label: 'In bed after 00:45'),
            ],
          ),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.swatch, required this.label});

  final Widget swatch;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        swatch,
        const SizedBox(width: 6),
        Text(label, style: AppFont.style(size: 12, color: context.palette.muted)),
      ],
    );
  }
}

class _LastNightCard extends StatelessWidget {
  const _LastNightCard({required this.night, this.large = false});

  final DailyMetrics night;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final stages = night.sleepStages;
    final bedtime = night.bedtime;
    final wakeTime = night.wakeTime;

    if (stages == null) {
      return AppCard(
        borderColor: p.sleep.label.withValues(alpha: 0.35),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'No sleep recorded last night',
              style: AppFont.style(size: 18, weight: FontWeight.w800, color: p.ink),
            ),
            const SizedBox(height: 6),
            Text(
              "Wear your Fitbit Air to bed to see tonight. This night is left "
              "out of your usual, so it won't pull your average down.",
              style: AppFont.style(size: 13, height: 1.4, color: p.muted),
            ),
          ],
        ),
      );
    }

    final segments = night.sleepSegments.isNotEmpty
        ? night.sleepSegments
        : [
            for (final stage in SleepStage.values)
              if (stages.minutesIn(stage) > 0) SleepSegment(stage, stages.minutesIn(stage)),
          ];

    return AppCard(
      raised: large,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Last night',
                  style: AppFont.style(size: 15, weight: FontWeight.w700, color: p.ink),
                ),
              ),
              if (bedtime != null && wakeTime != null)
                Text(
                  '${formatClockTime(bedtime)} – ${formatClockTime(wakeTime)}',
                  style: AppFont.style(size: 12, color: p.muted),
                ),
            ],
          ),
          if (large) ...[
            const SizedBox(height: 4),
            Text(
              formatHm(stages.asleep),
              style: AppFont.style(size: 46, weight: FontWeight.w800, letterSpacing: -2, height: 1, color: p.ink),
            ),
          ],
          const SizedBox(height: 12),
          StageTimeline(segments: segments),
          if (bedtime != null && wakeTime != null) ...[
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(formatClockTime(bedtime), style: AppFont.style(size: 11, color: p.faint)),
                Text(formatClockTime(wakeTime), style: AppFont.style(size: 11, color: p.faint)),
              ],
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              for (final (stage, label) in const [
                (SleepStage.deep, 'Deep'),
                (SleepStage.light, 'Light'),
                (SleepStage.rem, 'REM'),
                (SleepStage.awake, 'Awake'),
              ])
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(shape: BoxShape.circle, color: p.stage(stage)),
                          ),
                          const SizedBox(width: 5),
                          Text(label, style: AppFont.style(size: 11, color: p.muted)),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        formatHm(stages.minutesIn(stage)),
                        style: AppFont.style(size: 15, weight: FontWeight.w700, color: p.ink),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ComparisonCard extends StatelessWidget {
  const _ComparisonCard({required this.rows});

  final List<ComparisonRow> rows;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    if (rows.isEmpty) return const SizedBox.shrink();

    Widget cell(String text, {required bool header, bool highlight = false, bool alignRight = true}) {
      return Text(
        text,
        textAlign: alignRight ? TextAlign.right : TextAlign.left,
        style: AppFont.style(
          size: header ? 11 : 14,
          weight: header ? FontWeight.w500 : (highlight ? FontWeight.w700 : FontWeight.w500),
          color: header ? p.muted : (highlight ? p.sleep.onSoft : p.ink),
        ),
      );
    }

    return AppCard(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'This week vs your usual',
            style: AppFont.style(size: 15, weight: FontWeight.w700, color: p.ink),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Expanded(child: SizedBox()),
              SizedBox(width: 84, child: cell('This week', header: true)),
              SizedBox(width: 76, child: cell('Usual', header: true)),
            ],
          ),
          for (final row in rows)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 11),
              decoration: BoxDecoration(border: Border(top: BorderSide(color: p.border))),
              child: Row(
                children: [
                  Expanded(child: cell(row.label, header: false, alignRight: false)),
                  SizedBox(width: 84, child: cell(row.current, header: false, highlight: row.outsideUsual)),
                  SizedBox(
                    width: 76,
                    child: Text(
                      row.usual,
                      textAlign: TextAlign.right,
                      style: AppFont.style(size: 14, color: p.muted),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 4),
          Text(
            'Highlighted values are outside your usual range · '
            'usual = middle of your last 28 days',
            style: AppFont.style(size: 11, color: p.muted),
          ),
        ],
      ),
    );
  }
}
