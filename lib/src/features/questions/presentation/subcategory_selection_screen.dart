import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../settings/application/settings_providers.dart';
import '../domain/question.dart';
import '../domain/question_category.dart';
import '../domain/question_subcategory.dart';
import 'question_exam_screen.dart';

typedef QuestionShuffler = List<Question> Function(List<Question> questions);

List<Question> _shuffleQuestions(List<Question> questions) =>
    List<Question>.of(questions)..shuffle();

class SubcategorySelectionScreen extends ConsumerWidget {
  const SubcategorySelectionScreen({
    super.key,
    required this.category,
    required this.questions,
    required this.subcategories,
    this.questionShuffler = _shuffleQuestions,
  });

  final QuestionCategory category;
  final List<Question> questions;
  final List<QuestionSubcategory> subcategories;
  final QuestionShuffler questionShuffler;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final learning = ref.watch(learningDataControllerProvider);
    final categoryQuestions = questions
        .where((question) => question.category == category)
        .toList(growable: false);

    return Scaffold(
      appBar: AppBar(title: Text(category.label)),
      body: SafeArea(
        child: ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: subcategories.length + 1,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            if (index == 0) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('項目を選択', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 6),
                    Text('学習する項目を選んで、問題演習を始めましょう。', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                  ],
                ),
              );
            }

            final subcategory = subcategories[index - 1];
            final filtered = categoryQuestions
                .where((question) => question.subcategory == subcategory.label)
                .toList(growable: false);
            final questionIds = filtered.map((question) => question.id).toSet();
            final learnedIds = learning.history
                .where((entry) => questionIds.contains(entry.questionId))
                .map((entry) => entry.questionId)
                .toSet();
            final progress = filtered.isEmpty ? 0.0 : learnedIds.length / filtered.length;

            return _SubcategoryCard(
              subcategory: subcategory,
              questionCount: filtered.length,
              learnedCount: learnedIds.length,
              progress: progress,
              onTap: () {
                final shuffled = questionShuffler(filtered);
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => QuestionExamScreen(
                      questions: shuffled,
                      title: subcategory.label,
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _SubcategoryCard extends StatelessWidget {
  const _SubcategoryCard({required this.subcategory, required this.questionCount, required this.learnedCount, required this.progress, required this.onTap});

  final QuestionSubcategory subcategory;
  final int questionCount;
  final int learnedCount;
  final double progress;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final percentage = (progress * 100).round();
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(color: colors.primaryContainer, borderRadius: BorderRadius.circular(14)),
                child: Icon(subcategory.icon, color: colors.onPrimaryContainer),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(subcategory.label, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 4),
                    Text('$questionCount問  ・  学習進捗 $learnedCount / $questionCount', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant)),
                    const SizedBox(height: 10),
                    Row(children: [
                      Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(99), child: LinearProgressIndicator(value: progress, minHeight: 7))),
                      const SizedBox(width: 10),
                      SizedBox(width: 38, child: Text('$percentage%', textAlign: TextAlign.right, style: Theme.of(context).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700))),
                    ]),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Icon(Icons.chevron_right_rounded, color: colors.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}
