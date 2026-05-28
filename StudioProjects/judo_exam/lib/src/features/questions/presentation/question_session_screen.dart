import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../study/application/study_progress_controller.dart';
import '../application/question_providers.dart';
import '../domain/question.dart';

class QuestionSessionScreen extends ConsumerStatefulWidget {
  const QuestionSessionScreen({super.key, this.initialQuestionIndex = 0});

  final int initialQuestionIndex;

  @override
  ConsumerState<QuestionSessionScreen> createState() => _QuestionSessionScreenState();
}

class _QuestionSessionScreenState extends ConsumerState<QuestionSessionScreen> {
  late int _currentQuestionIndex;
  int? _selectedChoiceIndex;

  @override
  void initState() {
    super.initState();
    _currentQuestionIndex = widget.initialQuestionIndex;
  }

  @override
  Widget build(BuildContext context) {
    final questions = ref.watch(questionsProvider);

    return questions.when(
      data: (items) {
        if (items.isEmpty) {
          return const Scaffold(body: Center(child: Text('問題がありません')));
        }

        final safeIndex = _currentQuestionIndex.clamp(0, items.length - 1).toInt();
        final question = items[safeIndex];
        final progress = ref.watch(studyProgressControllerProvider).value;
        final isFavorite = progress?.isFavorite(question.id) ?? false;

        return Scaffold(
          appBar: AppBar(
            title: Text('問題 ${safeIndex + 1}/${items.length}'),
            actions: [
              IconButton(
                onPressed: () => ref
                    .read(studyProgressControllerProvider.notifier)
                    .toggleFavorite(question.id),
                icon: Icon(isFavorite ? Icons.star : Icons.star_outline),
                tooltip: isFavorite ? 'お気に入り解除' : 'お気に入り登録',
              ),
            ],
          ),
          body: _QuestionBody(
            question: question,
            selectedChoiceIndex: _selectedChoiceIndex,
            onSelectChoice: (choiceIndex) => _selectChoice(question, choiceIndex),
            onNext: safeIndex + 1 < items.length
                ? () => _moveToNextQuestion(safeIndex)
                : null,
          ),
        );
      },
      error: (error, stackTrace) => Scaffold(
        appBar: AppBar(title: const Text('問題')),
        body: Center(child: Text('問題の読み込みに失敗しました: $error')),
      ),
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
    );
  }

  void _selectChoice(Question question, int choiceIndex) {
    if (_selectedChoiceIndex != null) {
      return;
    }

    setState(() => _selectedChoiceIndex = choiceIndex);

    ref.read(studyProgressControllerProvider.notifier).recordAnswer(
          questionId: question.id,
          isCorrect: question.isCorrect(choiceIndex),
        );
  }

  void _moveToNextQuestion(int currentQuestionIndex) {
    setState(() {
      _currentQuestionIndex = currentQuestionIndex + 1;
      _selectedChoiceIndex = null;
    });
  }
}

class _QuestionBody extends StatelessWidget {
  const _QuestionBody({
    required this.question,
    required this.selectedChoiceIndex,
    required this.onSelectChoice,
    required this.onNext,
  });

  final Question question;
  final int? selectedChoiceIndex;
  final ValueChanged<int> onSelectChoice;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    final selectedIndex = selectedChoiceIndex;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(question.category.label, style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              question.questionText,
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
        ),
        const SizedBox(height: 16),
        for (final choice in question.choices.indexed)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _ChoiceButton(
              label: '${choice.$1 + 1}. ${choice.$2}',
              selected: selectedIndex == choice.$1,
              correct: selectedIndex == null ? null : question.isCorrect(choice.$1),
              onPressed: () => onSelectChoice(choice.$1),
            ),
          ),
        if (selectedIndex != null) ...[
          const SizedBox(height: 8),
          _AnswerResultCard(
            isCorrect: question.isCorrect(selectedIndex),
            explanation: question.explanation,
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onNext,
            icon: Icon(onNext == null ? Icons.check : Icons.arrow_forward),
            label: Text(onNext == null ? '最後の問題です' : '次の問題へ'),
          ),
        ],
      ],
    );
  }
}

class _ChoiceButton extends StatelessWidget {
  const _ChoiceButton({
    required this.label,
    required this.selected,
    required this.correct,
    required this.onPressed,
  });

  final String label;
  final bool selected;
  final bool? correct;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final answerCorrect = correct;
    final foregroundColor = answerCorrect == null
        ? null
        : answerCorrect
            ? colorScheme.primary
            : colorScheme.error;

    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        foregroundColor: selected ? foregroundColor : null,
        side: selected && foregroundColor != null ? BorderSide(color: foregroundColor) : null,
        padding: const EdgeInsets.all(16),
      ),
      onPressed: onPressed,
      child: Align(alignment: Alignment.centerLeft, child: Text(label)),
    );
  }
}

class _AnswerResultCard extends StatelessWidget {
  const _AnswerResultCard({required this.isCorrect, required this.explanation});

  final bool isCorrect;
  final String explanation;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      color: isCorrect ? colorScheme.primaryContainer : colorScheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isCorrect ? '正解です' : '不正解です',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: isCorrect
                        ? colorScheme.onPrimaryContainer
                        : colorScheme.onErrorContainer,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text('解説: $explanation'),
          ],
        ),
      ),
    );
  }
}
