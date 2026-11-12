import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../app_state.dart';
import '../logic/experiment.dart';
import '../logic/patterns.dart';
import '../ui/app_font.dart';
import '../ui/components.dart';
import '../ui/palette.dart';

/// Links found in the user's own data, and a 7-night experiment.
class PatternsScreen extends StatefulWidget {
  const PatternsScreen({super.key});

  @override
  State<PatternsScreen> createState() => _PatternsScreenState();
}

class _PatternsScreenState extends State<PatternsScreen> {
  PatternCategory? _filter;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final p = context.palette;
    final patterns = findPatterns(app.days);
    final shown = _filter == null
        ? patterns
        : patterns.where((pattern) => pattern.involves(_filter!)).toList();
    final experiment = BedtimeExperiment.sample(app.days);

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: ScreenHeader(eyebrow: 'FROM YOUR LAST 28 DAYS', title: 'Patterns'),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 8, 4, 16),
            child: Text(
              'Things that tend to happen together in your data. '
              'They show a link, not proof of cause.',
              style: AppFont.style(size: 13, height: 1.4, color: p.muted),
            ),
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _FilterChip(
                label: 'All',
                selected: _filter == null,
                color: p.ink,
                onTap: () => setState(() => _filter = null),
              ),
              for (final (category, label) in const [
                (PatternCategory.sleep, 'Sleep'),
                (PatternCategory.heart, 'Heart'),
                (PatternCategory.activity, 'Activity'),
              ])
                _FilterChip(
                  label: label,
                  selected: _filter == category,
                  color: p.category(category).label,
                  onTap: () => setState(() => _filter = category),
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (patterns.isEmpty)
            _NotEnoughNightsCard(nights: trackedNights(app.days))
          else if (shown.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'No patterns in this area yet.',
                style: AppFont.style(size: 14, color: p.muted),
              ),
            )
          else
            for (final pattern in shown) ...[
              _PatternCard(pattern: pattern),
              const SizedBox(height: 14),
            ],
          _ExperimentCard(
            experiment: experiment,
            reminderOn: app.bedtimeReminder,
            onToggleReminder: () {
              final turnOn = !app.bedtimeReminder;
              app.setBedtimeReminder(turnOn);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    turnOn ? "We'll remind you at 00:00." : 'Reminder turned off.',
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: selected ? color : Colors.transparent,
        shape: StadiumBorder(
          side: BorderSide(color: selected ? color : color.withValues(alpha: 0.4)),
        ),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
            child: Text(
              label,
              style: AppFont.style(
                size: 13,
                weight: selected ? FontWeight.w700 : FontWeight.w600,
                color: selected ? p.background : color,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PatternCard extends StatelessWidget {
  const _PatternCard({required this.pattern});

  final FoundPattern pattern;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final causeColor = p.category(pattern.causeCategory).label;
    final effectColors = p.category(pattern.effectCategory);
    final largest = math.max(pattern.highlight.average, pattern.baseline.average);
    final consistent = pattern.strength == PatternStrength.consistent;

    Widget bar(String name, double value, {required bool highlighted}) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(name, style: AppFont.style(size: 13, color: p.muted))),
              Text(
                pattern.format(value),
                style: AppFont.style(
                  size: 13,
                  weight: FontWeight.w700,
                  color: highlighted ? effectColors.onSoft : p.ink,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Container(
            height: 16,
            decoration: BoxDecoration(color: p.track, borderRadius: BorderRadius.circular(8)),
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: (value / largest).clamp(0.05, 1.0),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: highlighted ? null : effectColors.flat,
                  gradient: highlighted ? effectColors.horizontal : null,
                ),
              ),
            ),
          ),
        ],
      );
    }

    return AppCard(
      raised: true,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(text: pattern.cause, style: AppFont.style(color: causeColor)),
                      TextSpan(text: '  →  ', style: AppFont.style(color: p.faint)),
                      TextSpan(text: pattern.effect, style: AppFont.style(color: effectColors.label)),
                    ],
                  ),
                  style: AppFont.style(size: 12, weight: FontWeight.w700),
                ),
              ),
              DiffChip(
                consistent ? 'Consistent so far' : 'Early pattern',
                background: consistent ? effectColors.soft : p.track,
                foreground: consistent ? effectColors.onSoft : p.muted,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            pattern.title,
            style: AppFont.style(size: 21, weight: FontWeight.w800, letterSpacing: -0.5, height: 1.15, color: p.ink),
          ),
          const SizedBox(height: 14),
          bar(pattern.baseline.name, pattern.baseline.average, highlighted: false),
          const SizedBox(height: 10),
          bar(pattern.highlight.name, pattern.highlight.average, highlighted: true),
          const SizedBox(height: 12),
          Text(
            'Based on ${pattern.totalCount} ${pattern.countNoun}: '
            '${pattern.highlight.count} vs ${pattern.baseline.count}',
            style: AppFont.style(size: 12, color: p.muted),
          ),
        ],
      ),
    );
  }
}

