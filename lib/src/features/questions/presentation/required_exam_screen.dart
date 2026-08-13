import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/presentation/auth_dialogs.dart';
import '../../premium/application/premium_providers.dart';
import '../../settings/application/settings_providers.dart';
import '../application/required_exam_selector.dart';
import '../domain/question.dart';

class RequiredExamScreen extends ConsumerStatefulWidget {
  const RequiredExamScreen({super.key, required this.questions});

  final List<Question> questions;

  @override
  ConsumerState<RequiredExamScreen> createState() => _RequiredExamScreenState();
}

class _RequiredExamScreenState extends ConsumerState<RequiredExamScreen> {
  int _currentIndex = 0;
  int _correctCount = 0;
  int? _selectedChoiceIndex;
  late Question _currentQuestion;
  bool _isSaving = false;
  bool _isFinished = false;

  @override
  void initState() {
    super.initState();
    _currentQuestion = widget.questions.first.shuffledChoices();
  }

  Future<void> _answer(int choiceIndex) async {
    if (_selectedChoiceIndex != null || _isSaving) return;
    _isSaving = true;
    try {
      final isPremium = ref.read(isPremiumProvider);
      if (!isPremium) {
        if (mounted) await showRequiredExamPremiumDialog(context);
        return;
      }

      if (!mounted) return;
      final isCorrect = _currentQuestion.isCorrect(choiceIndex);
      setState(() {
        _selectedChoiceIndex = choiceIndex;
        if (isCorrect) _correctCount++;
      });
      await ref
          .read(learningDataControllerProvider.notifier)
          .recordRequiredExamAnswer(
            question: _currentQuestion,
            isCorrect: isCorrect,
            isPremium: isPremium,
          );
    } finally {
      _isSaving = false;
    }
  }

