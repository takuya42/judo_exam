import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/question_providers.dart';

class QuestionListScreen extends ConsumerWidget {
  const QuestionListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final questions = ref.watch(sampleQuestionsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('問題一覧')),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: questions.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final question = questions[index];
          return Card(
            child: ListTile(
              title: Text(question.questionText),
              subtitle: Text(
                '${question.category.label} / ${question.isPremium ? '有料' : '無料'}',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => showModalBottomSheet<void>(
                context: context,
                showDragHandle: true,
                builder: (context) => _QuestionPreview(questionIndex: index),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _QuestionPreview extends ConsumerStatefulWidget {
  const _QuestionPreview({required this.questionIndex});

  final int questionIndex;

  @override
  ConsumerState<_QuestionPreview> createState() => _QuestionPreviewState();
}

class _QuestionPreviewState extends ConsumerState<_QuestionPreview> {
  int? _selectedChoiceIndex;

  @override
  Widget build(BuildContext context) {
    final question = ref.watch(sampleQuestionsProvider)[widget.questionIndex];
    final selectedChoiceIndex = _selectedChoiceIndex;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              question.questionText,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            for (final entry in question.choices.indexed)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: OutlinedButton(
                  onPressed: () => setState(
                    () => _selectedChoiceIndex = entry.$1,
                  ),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text('${entry.$1 + 1}. ${entry.$2}'),
                  ),
                ),
              ),
            if (selectedChoiceIndex != null) ...[
              const SizedBox(height: 8),
              Text(
                question.isCorrect(selectedChoiceIndex) ? '正解です' : '不正解です',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: question.isCorrect(selectedChoiceIndex)
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.error,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text('解説: ${question.explanation}'),
            ],
          ],
        ),
      ),
    );
  }
}
