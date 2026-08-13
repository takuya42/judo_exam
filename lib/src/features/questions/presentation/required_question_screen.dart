import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/question_providers.dart';
import '../application/required_exam_selector.dart';
import '../domain/question.dart';
import 'required_exam_screen.dart';

class RequiredQuestionScreen extends ConsumerWidget {
  const RequiredQuestionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final questions = ref.watch(requiredQuestionsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('必修問題')),
      body: questions.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => _RequiredError(
          onRetry: () => ref.invalidate(requiredQuestionsProvider),
        ),
        data: (questions) => _RequiredExamLanding(questions: questions),
      ),
    );
  }
}

class _RequiredExamLanding extends StatelessWidget {
  const _RequiredExamLanding({required this.questions});

  final List<Question> questions;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final shortages = requiredExamQuestionShortages(questions);
    final canStart = shortages.isEmpty;

    return SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Column(
              children: [
                Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.workspace_premium_rounded, size: 40, color: colorScheme.primary),
                ),
                const SizedBox(height: 20),
                Text('必修問題', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w900)),
                const SizedBox(height: 8),
                Text('国家試験の必修問題に挑戦', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: colorScheme.onSurfaceVariant)),
                const SizedBox(height: 32),
                Card(
                  margin: EdgeInsets.zero,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 26),
                    child: Column(
                      children: [
                        _ExamInfoRow(label: '出題数', value: '50問', icon: Icons.description_outlined),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 22),
                          child: Divider(height: 1, color: colorScheme.outlineVariant),
                        ),
                        const _ExamInfoRow(label: '合格ライン', value: '80%以上', detail: '40 / 50問 正解', icon: Icons.check_circle_outline_rounded),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  height: 58,
                  child: FilledButton.icon(
                    onPressed: canStart
                        ? () {
                            final examQuestions = selectRequiredExamQuestions(questions);
                            Navigator.of(context).push(MaterialPageRoute<void>(
                              builder: (_) => RequiredExamScreen(questions: examQuestions),
                            ));
                          }
                        : null,
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: const Text('必修問題を開始', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                  ),
                ),
                if (!canStart) ...[
                  const SizedBox(height: 14),
                  Text(
                    '試験を開始するには各科目の問題登録が必要です。\n'
                    '${shortages.entries.map((entry) => '${entry.key.label} あと${entry.value}問').join('、')}',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: colorScheme.error),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ExamInfoRow extends StatelessWidget {
  const _ExamInfoRow({required this.label, required this.value, required this.icon, this.detail});
  final String label;
  final String value;
  final String? detail;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Row(children: [
    Icon(icon, color: Theme.of(context).colorScheme.primary, size: 28),
    const SizedBox(width: 16),
    Expanded(child: Text(label, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700))),
    Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
      Text(value, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
      if (detail != null) ...[const SizedBox(height: 3), Text(detail!, style: Theme.of(context).textTheme.bodyMedium)],
    ]),
  ]);
}

class _RequiredError extends StatelessWidget {
  const _RequiredError({required this.onRetry});
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => Center(child: Padding(
    padding: const EdgeInsets.all(24),
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(Icons.error_outline, size: 52, color: Theme.of(context).colorScheme.error),
      const SizedBox(height: 16),
      const Text('必修問題を取得できませんでした'),
      const SizedBox(height: 16),
      FilledButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh), label: const Text('再試行')),
    ]),
  ));
}
