import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../ui/app_font.dart';
import '../../ui/components.dart';
import '../../ui/palette.dart';
import 'consent_screen.dart';

/// First screen a new user sees.
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    Widget feature(IconData icon, CategoryColors colors, String bold, String rest) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(color: colors.soft, borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, size: 18, color: colors.label),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(text: bold, style: AppFont.style(weight: FontWeight.w700, color: p.ink)),
                    TextSpan(text: rest, style: AppFont.style(color: p.muted)),
                  ],
                ),
                style: AppFont.style(size: 15),
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: p.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 40, 24, 28),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: math.max(0, constraints.maxHeight - 68)),
              child: IntrinsicHeight(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Center(child: BeFitWordmark()),
                    const SizedBox(height: 28),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        for (final (colors, fill) in [(p.sleep, 0.7), (p.heart, 0.55), (p.activity, 0.85)])
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 2),
                            child: SizedBox(
                              width: 96,
                              child: ExcludeSemantics(
                                child: _WelcomeArc(colors: colors.gradient, fill: fill, track: p.track),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    Semantics(
                      header: true,
                      child: Text(
                        'Your Fitbit Air,\nfinally explained.',
                        style: AppFont.style(size: 44, weight: FontWeight.w800, letterSpacing: -2, height: 1, color: p.ink),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'See how today compares with your normal, and what in your '
                      'days actually changes your sleep.',
                      style: AppFont.style(size: 16, height: 1.45, color: p.muted),
                    ),
                    const SizedBox(height: 28),
                    feature(Icons.speed_rounded, p.sleep, 'Today vs your usual', ' in one glance'),
                    feature(Icons.insights_rounded, p.heart, 'Patterns', ' found in your own data'),
                    feature(Icons.chat_bubble_outline_rounded, p.activity, 'A coach', ' that shows the numbers it used'),
                    const Spacer(),
                    const SizedBox(height: 20),
                    PrimaryPillButton(
                      label: 'Get started',
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(builder: (_) => const ConsentScreen()),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Center(
                      child: Text(
                        'Made for the Fitbit Air.\n'
                        'Not a medical device.',
                        textAlign: TextAlign.center,
                        style: AppFont.style(size: 12, height: 1.4, color: p.muted),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _WelcomeArc extends StatelessWidget {
  const _WelcomeArc({required this.colors, required this.fill, required this.track});

  final List<Color> colors;
  final double fill;
  final Color track;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 100 / 56,
      child: CustomPaint(painter: _WelcomeArcPainter(colors: colors, fill: fill, track: track)),
    );
  }
}

class _WelcomeArcPainter extends CustomPainter {
  _WelcomeArcPainter({required this.colors, required this.fill, required this.track});

  final List<Color> colors;
  final double fill;
  final Color track;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 100;
    final rect = Rect.fromCircle(center: Offset(50 * s, 50 * s), radius: 40 * s);
    Paint stroke() => Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12 * s
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, math.pi, math.pi, false, stroke()..color = track);
    canvas.drawArc(
      rect,
      math.pi,
      math.pi * fill,
      false,
      stroke()..shader = LinearGradient(colors: colors).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(_WelcomeArcPainter old) => old.fill != fill || old.colors != colors;
}
