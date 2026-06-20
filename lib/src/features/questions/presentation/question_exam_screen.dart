import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../settings/application/settings_providers.dart';
import '../domain/question.dart';

class QuestionExamScreen extends ConsumerStatefulWidget {
  const QuestionExamScreen({
    super.key,
    required this.questions,
    this.title = '問題演習',
  });

  final List<Question> questions;
  final String title;

  @override
  ConsumerState<QuestionExamScreen> createState() => _QuestionExamScreenState();
}

class _QuestionExamScreenState extends ConsumerState<QuestionExamScreen> {
  int _currentIndex = 0;
  int? _selectedChoiceIndex;
  Question? _currentQuestion;

  @override
  void initState() {
    super.initState();
    if (widget.questions.isNotEmpty) {
      _currentQuestion = _shuffledQuestionAt(_currentIndex);
    }
  }

  Question _shuffledQuestionAt(int index) =>
      widget.questions[index].shuffledChoices();

  void _answer(int choiceIndex) {
    if (_selectedChoiceIndex != null) return;

    final question = _currentQuestion;
    if (question == null) return;

    setState(() => _selectedChoiceIndex = choiceIndex);
    ref.read(learningDataControllerProvider.notifier).recordAnswer(
          question: question,
          isCorrect: question.isCorrect(choiceIndex),
        );
  }

  void _nextQuestion() {
    if (_currentIndex + 1 >= widget.questions.length) {
      Navigator.of(context).pop();
      return;
    }

    setState(() {
      _currentIndex += 1;
      _currentQuestion = _shuffledQuestionAt(_currentIndex);
      _selectedChoiceIndex = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final questions = widget.questions;
    if (questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.title)),
        body: const Center(child: Text('表示できる問題がありません。')),
      );
    }

    final question = _currentQuestion!;
    final selectedChoiceIndex = _selectedChoiceIndex;
    final currentNumber = _currentIndex + 1;
    final totalCount = questions.length;
    final progress = currentNumber / totalCount;
    final isFavorite = ref.watch(learningDataControllerProvider).isFavorite(question.id);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(
            tooltip: isFavorite ? 'お気に入り解除' : 'お気に入り登録',
            onPressed: () => ref
                .read(learningDataControllerProvider.notifier)
                .toggleFavorite(question),
            icon: Icon(isFavorite ? Icons.star_rounded : Icons.star_border_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Row(
              children: [
                Text(
                  '第$currentNumber問',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const Spacer(),
                Text(
                  '$currentNumber / $totalCount',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(value: progress, minHeight: 10),
            ),
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  question.questionText,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(height: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 16),
            for (final entry in question.choices.indexed)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _ChoiceButton(
                  number: entry.$1 + 1,
                  label: entry.$2,
                  isSelected: selectedChoiceIndex == entry.$1,
                  isCorrect: question.correctChoiceIndex == entry.$1,
                  hasAnswered: selectedChoiceIndex != null,
                  onPressed: () => _answer(entry.$1),
                ),
              ),
            if (selectedChoiceIndex != null) ...[
              const SizedBox(height: 8),
              _AnswerResultCard(
                isCorrect: question.isCorrect(selectedChoiceIndex),
                correctChoiceNumber: question.correctChoiceIndex + 1,
                correctChoice: question.correctChoice,
                explanation: question.explanation,
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _nextQuestion,
                icon: Icon(
                  currentNumber == totalCount
                      ? Icons.check_rounded
                      : Icons.arrow_forward_rounded,
                ),
                label: Text(currentNumber == totalCount ? '終了' : '次の問題'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ChoiceButton extends StatelessWidget {
  const _ChoiceButton({
    required this.number,
    required this.label,
    required this.isSelected,
    required this.isCorrect,
    required this.hasAnswered,
    required this.onPressed,
  });

  final int number;
  final String label;
  final bool isSelected;
  final bool isCorrect;
  final bool hasAnswered;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final backgroundColor = hasAnswered && isCorrect
        ? colorScheme.primaryContainer
        : hasAnswered && isSelected
            ? colorScheme.errorContainer
            : colorScheme.surface;
    final borderColor = hasAnswered && isCorrect
        ? colorScheme.primary
        : hasAnswered && isSelected
            ? colorScheme.error
            : colorScheme.outlineVariant;

    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        alignment: Alignment.centerLeft,
        backgroundColor: backgroundColor,
        side: BorderSide(color: borderColor, width: 1.5),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      onPressed: hasAnswered ? null : onPressed,
      child: Text('$number. $label'),
    );
  }
}

class _AnswerResultCard extends StatelessWidget {
  const _AnswerResultCard({
    required this.isCorrect,
    required this.correctChoiceNumber,
    required this.correctChoice,
    required this.explanation,
  });

  final bool isCorrect;
  final int correctChoiceNumber;
  final String correctChoice;
  final String explanation;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final resultColor = isCorrect ? colorScheme.primary : colorScheme.error;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isCorrect ? '正解' : '不正解',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: resultColor,
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 10),
            Text('正解: $correctChoiceNumber. $correctChoice'),
            const SizedBox(height: 12),
            Text('解説', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 6),
            Text(explanation),
          ],
        ),
      ),
    );
  }
}
