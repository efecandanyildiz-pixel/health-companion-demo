import 'package:flutter/material.dart';

import '../app_state.dart';
import '../models/friend.dart';
import '../ui/app_font.dart';
import '../ui/components.dart';
import '../ui/palette.dart';

/// Appearance, coach and sharing settings, and the user's data.
class YouScreen extends StatelessWidget {
  const YouScreen({super.key});

  static const _themes = [ThemeMode.system, ThemeMode.dark, ThemeMode.light];

  void _say(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _confirmDelete(BuildContext context, AppState app) async {
    final p = context.palette;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Delete everything?',
          style: AppFont.style(size: 20, weight: FontWeight.w800, color: p.ink),
        ),
        content: Text(
          'This removes your daily summaries, coach chats, patterns and '
          'friends settings. The data on your Fitbit Air stays. '
          "This can't be undone.",
          style: AppFont.style(size: 14, height: 1.45, color: p.muted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(backgroundColor: p.dangerFill, foregroundColor: Colors.white),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) app.deleteAllData();
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final p = context.palette;

    Widget sectionTitle(String text) => Text(
          text,
          style: AppFont.style(size: 15, weight: FontWeight.w700, color: p.ink),
        );

    Widget switchRow({
      required String title,
      required String subtitle,
      required bool value,
      required ValueChanged<bool> onChanged,
    }) {
      return MergeSemantics(
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppFont.style(size: 14, color: p.ink)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: AppFont.style(size: 12, color: p.muted)),
                ],
              ),
            ),
            Switch(value: value, onChanged: onChanged),
          ],
        ),
      );
    }

    Widget linkRow(String label, VoidCallback onTap, {Color? color, String? detail, bool last = false}) {
      return InkWell(
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 52),
          decoration: BoxDecoration(
            border: last ? null : Border(bottom: BorderSide(color: p.border)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(text: label),
                      if (detail != null)
                        TextSpan(text: '  ·  $detail', style: AppFont.style(size: 12, color: p.muted)),
                    ],
                  ),
                  style: AppFont.style(
                    size: 14,
                    weight: color == null ? FontWeight.w400 : FontWeight.w600,
                    color: color ?? p.ink,
                  ),
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: color ?? p.muted),
            ],
          ),
        ),
      );
    }

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              children: [
                const Avatar(size: 56),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'You',
                        style: AppFont.style(size: 34, weight: FontWeight.w800, letterSpacing: -1.2, height: 1, color: p.ink),
                      ),
                      const SizedBox(height: 4),
                      Text('Fitbit Air · sample data', style: AppFont.style(size: 13, color: p.muted)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                sectionTitle('Appearance'),
                const SizedBox(height: 12),
                SegmentedSwitch(
                  options: const ['Automatic', 'Dark', 'Light'],
                  selectedIndex: _themes.indexOf(app.themeMode),
                  onChanged: (index) => app.setThemeMode(_themes[index]),
                  semanticLabel: 'Theme',
                ),
                const SizedBox(height: 8),
                Text(
                  "Automatic follows your phone's setting",
                  style: AppFont.style(size: 12, color: p.muted),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                sectionTitle('Coach and reminders'),
                const SizedBox(height: 8),
                switchRow(
                  title: 'Let the coach use my daily summaries',
                  subtitle: 'Sent to Claude only when you ask a question',
                  value: app.coachMayUseData,
                  onChanged: app.setCoachMayUseData,
                ),
                const SizedBox(height: 4),
                switchRow(
                  title: 'Bedtime experiment reminder',
                  subtitle: 'Every night at 00:00',
                  value: app.bedtimeReminder,
                  onChanged: app.setBedtimeReminder,
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                sectionTitle('What friends can see'),
                const SizedBox(height: 4),
                Text(
                  'Friends only see what you turn on.',
                  style: AppFont.style(size: 12, color: p.muted),
                ),
                const SizedBox(height: 8),
                for (final (metric, subtitle) in const [
                  (SharedMetric.steps, 'Your weekly total and leaderboard place'),
                  (SharedMetric.activeMinutes, 'Your active minutes this week'),
                  (SharedMetric.mood, 'One word from your recovery, no numbers'),
                  (SharedMetric.sleep, 'Off by default'),
                ]) ...[
                  switchRow(
                    title: metric.label,
                    subtitle: subtitle,
                    value: app.isSharing(metric),
                    onChanged: (value) => app.setSharing(metric, value),
                  ),
                  if (metric != SharedMetric.sleep) const SizedBox(height: 4),
                ],
              ],
            ),
          ),
          const SizedBox(height: 14),
          AppCard(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                sectionTitle('Your data'),
                const SizedBox(height: 4),
                linkRow(
                  'Export my data',
                  () => _say(context, 'Export arrives once your data is stored on our server.'),
                  detail: 'CSV or JSON',
                ),
                linkRow('Privacy notice', () => showPrivacyNotice(context)),
                linkRow(
                  'Delete all my data',
                  () => _confirmDelete(context, app),
                  color: p.danger,
                  last: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              'Not a medical device. The app explains trends in your own data '
              'and does not diagnose any condition.',
              style: AppFont.style(size: 12, height: 1.45, color: p.faint),
            ),
          ),
        ],
      ),
    );
  }
}