class _NotEnoughNightsCard extends StatelessWidget {
  const _NotEnoughNightsCard({required this.nights});

  final int nights;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'No patterns yet',
                    style: AppFont.style(size: 16, weight: FontWeight.w700, color: p.ink),
                  ),
                ),
                Text(
                  '$nights of $minimumNightsForPatterns nights',
                  style: AppFont.style(size: 13, color: p.muted),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: (nights / minimumNightsForPatterns).clamp(0.0, 1.0),
                minHeight: 8,
                backgroundColor: p.track,
                color: p.sleep.gradient.last,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              "Patterns need at least $minimumNightsForPatterns nights so "
              "they aren't based on luck.",
              style: AppFont.style(size: 13, color: p.muted),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExperimentCard extends StatelessWidget {
  const _ExperimentCard({
    required this.experiment,
    required this.reminderOn,
    required this.onToggleReminder,
  });

  final BedtimeExperiment experiment;
  final bool reminderOn;
  final VoidCallback onToggleReminder;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    const white = Colors.white;

    Widget night(int index) {
      final done = index < experiment.nightsDone;
      final isTonight = index == experiment.nightsDone;
      final made = done && experiment.results[index];
      return Expanded(
        child: Container(
          height: 8,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            color: made
                ? white
                : white.withValues(alpha: done || isTonight ? 0.35 : 0.2),
            border: isTonight ? Border.all(color: white, width: 2) : null,
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: p.experiment,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'EXPERIMENT',
            style: AppFont.style(size: 12, weight: FontWeight.w700, letterSpacing: 2, color: white.withValues(alpha: 0.9)),
          ),
          const SizedBox(height: 8),
          Text(
            experiment.title,
            style: AppFont.style(size: 24, weight: FontWeight.w800, letterSpacing: -0.7, height: 1.1, color: white),
          ),
          const SizedBox(height: 14),
          Semantics(
            label: '${experiment.nightsMet} of ${experiment.nightsDone} nights done, '
                'night ${experiment.tonight} tonight',
            child: ExcludeSemantics(
              child: Row(
                children: [
                  for (var i = 0; i < experiment.lengthNights; i++) night(i),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Night ${experiment.tonight} tonight · '
                  '${experiment.nightsMet} of ${experiment.nightsDone} done',
                  style: AppFont.style(size: 13, color: white),
                ),
              ),
              FilledButton(
                onPressed: onToggleReminder,
                style: FilledButton.styleFrom(
                  backgroundColor: white,
                  foregroundColor: const Color(0xFF0A0810),
                  minimumSize: const Size(0, 44),
                  shape: const StadiumBorder(),
                  textStyle: AppFont.style(size: 14, weight: FontWeight.w700),
                ),
                child: Text(reminderOn ? 'Reminder on' : 'Remind me'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
