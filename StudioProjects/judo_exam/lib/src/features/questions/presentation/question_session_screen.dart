import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../purchase/application/purchase_controller.dart';
import '../../purchase/presentation/purchase_screen.dart';
import '../../study/application/study_progress_controller.dart';
import '../application/question_providers.dart';
import '../domain/question.dart';

class QuestionSessionScreen extends ConsumerWidget {
  const QuestionSessionScreen({
    super.key,
    this.initialQuestionIndex = 0,
    this.sessionQuestions,
    this.title = '問題演習',
    this.showResultOnComplete = false,
    this.recordStudyProgress = true,
  });

  final int initialQuestionIndex;
  final List<Question>? sessionQuestions;
  final String title;
  final bool showResultOnComplete;
  final bool recordStudyProgress;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allQuestions = ref.watch(questionsProvider);

    return allQuestions.when(
      data: (items) {
        final questions = sessionQuestions ?? items;
        return _QuestionSessionView(
          allQuestions: items,
          questions: questions,
          initialQuestionIndex: initialQuestionIndex,
          title: title,
          showResultOnComplete: showResultOnComplete,
          recordStudyProgress: recordStudyProgress,
        );
      },
      error: (error, stackTrace) => Scaffold(
        appBar: AppBar(title: Text(title)),
        body: Center(child: Text('問題の読み込みに失敗しました: $error')),
      ),
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
    );
  }
}

class _QuestionSessionView extends ConsumerStatefulWidget {
  const _QuestionSessionView({
    required this.allQuestions,
    required this.questions,
    required this.initialQuestionIndex,
    required this.title,
    required this.showResultOnComplete,
    required this.recordStudyProgress,
  });

  final List<Question> allQuestions;
  final List<Question> questions;
  final int initialQuestionIndex;
  final String title;
  final bool showResultOnComplete;
  final bool recordStudyProgress;

  @override
  ConsumerState<_QuestionSessionView> createState() => _QuestionSessionViewState();
}

class _QuestionSessionViewState extends ConsumerState<_QuestionSessionView> {
  late int _currentQuestionIndex;
  int? _selectedChoiceIndex;
  final Map<String, bool> _sessionResults = <String, bool>{};

  @override
  void initState() {
    super.initState();
    _currentQuestionIndex = widget.initialQuestionIndex;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.title)),
        body: const Center(child: Text('問題がありません')),
      );
    }

    if (_currentQuestionIndex >= widget.questions.length && widget.showResultOnComplete) {
      return _ExamResultScreen(title: widget.title, results: _sessionResults);
    }

    final safeIndex = _currentQuestionIndex.clamp(0, widget.questions.length - 1).toInt();
    final question = widget.questions[safeIndex];
    final progress = ref.watch(studyProgressControllerProvider).value;
    final isFavorite = progress?.isFavorite(question.id) ?? false;
    final isUnlocked = ref.watch(purchaseControllerProvider).value ?? false;
    final originalQuestionIndex = widget.allQuestions.indexWhere((item) => item.id == question.id);
    final needsPurchase =
        originalQuestionIndex >= PurchaseController.freeQuestionLimit && !isUnlocked;

    if (needsPurchase) {
      return const PurchaseScreen();
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.title} ${safeIndex + 1}/${widget.questions.length}'),
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
        onNext: safeIndex + 1 < widget.questions.length
            ? () => _moveToNextQuestion(safeIndex)
            : _completeSession,
        isLastQuestion: safeIndex + 1 == widget.questions.length,
      ),
    );
  }

  void _selectChoice(Question question, int choiceIndex) {
    if (_selectedChoiceIndex != null) {
      return;
    }

    final isCorrect = question.isCorrect(choiceIndex);
    setState(() {
      _selectedChoiceIndex = choiceIndex;
      _sessionResults[question.id] = isCorrect;
    });

    if (widget.recordStudyProgress) {
      ref.read(studyProgressControllerProvider.notifier).recordAnswer(
            questionId: question.id,
            isCorrect: isCorrect,
          );
    }
  }

  void _moveToNextQuestion(int currentQuestionIndex) {
    setState(() {
      _currentQuestionIndex = currentQuestionIndex + 1;
      _selectedChoiceIndex = null;
    });
  }

  void _completeSession() {
    if (widget.showResultOnComplete) {
      setState(() {
        _currentQuestionIndex = widget.questions.length;
        _selectedChoiceIndex = null;
      });
      return;
    }

    Navigator.of(context).maybePop();
  }
}

class _QuestionBody extends StatelessWidget {
  const _QuestionBody({
    required this.question,
    required this.selectedChoiceIndex,
    required this.onSelectChoice,
    required this.onNext,
    required this.isLastQuestion,
  });

  final Question question;
  final int? selectedChoiceIndex;
  final ValueChanged<int> onSelectChoice;
  final VoidCallback onNext;
  final bool isLastQuestion;

  @override
  Widget build(BuildContext context) {
    final selectedIndex = selectedChoiceIndex;
    final colorScheme = Theme.of(context).colorScheme;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                question.category.label,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: colorScheme.onPrimaryContainer,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                question.questionText,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
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
              onPressed: selectedIndex == null ? () => onSelectChoice(choice.$1) : null,
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
            icon: Icon(isLastQuestion ? Icons.flag : Icons.arrow_forward),
            label: Text(isLastQuestion ? '終了する' : '次の問題へ'),
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
  final VoidCallback? onPressed;

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

class _ExamResultScreen extends StatelessWidget {
  const _ExamResultScreen({required this.title, required this.results});

  final String title;
  final Map<String, bool> results;

  @override
  Widget build(BuildContext context) {
    final correctCount = results.values.where((isCorrect) => isCorrect).length;
    final incorrectCount = results.length - correctCount;
    final accuracy = results.isEmpty ? 0.0 : correctCount / results.length * 100;

    return Scaffold(
      appBar: AppBar(title: Text('$title 結果')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('試験結果', style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 16),
                  _ResultRow(label: '正解数', value: '$correctCount 問'),
                  _ResultRow(label: '不正解数', value: '$incorrectCount 問'),
                  _ResultRow(label: '正答率', value: '${accuracy.toStringAsFixed(1)} %'),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.home_outlined),
                    label: const Text('戻る'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultRow extends StatelessWidget {
  const _ResultRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value, style: Theme.of(context).textTheme.titleMedium),
        ],
      ),
    );
  }
}
