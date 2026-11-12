import 'package:flutter/material.dart';

import '../../app_state.dart';
import '../../ui/app_font.dart';
import '../../ui/components.dart';
import '../../ui/palette.dart';

/// Explains exactly what data BeFit uses and what we do with it, and asks
/// for consent. Needed for KVKK explicit consent.
class ConsentScreen extends StatefulWidget {
  const ConsentScreen({super.key});

  @override
  State<ConsentScreen> createState() => _ConsentScreenState();
}

class _ConsentScreenState extends State<ConsentScreen> {
  // Explicit consent must be given actively, so the box starts empty.
  bool _agreed = false;
  bool _showError = false;

  void _continue() {
    if (!_agreed) {
      setState(() => _showError = true);
      return;
    }
    final app = AppScope.of(context);
    Navigator.of(context).popUntil((route) => route.isFirst);
    app.completeOnboarding();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    Widget check(String text, {bool positive = true}) {
      return Padding(
        padding: const EdgeInsets.only(top: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              positive ? Icons.check_rounded : Icons.close_rounded,
              size: 18,
              color: positive ? p.activity.label : p.heart.label,
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(text, style: AppFont.style(size: 14, height: 1.4, color: p.ink))),
          ],
        ),
      );
    }

    Widget dataType(Color color, String text) {
      return Padding(
        padding: const EdgeInsets.only(top: 10),
        child: Row(
          children: [
            Container(width: 10, height: 10, decoration: BoxDecoration(shape: BoxShape.circle, color: color)),
            const SizedBox(width: 12),
            Expanded(child: Text(text, style: AppFont.style(size: 14, color: p.ink))),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: p.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => Navigator.of(context).pop(),
                icon: Icon(Icons.chevron_left_rounded, color: p.muted),
                label: Text('Back', style: AppFont.style(size: 15, weight: FontWeight.w600, color: p.muted)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'YOUR DATA',
                    style: AppFont.style(size: 12, weight: FontWeight.w600, letterSpacing: 2.4, color: p.muted),
                  ),
                  const SizedBox(height: 4),
                  Semantics(
                    header: true,
                    child: Text(
                      'Before you start',
                      style: AppFont.style(size: 34, weight: FontWeight.w800, letterSpacing: -1.3, height: 1.05, color: p.ink),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Health data is sensitive, so here is exactly what we use '
                    'and what we do with it.',
                    style: AppFont.style(size: 14, height: 1.45, color: p.muted),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('What BeFit uses',
                      style: AppFont.style(size: 15, weight: FontWeight.w700, color: p.ink)),
                  dataType(p.sleep.label, 'Sleep: duration, stages, bed and wake times'),
                  dataType(p.heart.label, 'Heart: resting heart rate and HRV'),
                  dataType(p.activity.label, 'Activity: steps and active minutes'),
                  const SizedBox(height: 10),
                  Text('All of it comes from your Fitbit Air. We only read it.',
                      style: AppFont.style(size: 12, color: p.muted)),
                ],
              ),
            ),
            const SizedBox(height: 12),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('What we do with it',
                      style: AppFont.style(size: 15, weight: FontWeight.w700, color: p.ink)),
                  check('Keep daily summaries only, encrypted, never raw sensor data'),
                  check('Send those summaries to our AI coach (Claude, by Anthropic) '
                      'only when you ask it a question'),
                  check('Export or delete everything at any time from the You tab'),
                  check('Never sell your data or use it for ads', positive: false),
                ],
              ),
            ),
            const SizedBox(height: 12),
            AppCard(
              color: p.sleep.soft,
              borderColor: p.sleep.label.withValues(alpha: 0.25),
              padding: const EdgeInsets.all(16),
              child: Text(
                'This app explains trends in your own data. It does not diagnose '
                'or treat any condition. For health concerns, talk to a doctor.',
                style: AppFont.style(size: 13, height: 1.45, color: p.ink),
              ),
            ),
            const SizedBox(height: 14),
            MergeSemantics(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Checkbox(
                    value: _agreed,
                    onChanged: (value) => setState(() {
                      _agreed = value ?? false;
                      if (_agreed) _showError = false;
                    }),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() {
                        _agreed = !_agreed;
                        if (_agreed) _showError = false;
                      }),
                      child: Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Text(
                          'I give explicit consent to processing my health data '
                          'as described, under KVKK.',
                          style: AppFont.style(size: 14, height: 1.4, color: p.ink),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 40),
              child: Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: () => showPrivacyNotice(context),
                  child: Text('Read the privacy notice',
                      style: AppFont.style(size: 14, weight: FontWeight.w600, color: p.sleep.label)),
                ),
              ),
            ),
            if (_showError)
              Padding(
                padding: const EdgeInsets.fromLTRB(48, 0, 8, 8),
                child: Text(
                  'Tick the box to give your consent before continuing.',
                  style: AppFont.style(size: 13, weight: FontWeight.w600, color: p.danger),
                ),
              ),
            const SizedBox(height: 16),
            PrimaryPillButton(label: 'Continue', onPressed: _continue),
            const SizedBox(height: 10),
            Text(
              'You can withdraw your consent any time in the You tab.',
              textAlign: TextAlign.center,
              style: AppFont.style(size: 12, height: 1.4, color: p.muted),
            ),
          ],
        ),
      ),
    );
  }
}
