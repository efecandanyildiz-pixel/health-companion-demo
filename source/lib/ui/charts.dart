import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/daily_metrics.dart';
import 'app_font.dart';
import 'palette.dart';

/// Half-circle gauge: the arc is today, the notch marks your usual.
class ArcGauge extends StatelessWidget {
  const ArcGauge({
    super.key,
    required this.fraction,
    required this.usualFraction,
    required this.colors,
    required this.child,
  });

  /// How far the arc is filled (0–1). Null draws only the empty track.
  final double? fraction;

  /// Where the "usual" notch sits. Null hides the notch.
  final double? usualFraction;
  final List<Color> colors;

  /// Shown inside the arc, usually the value.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 108),
      child: AspectRatio(
        aspectRatio: 100 / 70,
        child: CustomPaint(
          painter: _ArcGaugePainter(
            fraction: fraction,
            usualFraction: usualFraction,
            colors: colors,
            track: p.track,
            mark: p.usualMark,
            labelStyle: AppFont.style(weight: FontWeight.w700, color: p.usualMark),
          ),
          child: Align(alignment: Alignment.bottomCenter, child: child),
        ),
      ),
    );
  }
}

class _ArcGaugePainter extends CustomPainter {
  _ArcGaugePainter({
    required this.fraction,
    required this.usualFraction,
    required this.colors,
    required this.track,
    required this.mark,
    required this.labelStyle,
  });

  final double? fraction;
  final double? usualFraction;
  final List<Color> colors;
  final Color track;
  final Color mark;
  final TextStyle labelStyle;

  @override
  void paint(Canvas canvas, Size size) {
    // Drawn in a 100 x 70 box; the arc's center sits at (50, 62).
    final s = size.width / 100;
    final center = Offset(50 * s, 62 * s);
    final radius = 40 * s;
    final rect = Rect.fromCircle(center: center, radius: radius);

    Paint arcPaint() => Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10 * s
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(rect, math.pi, math.pi, false, arcPaint()..color = track);

    final filled = fraction;
    if (filled != null && filled > 0) {
      canvas.drawArc(
        rect,
        math.pi,
        math.pi * filled,
        false,
        arcPaint()..shader = LinearGradient(colors: colors).createShader(rect),
      );
    }

    final usual = usualFraction;
    if (usual == null) return;
    final angle = math.pi + math.pi * usual;
    Offset at(double r) => center + Offset(math.cos(angle) * r, math.sin(angle) * r);
    canvas.drawLine(
      at(32 * s),
      at(47 * s),
      Paint()
        ..color = mark
        ..strokeWidth = 3.5 * s
        ..strokeCap = StrokeCap.round,
    );
    final label = TextPainter(
      text: TextSpan(text: 'usual', style: labelStyle.copyWith(fontSize: 10 * s)),
      textDirection: TextDirection.ltr,
    )..layout();
    final anchor = at(55 * s);
    label.paint(canvas, anchor - Offset(label.width / 2, label.height / 2));
  }

  @override
  bool shouldRepaint(_ArcGaugePainter old) =>
      old.fraction != fraction ||
      old.usualFraction != usualFraction ||
      old.colors != colors ||
      old.track != track ||
      old.mark != mark;
}

/// One bar of a sleep chart.
class NightBar {
  const NightBar({
    required this.minutes,
    required this.label,
    this.striped = false,
    this.highlighted = false,
  });

  final int? minutes;
  final String label;

  /// Striped = in bed after 00:45.
  final bool striped;

  /// The most recent night, drawn with the gradient.
  final bool highlighted;
}

/// Bars for nights, with a dashed line at your usual sleep.
class NightBarsChart extends StatelessWidget {
  const NightBarsChart({
    super.key,
    required this.bars,
    required this.usualMinutes,
    this.height = 110,
    this.usualLabel,
    this.gap = 9,
  });

  final List<NightBar> bars;
  final double usualMinutes;
  final double height;
  final String? usualLabel;
  final double gap;

  /// Bars start at 4 hours, so differences of 30–60 minutes are visible.
  static const _baseline = 240.0;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final colors = p.sleep;
    final tallest = bars
        .map((bar) => (bar.minutes ?? 0).toDouble())
        .fold<double>(usualMinutes, math.max);
    final top = tallest + 20;
    double heightOf(num minutes) =>
        height * ((minutes - _baseline) / (top - _baseline)).clamp(0.04, 1.0);
    final usualY = heightOf(usualMinutes);