  void _next() {
    if (_currentIndex + 1 == widget.questions.length) {
      setState(() => _isFinished = true);
      return;
    }
    setState(() {
      _currentIndex++;
      _currentQuestion = widget.questions[_currentIndex].shuffledChoices();
      _selectedChoiceIndex = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Guard the destination itself as well as the landing-page button. This
    // also reacts if the account loses premium status while the exam is open.
    if (!ref.watch(isPremiumProvider)) {
      return Scaffold(
        appBar: AppBar(title: const Text('必修問題')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.lock_rounded, size: 56),
                const SizedBox(height: 16),
                Text(
                  '必修問題はプレミアム限定です',
                  style: Theme.of(context).textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: () => showRequiredExamPremiumDialog(context),
                  child: const Text('プレミアムプランを見る'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_isFinished) {
      return _RequiredExamResult(correctCount: _correctCount, totalCount: widget.questions.length);
    }

    final choiceIndex = _selectedChoiceIndex;
    final currentNumber = _currentIndex + 1;
    final totalCount = widget.questions.length;
    return Scaffold(
      appBar: AppBar(title: const Text('必修問題')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Row(children: [
              Text('第$currentNumber問', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
              const Spacer(),
              Text('$currentNumber / $totalCount', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            ]),
            const SizedBox(height: 12),
            ClipRRect(borderRadius: BorderRadius.circular(99), child: LinearProgressIndicator(value: currentNumber / totalCount, minHeight: 10)),
            const SizedBox(height: 24),
            Card(child: Padding(
              padding: const EdgeInsets.all(20),
              child: Text(_currentQuestion.questionText, style: Theme.of(context).textTheme.titleLarge?.copyWith(height: 1.5)),
            )),
            const SizedBox(height: 16),
            for (final entry in _currentQuestion.choices.indexed)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _ExamChoiceButton(
                  number: entry.$1 + 1,
                  label: entry.$2,
                  isSelected: choiceIndex == entry.$1,
                  isCorrect: _currentQuestion.correctChoiceIndex == entry.$1,
                  hasAnswered: choiceIndex != null,
                  onPressed: () => _answer(entry.$1),
                ),
              ),
            if (choiceIndex != null) ...[
              const SizedBox(height: 8),
              _AnswerFeedback(question: _currentQuestion, selectedChoiceIndex: choiceIndex),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _next,
                icon: Icon(currentNumber == totalCount ? Icons.check_rounded : Icons.arrow_forward_rounded),
                label: Text(currentNumber == totalCount ? '結果を見る' : '次の問題'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ExamChoiceButton extends StatelessWidget {
  const _ExamChoiceButton({required this.number, required this.label, required this.isSelected, required this.isCorrect, required this.hasAnswered, required this.onPressed});
  final int number;
  final String label;
  final bool isSelected;
  final bool isCorrect;
  final bool hasAnswered;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final background = hasAnswered && isCorrect ? colors.primaryContainer : hasAnswered && isSelected ? colors.errorContainer : colors.surface;
    final border = hasAnswered && isCorrect ? colors.primary : hasAnswered && isSelected ? colors.error : colors.outlineVariant;
    return OutlinedButton(
      style: OutlinedButton.styleFrom(alignment: Alignment.centerLeft, backgroundColor: background, side: BorderSide(color: border, width: 1.5), padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16)),
      onPressed: hasAnswered ? null : onPressed,
      child: Text('$number. $label'),
    );
  }
}

class _AnswerFeedback extends StatelessWidget {
  const _AnswerFeedback({required this.question, required this.selectedChoiceIndex});
  final Question question;
  final int selectedChoiceIndex;

  @override
  Widget build(BuildContext context) {
    final isCorrect = question.isCorrect(selectedChoiceIndex);
    final color = isCorrect ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.error;
    return Card(child: Padding(
      padding: const EdgeInsets.all(18),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(isCorrect ? '正解' : '不正解', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: color, fontWeight: FontWeight.w800)),
        const SizedBox(height: 10),
        Text('正解: ${question.correctChoiceIndex + 1}. ${question.correctChoice}'),
        const SizedBox(height: 12),
        Text('解説', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 6),
        Text(question.explanation),
      ]),
    ));
  }
}

class _RequiredExamResult extends StatelessWidget {
  const _RequiredExamResult({required this.correctCount, required this.totalCount});
  final int correctCount;
  final int totalCount;

  @override
  Widget build(BuildContext context) {
    final passed = correctCount >= requiredExamPassingScore;
    final incorrectCount = totalCount - correctCount;
    final percentage = correctCount / totalCount * 100;
    final colors = Theme.of(context).colorScheme;
    final resultColor = passed ? colors.primary : colors.error;
    return Scaffold(
      appBar: AppBar(title: const Text('試験結果'), automaticallyImplyLeading: false),
      body: SafeArea(child: Center(child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 520), child: Column(children: [
          Container(
            width: 92,
            height: 92,
            decoration: BoxDecoration(color: resultColor.withValues(alpha: 0.12), shape: BoxShape.circle),
            child: Icon(passed ? Icons.emoji_events_rounded : Icons.refresh_rounded, size: 50, color: resultColor),
          ),
          const SizedBox(height: 20),
          Text(passed ? '合格' : '不合格', style: Theme.of(context).textTheme.displaySmall?.copyWith(color: resultColor, fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          Text(passed ? 'おめでとうございます！' : 'もう一度挑戦してみましょう', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 30),
          Card(child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(children: [
              _ResultRow(label: '正解数', value: '$correctCount問'),
              const SizedBox(height: 18),
              _ResultRow(label: '不正解数', value: '$incorrectCount問'),
              const SizedBox(height: 18),
              _ResultRow(label: '正答率', value: '${percentage.toStringAsFixed(0)}%'),
            ]),
          )),
          const SizedBox(height: 28),
          SizedBox(width: double.infinity, height: 54, child: FilledButton.icon(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.home_rounded),
            label: const Text('必修問題トップへ'),
          )),
        ])),
      ))),
    );
  }
}

class _ResultRow extends StatelessWidget {
  const _ResultRow({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Row(children: [
    Text(label, style: Theme.of(context).textTheme.titleMedium),
    const Spacer(),
    Text(value, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
  ]);
}
