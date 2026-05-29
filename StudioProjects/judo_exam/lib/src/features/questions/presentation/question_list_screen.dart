import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../purchase/application/purchase_controller.dart';
import '../../purchase/presentation/purchase_screen.dart';
import '../application/question_providers.dart';
import '../domain/question.dart';
import '../domain/question_category.dart';
import 'question_session_screen.dart';

class QuestionListScreen extends ConsumerWidget {
  const QuestionListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final questions = ref.watch(filteredQuestionsProvider);
    final isUnlocked = ref.watch(purchaseControllerProvider).value ?? false;
    final allQuestions = ref.watch(questionsProvider).value;

    return Scaffold(
      appBar: AppBar(title: const Text('問題一覧')),
      body: questions.when(
        data: (items) => ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: items.length + 2,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            if (index == 0) {
              return const _CategoryFilter();
            }

            if (index == 1) {
              return FilledButton.icon(
                onPressed: items.isEmpty ? null : () => _openSession(context, questions: items),
                icon: const Icon(Icons.play_arrow),
                label: const Text('表示中の問題を解く'),
              );
            }

            final questionIndex = index - 2;
            final question = items[questionIndex];
            final originalIndex =
                allQuestions?.indexWhere((item) => item.id == question.id) ?? questionIndex;
            final isLocked = originalIndex >= PurchaseController.freeQuestionLimit && !isUnlocked;

            return Card(
              child: ListTile(
                leading: CircleAvatar(child: Text('${questionIndex + 1}')),
                title: Text(question.questionText),
                subtitle: Text(
                  '${question.category.label} / '
                  '${isLocked ? '購入が必要' : question.isPremium ? '有料' : '無料'}',
                ),
                trailing: Icon(isLocked ? Icons.lock_outline : Icons.chevron_right),
                onTap: () {
                  if (isLocked) {
                    _openPurchase(context);
                    return;
                  }
                  _openSession(
                    context,
                    questions: items,
                    initialQuestionIndex: questionIndex,
                  );
                },
              ),
            );
          },
        ),
        error: (error, stackTrace) => Center(child: Text('問題の読み込みに失敗しました: $error')),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
    );
  }

  void _openSession(
    BuildContext context, {
    required List<Question> questions,
    int initialQuestionIndex = 0,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => QuestionSessionScreen(
          sessionQuestions: questions,
          initialQuestionIndex: initialQuestionIndex,
        ),
      ),
    );
  }

  void _openPurchase(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const PurchaseScreen()),
    );
  }
}

class _CategoryFilter extends ConsumerWidget {
  const _CategoryFilter();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedCategory = ref.watch(selectedCategoryProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('カテゴリで絞り込み', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilterChip(
                  label: const Text('すべて'),
                  selected: selectedCategory == null,
                  onSelected: (_) => ref.read(selectedCategoryProvider.notifier).state = null,
                ),
                for (final category in QuestionCategory.values)
                  FilterChip(
                    label: Text(category.label),
                    selected: selectedCategory == category,
                    onSelected: (_) => ref.read(selectedCategoryProvider.notifier).state = category,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