    return Column(
      children: [
        SizedBox(
          height: height,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    for (final bar in bars)
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: gap / 2),
                          child: _Bar(
                            height: bar.minutes == null ? 4 : heightOf(bar.minutes!),
                            colors: colors,
                            striped: bar.striped,
                            highlighted: bar.highlighted,
                            empty: bar.minutes == null,
                            emptyColor: p.track,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: usualY,
                child: SizedBox(
                  height: 1.5,
                  child: CustomPaint(painter: _DashedLinePainter(p.usualMark.withValues(alpha: 0.5))),
                ),
              ),
              if (usualLabel != null)
                Positioned(
                  right: 0,
                  bottom: usualY + 4,
                  child: Text(usualLabel!, style: AppFont.style(size: 11, color: p.muted)),
                ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            for (final bar in bars)
              Expanded(
                child: Text(
                  bar.label,
                  textAlign: TextAlign.center,
                  style: AppFont.style(
                    size: 11,
                    weight: bar.highlighted ? FontWeight.w700 : FontWeight.w400,
                    color: bar.highlighted ? p.ink : p.faint,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({
    required this.height,
    required this.colors,
    required this.striped,
    required this.highlighted,
    required this.empty,
    required this.emptyColor,
  });

  final double height;
  final CategoryColors colors;
  final bool striped;
  final bool highlighted;
  final bool empty;
  final Color emptyColor;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(8);
    if (empty) {
      return Container(
        height: height,
        decoration: BoxDecoration(color: emptyColor, borderRadius: radius),
      );
    }
    if (striped) {
      return ClipRRect(
        borderRadius: radius,
        child: SizedBox(
          height: height,
          width: double.infinity,
          child: CustomPaint(
            painter: _StripesPainter(
              base: highlighted ? colors.gradient.last : colors.flat,
              stripe: highlighted ? colors.gradient.first : colors.stripe,
            ),
          ),
        ),
      );
    }
    return Container(
      height: height,
      decoration: BoxDecoration(
        borderRadius: radius,
        color: highlighted ? null : colors.flat,
        gradient: highlighted ? colors.vertical : null,
      ),
    );
  }
}

class _StripesPainter extends CustomPainter {
  _StripesPainter({required this.base, required this.stripe});

  final Color base;
  final Color stripe;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = base);
    final paint = Paint()
      ..color = stripe
      ..strokeWidth = 4;
    for (var x = -size.height; x < size.width; x += 9) {
      canvas.drawLine(Offset(x, size.height), Offset(x + size.height, 0), paint);
    }
  }

  @override
  bool shouldRepaint(_StripesPainter old) => old.base != base || old.stripe != stripe;
}

class _DashedLinePainter extends CustomPainter {
  _DashedLinePainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = size.height;
    for (var x = 0.0; x < size.width; x += 8) {
      canvas.drawLine(
        Offset(x, size.height / 2),
        Offset(math.min(x + 4, size.width), size.height / 2),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_DashedLinePainter old) => old.color != color;
}

/// A small square showing what a bar style means, for legends.
class BarSwatch extends StatelessWidget {
  const BarSwatch({super.key, required this.colors, this.striped = false});

  final CategoryColors colors;
  final bool striped;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(3),
      child: SizedBox(
        width: 12,
        height: 12,
        child: striped
            ? CustomPaint(painter: _StripesPainter(base: colors.gradient.first, stripe: colors.stripe))
            : ColoredBox(color: colors.flat),
      ),
    );
  }
}

/// The night in order: one colored block per sleep stage.
class StageTimeline extends StatelessWidget {
  const StageTimeline({super.key, required this.segments});

  final List<SleepSegment> segments;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(
        height: 34,
        child: Row(
          children: [
            for (var i = 0; i < segments.length; i++)
              Expanded(
                flex: segments[i].minutes,
                child: Container(
                  margin: EdgeInsets.only(right: i == segments.length - 1 ? 0 : 2),
                  color: p.stage(segments[i].stage),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// A small line chart with your usual range as a band behind it.
class Sparkline extends StatelessWidget {
  const Sparkline({
    super.key,
    required this.values,
    required this.colors,
    this.bandLow,
    this.bandHigh,
    this.height = 44,
  });

  final List<int?> values;
  final List<Color> colors;
  final double? bandLow;
  final double? bandHigh;
  final double height;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(
        painter: _SparklinePainter(
          values: values,
          colors: colors,
          bandLow: bandLow,
          bandHigh: bandHigh,
          bandColor: p.track,
          dotColor: p.usualMark,
        ),
      ),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  _SparklinePainter({
    required this.values,
    required this.colors,
    required this.bandLow,
    required this.bandHigh,
    required this.bandColor,
    required this.dotColor,
  });

  final List<int?> values;
  final List<Color> colors;
  final double? bandLow;
  final double? bandHigh;
  final Color bandColor;
  final Color dotColor;

  @override
  void paint(Canvas canvas, Size size) {
    final present = values.whereType<int>().map((v) => v.toDouble()).toList();
    if (present.length < 2) return;
    var low = present.reduce(math.min);
    var high = present.reduce(math.max);
    if (bandLow != null) low = math.min(low, bandLow!);
    if (bandHigh != null) high = math.max(high, bandHigh!);
    final padding = (high - low) * 0.2 + 1;
    low -= padding;
    high += padding;
    double yOf(double v) => size.height - (v - low) / (high - low) * size.height;
    double xOf(int i) => values.length == 1 ? 0 : i / (values.length - 1) * (size.width - 6) + 3;

    if (bandLow != null && bandHigh != null) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTRB(0, yOf(bandHigh!), size.width, yOf(bandLow!)),
          const Radius.circular(4),
        ),
        Paint()..color = bandColor,
      );
    }

    final points = <Offset>[
      for (var i = 0; i < values.length; i++)
        if (values[i] != null) Offset(xOf(i), yOf(values[i]!.toDouble())),
    ];
    final line = Path()..moveTo(points.first.dx, points.first.dy);
    for (final point in points.skip(1)) {
      line.lineTo(point.dx, point.dy);
    }
    final area = Path.from(line)
      ..lineTo(points.last.dx, size.height)
      ..lineTo(points.first.dx, size.height)
      ..close();
    final bounds = Offset.zero & size;
    canvas.drawPath(
      area,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [colors.last.withValues(alpha: 0.35), colors.last.withValues(alpha: 0)],
        ).createShader(bounds),
    );
    canvas.drawPath(
      line,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..shader = LinearGradient(colors: colors).createShader(bounds),
    );
    canvas.drawCircle(points.last, 4, Paint()..color = dotColor);
  }

  @override
  bool shouldRepaint(_SparklinePainter old) => true;
}

/// Small bars for recent days; the last one is highlighted.
class MiniBars extends StatelessWidget {
  const MiniBars({super.key, required this.values, required this.colors, this.height = 44});

  final List<int?> values;
  final CategoryColors colors;
  final double height;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final tallest = values.whereType<int>().fold<int>(1, math.max);
    return SizedBox(
      height: height,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (var i = 0; i < values.length; i++)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Container(
                  height: values[i] == null
                      ? 3
                      : math.max(3, height * values[i]! / tallest),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    color: values[i] == null
                        ? p.track
                        : (i == values.length - 1 ? null : colors.flat),
                    gradient: values[i] != null && i == values.length - 1
                        ? colors.vertical
                        : null,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// A full ring that fills clockwise from the top, with [child] inside.
/// Used for the daily scores and, small, for a friend's mood.
///
/// The fill eases in when it first shows or changes. With reduce motion on,
/// it appears at once.
class ScoreRing extends StatelessWidget {
  const ScoreRing({
    super.key,
    required this.fraction,
    required this.colors,
    this.size = 96,
    this.strokeWidth = 9,
    this.glow = false,
    this.child,
  });

  /// How far the ring is filled (0–1). Null draws only the empty track.
  final double? fraction;

  /// One colour, or several for a soft gradient along the ring.
  final List<Color> colors;
  final double size;
  final double strokeWidth;

  /// A soft halo of the ring colour behind the stroke, for the big rings.
  final bool glow;
  final Widget? child;

  static const fillDuration = Duration(milliseconds: 900);

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final target = fraction?.clamp(0.0, 1.0);
    final duration = MediaQuery.maybeDisableAnimationsOf(context) ?? false
        ? Duration.zero
        : fillDuration;
    return SizedBox(
      width: size,
      height: size,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: target ?? 0),
        duration: duration,
        curve: Curves.easeOutCubic,
        builder: (context, value, child) => CustomPaint(
          painter: _ScoreRingPainter(
            fraction: target == null ? null : value,
            colors: colors,
            track: p.track,
            strokeWidth: strokeWidth,
            glow: glow ? (p.isDark ? 0.45 : 0.25) : 0,
          ),
          child: child,
        ),
        child: child == null ? null : Center(child: child),
      ),
    );
  }
}

class _ScoreRingPainter extends CustomPainter {
  _ScoreRingPainter({
    required this.fraction,
    required this.colors,
    required this.track,
    required this.strokeWidth,
    required this.glow,
  });

  final double? fraction;
  final List<Color> colors;
  final Color track;
  final double strokeWidth;

  /// Opacity of the halo, 0 for none.
  final double glow;

  @override
  void paint(Canvas canvas, Size size) {
    final radius = (math.min(size.width, size.height) - strokeWidth) / 2;
    final center = size.center(Offset.zero);
    final rect = Rect.fromCircle(center: center, radius: radius);
    Paint ring() => Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(rect, 0, 2 * math.pi, false, ring()..color = track);
    final value = fraction;
    if (value == null || value <= 0) return;
    final sweep = 2 * math.pi * value;
    const top = -math.pi / 2;

    if (glow > 0) {
      canvas.drawArc(
        rect,
        top,
        sweep,
        false,
        ring()
          ..strokeWidth = strokeWidth * 1.6
          ..color = colors.last.withValues(alpha: glow * value)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, strokeWidth),
      );
    }

    final paint = ring();
    if (colors.length > 1) {
      // Start the gradient a little before the top so the rounded cap at
      // the start keeps the first colour.
      final cap = strokeWidth / 2 / radius;
      paint.shader = SweepGradient(
        endAngle: math.min(2 * math.pi, sweep + 2 * cap),
        colors: colors,
        transform: GradientRotation(top - cap),
      ).createShader(rect);
    } else {
      paint.color = colors.first;
    }
    canvas.drawArc(rect, top, sweep, false, paint);
  }

  @override
  bool shouldRepaint(_ScoreRingPainter old) =>
      old.fraction != fraction ||
      old.colors != colors ||
      old.track != track ||
      old.strokeWidth != strokeWidth ||
      old.glow != glow;
}
