import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../premium/application/premium_providers.dart';
import '../../settings/application/settings_providers.dart';
import '../application/question_providers.dart';
import '../domain/question.dart';
import '../domain/question_category.dart';
import 'question_exam_screen.dart';

class RequiredQuestionScreen extends ConsumerStatefulWidget {
  const RequiredQuestionScreen({super.key});

  @override
  ConsumerState<RequiredQuestionScreen> createState() =>
      _RequiredQuestionScreenState();
}

class _RequiredQuestionScreenState
    extends ConsumerState<RequiredQuestionScreen> {
  QuestionCategory? _category;

  @override
  Widget build(BuildContext context) {
    final questions = ref.watch(requiredQuestionsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('必修問題')),
      body: questions.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => _RequiredError(
          onRetry: () => ref.invalidate(requiredQuestionsProvider),
        ),
        data: _content,
      ),
    );
  }

  Widget _content(List<Question> questions) {
    if (questions.isEmpty) return const Center(child: Text('必修問題がありません'));
    final categories = questions.map((q) => q.category).toSet().toList();
    final filtered = questions
        .where((q) => _category == null || q.category == _category)
        .toList(growable: false);
    final summary = ref.watch(learningDataControllerProvider);
    final learnedIds = summary.history
        .where((entry) => entry.questionType == 'required')
        .map((entry) => entry.storageQuestionId)
        .toSet();
    final learned = questions.where((q) => learnedIds.contains(q.storageId)).length;
    final progress = learned / questions.length;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('必修問題', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Text('国家試験の必修問題を学習', style: Theme.of(context).textTheme.bodyLarge),
                  const SizedBox(height: 20),
                  Text('学習進捗', style: Theme.of(context).textTheme.labelLarge),
                  const SizedBox(height: 5),
                  Row(children: [
                    Text('$learned / ${questions.length}問', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
                    const Spacer(),
                    Text('${(progress * 100).round()}%'),
                  ]),
                  const SizedBox(height: 10),
                  ClipRRect(borderRadius: BorderRadius.circular(99), child: LinearProgressIndicator(value: progress, minHeight: 8)),
                ],
              ),
            ),
          ),
        ),
        SizedBox(
          height: 44,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: categories.length + 1,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (_, index) {
              final category = index == 0 ? null : categories[index - 1];
              final selected = category == _category;
              return FilterChip(
                label: Text(category?.label ?? 'すべて'),
                selected: selected,
                showCheckmark: false,
                selectedColor: Theme.of(context).colorScheme.primary,
                labelStyle: TextStyle(color: selected ? Theme.of(context).colorScheme.onPrimary : Theme.of(context).colorScheme.onSurface),
                onSelected: (_) => setState(() => _category = category),
              );
            },
          ),
        ),
        if (!ref.watch(isPremiumProvider))
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 6, 20, 2),
            child: Row(children: [
              const Text('本日の回答数'),
              const Spacer(),
              Text('${ref.watch(dailyAnswerLimitControllerProvider).answeredCount} / $freeDailyAnswerLimit問', style: const TextStyle(fontWeight: FontWeight.w700)),
            ]),
          ),
        Expanded(
          child: filtered.isEmpty
              ? const Center(child: Text('必修問題がありません'))
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  itemCount: filtered.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (_, index) => _RequiredQuestionCard(
                    question: filtered[index],
                    onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
                      builder: (_) => QuestionExamScreen(questions: filtered.sublist(index), title: '必修問題'),
                    )),
                  ),
                ),
        ),
      ],
    );
  }
}

class _RequiredQuestionCard extends StatelessWidget {
  const _RequiredQuestionCard({required this.question, required this.onTap});
  final Question question;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(
    margin: EdgeInsets.zero,
    clipBehavior: Clip.antiAlias,
    child: ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      onTap: onTap,
      title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(question.category.label, style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w700)),
        const SizedBox(height: 7),
        Text(question.questionText, maxLines: 2, overflow: TextOverflow.ellipsis),
      ]),
      subtitle: question.subcategory.isEmpty ? null : Padding(padding: const EdgeInsets.only(top: 7), child: Text('# ${question.subcategory}')),
      trailing: const Icon(Icons.chevron_right_rounded),
    ),
  );
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
