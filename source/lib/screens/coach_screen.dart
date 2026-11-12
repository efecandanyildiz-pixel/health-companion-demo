import 'package:flutter/material.dart';

import '../app_state.dart';
import '../logic/coach_answers.dart';
import '../logic/formatters.dart';
import '../logic/patterns.dart';
import '../logic/personal_range.dart';
import '../ui/app_font.dart';
import '../ui/charts.dart';
import '../ui/components.dart';
import '../ui/palette.dart';

/// The coach answers only when asked, and shows the numbers it used.
class CoachScreen extends StatefulWidget {
  const CoachScreen({super.key, required this.onOpenPatterns});

  final VoidCallback onOpenPatterns;

  @override
  State<CoachScreen> createState() => _CoachScreenState();
}

class _CoachScreenState extends State<CoachScreen> {
  String? _question;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final p = context.palette;
    final question = _question;
    final answer = question == null ? null : answerCoachQuestion(question, app.days);
    final otherQuestions =
        CoachQuestions.all.where((q) => q != question).toList();

    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4),
                  child: ScreenHeader(eyebrow: 'ONLY WHEN YOU ASK', title: 'Coach'),
                ),
                const SizedBox(height: 20),
                if (!app.coachMayUseData)
                  AppCard(
                    child: Text(
                      'The coach is turned off. Turn on "Let the coach use my '
                      'daily summaries" in the You tab to ask questions.',
                      style: AppFont.style(size: 14, height: 1.4, color: p.ink),
                    ),
                  )
                else if (question == null || answer == null) ...[
                  const _Bubble(
                    text: "Ask about your sleep, recovery or movement. I'll "
                        'answer with your own numbers and show them.',
                  ),
                  const SizedBox(height: 14),
                  _QuestionChips(
                    questions: CoachQuestions.all,
                    onAsk: (q) => setState(() => _question = q),
                  ),
                ] else ...[
                  _Bubble(text: question, fromUser: true),
                  const SizedBox(height: 14),
                  _AnswerCard(answer: answer),
                  const SizedBox(height: 14),
                  _QuestionChips(
                    questions: otherQuestions,
                    onAsk: (q) => setState(() => _question = q),
                    action: question == CoachQuestions.sleepWeek
                        ? ('Start bedtime experiment', widget.onOpenPatterns)
                        : null,
                  ),
                ],
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: TextField(
              enabled: false,
              decoration: InputDecoration(
                hintText: 'Free questions arrive with the AI coach',
                hintStyle: AppFont.style(size: 14, color: p.muted),
                filled: true,
                fillColor: p.surface,
                contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
                disabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide(color: p.border),
                ),
                suffixIcon: Icon(Icons.arrow_upward_rounded, color: p.faint),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.text, this.fromUser = false});

  final String text;
  final bool fromUser;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Align(
      alignment: fromUser ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 320),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: fromUser ? null : p.surface,
            gradient: fromUser ? p.sleep.horizontal : null,
            border: fromUser ? null : Border.all(color: p.border),
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(22),
              topRight: const Radius.circular(22),
              bottomLeft: Radius.circular(fromUser ? 22 : 6),
              bottomRight: Radius.circular(fromUser ? 6 : 22),
            ),
          ),
          child: Text(
            text,
            style: AppFont.style(
              size: 15,
              height: 1.4,
              weight: fromUser ? FontWeight.w600 : FontWeight.w400,
              color: fromUser ? Colors.white : p.ink,
            ),
          ),
        ),
      ),
    );
  }
}

class _AnswerCard extends StatelessWidget {
  const _AnswerCard({required this.answer});

  final CoachAnswer answer;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final p = context.palette;
    final usual = PersonalRange.tryFrom(app.days.skip(1).map((d) => d.sleepMinutes));

    return AppCard(
      raised: true,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(colors: p.brand)),
                child: const Icon(Icons.auto_awesome_rounded, size: 15, color: Colors.white),
              ),
              const SizedBox(width: 10),
              Text(
                'INSIGHT',
                style: AppFont.style(size: 11, weight: FontWeight.w700, letterSpacing: 1.6, color: p.muted),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            answer.title,
            style: AppFont.style(size: 20, weight: FontWeight.w800, letterSpacing: -0.6, height: 1.2, color: p.ink),
          ),
          const SizedBox(height: 8),
          Text(answer.text, style: AppFont.style(size: 15, height: 1.5, color: p.muted)),
          if (answer.chartNights.isNotEmpty && usual != null) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: p.isDark ? p.background : p.background.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  NightBarsChart(
                    height: 70,
                    gap: 7,
                    usualMinutes: usual.median,
                    bars: [
                      for (var i = 0; i < answer.chartNights.length; i++)
                        NightBar(
                          minutes: answer.chartNights[i].sleepMinutes,
                          label: weekdayLetter(answer.chartNights[i].date),
                          striped: isLateNight(answer.chartNights[i]),
                          highlighted: i == answer.chartNights.length - 1,
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  SizedBox(
                    width: double.infinity,
                    child: Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      spacing: 12,
                      runSpacing: 4,
                      children: [
                        Text('striped = in bed after 00:45', style: AppFont.style(size: 11, color: p.muted)),
                        Text('dashed = usual', style: AppFont.style(size: 11, color: p.muted)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (answer.numbersUsed.isNotEmpty) ...[
            const SizedBox(height: 14),
            Divider(height: 1, color: p.border),
            const SizedBox(height: 12),
            Text(
              'NUMBERS USED',
              style: AppFont.style(size: 11, weight: FontWeight.w700, letterSpacing: 1.6, color: p.muted),
            ),
            for (final (label, value) in answer.numbersUsed)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  children: [
                    Expanded(child: Text(label, style: AppFont.style(size: 13, color: p.muted))),
                    Text(value, style: AppFont.style(size: 13, weight: FontWeight.w700, color: p.ink)),
                  ],
                ),
              ),
          ],
          const SizedBox(height: 12),
          Text(
            'Preview: written by fixed rules until the AI coach is connected · '
            'Not medical advice',
            style: AppFont.style(size: 11, color: p.faint),
          ),
        ],
      ),
    );
  }
}

class _QuestionChips extends StatelessWidget {
  const _QuestionChips({required this.questions, required this.onAsk, this.action});

  final List<String> questions;
  final ValueChanged<String> onAsk;

  /// An extra chip that leads somewhere, drawn with the brand gradient.
  final (String, VoidCallback)? action;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        if (action != null)
          Material(
            shape: const StadiumBorder(),
            clipBehavior: Clip.antiAlias,
            child: Ink(
              decoration: BoxDecoration(gradient: LinearGradient(colors: p.brand)),
              child: InkWell(
                onTap: action!.$2,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                  child: Text(
                    action!.$1,
                    style: AppFont.style(size: 13, weight: FontWeight.w700, color: Colors.white),
                  ),
                ),
              ),
            ),
          ),
        for (final question in questions)
          Material(
            color: Colors.transparent,
            shape: StadiumBorder(side: BorderSide(color: p.border)),
            child: InkWell(
              customBorder: const StadiumBorder(),
              onTap: () => onAsk(question),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                child: Text(
                  question,
                  style: AppFont.style(size: 13, weight: FontWeight.w600, color: p.ink),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
