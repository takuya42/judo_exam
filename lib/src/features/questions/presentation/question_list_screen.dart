import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../settings/application/settings_providers.dart';
import '../application/question_providers.dart';
import '../domain/question.dart';
import '../domain/question_category.dart';

class QuestionListScreen extends ConsumerWidget {
  const QuestionListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final questionsAsync = ref.watch(questionsProvider);
    final selectedCategory = ref.watch(selectedQuestionCategoryProvider);
    final isRandomMode = ref.watch(randomQuestionModeProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isRandomMode
              ? 'ランダム出題'
              : selectedCategory == null
                  ? '問題一覧'
                  : selectedCategory.label,
        ),
        actions: [
          IconButton(
            tooltip: isRandomMode ? '通常順に戻す' : 'ランダム出題',
            onPressed: () {
              ref.read(selectedQuestionCategoryProvider.notifier).state = null;
              ref.read(randomQuestionModeProvider.notifier).state = !isRandomMode;
            },
            icon: Icon(
              isRandomMode
                  ? Icons.format_list_bulleted_rounded
                  : Icons.shuffle_rounded,
            ),
          ),
          if (selectedCategory != null || isRandomMode)
            TextButton.icon(
              onPressed: () {
                ref.read(selectedQuestionCategoryProvider.notifier).state = null;
                ref.read(randomQuestionModeProvider.notifier).state = false;
              },
              icon: const Icon(Icons.filter_alt_off_rounded),
              label: const Text('全て'),
            ),
        ],
      ),
      body: questionsAsync.when(
        loading: () => const _LoadingQuestions(),
        error: (error, _) => _QuestionLoadError(error: error),
        data: (questions) {
          final sourceQuestions = isRandomMode
              ? ref.watch(randomQuestionsProvider).value ?? questions
              : questions;
          final visibleQuestions = selectedCategory == null
              ? sourceQuestions
              : sourceQuestions
                  .where((question) => question.category == selectedCategory)
                  .toList(growable: false);

          if (visibleQuestions.isEmpty) {
            return _EmptyQuestionList(selectedCategory: selectedCategory);
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: visibleQuestions.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final question = visibleQuestions[index];
              return Card(
                child: ListTile(
                  title: Text(question.questionText),
                  subtitle: Text(
                    '${question.category.label} / '
                    '${question.isPremium ? '有料' : '無料'}',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => showModalBottomSheet<void>(
                    context: context,
                    showDragHandle: true,
                    builder: (context) => QuestionPreview(question: question),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _EmptyQuestionList extends StatelessWidget {
  const _EmptyQuestionList({required this.selectedCategory});

  final QuestionCategory? selectedCategory;

  @override
  Widget build(BuildContext context) {
    final category = selectedCategory;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          category == null
              ? '表示できる問題がありません。'
              : '${category.label}の問題はまだありません。',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

class QuestionPreview extends ConsumerStatefulWidget {
  const QuestionPreview({super.key, required this.question});

  final Question question;

  @override
  ConsumerState<QuestionPreview> createState() => _QuestionPreviewState();
}

class _QuestionPreviewState extends ConsumerState<QuestionPreview> {
  int? _selectedChoiceIndex;

  @override
  Widget build(BuildContext context) {
    final question = widget.question;
    final selectedChoiceIndex = _selectedChoiceIndex;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    question.questionText,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                IconButton(
                  tooltip: ref
                          .watch(learningDataControllerProvider)
                          .isFavorite(question.id)
                      ? 'お気に入り解除'
                      : 'お気に入り登録',
                  onPressed: () => ref
                      .read(learningDataControllerProvider.notifier)
                      .toggleFavorite(question),
                  icon: Icon(
                    ref
                            .watch(learningDataControllerProvider)
                            .isFavorite(question.id)
                        ? Icons.star_rounded
                        : Icons.star_border_rounded,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            for (final entry in question.choices.indexed)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: OutlinedButton(
                  onPressed: selectedChoiceIndex == null
                      ? () {
                          final choiceIndex = entry.$1;
                          setState(() => _selectedChoiceIndex = choiceIndex);
                          ref
                              .read(learningDataControllerProvider.notifier)
                              .recordAnswer(
                                question: question,
                                isCorrect: question.isCorrect(choiceIndex),
                              );
                        }
                      : null,
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

class _LoadingQuestions extends StatelessWidget {
  const _LoadingQuestions();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Google Sheetsから問題を取得しています...'),
        ],
      ),
    );
  }
}

class _QuestionLoadError extends ConsumerWidget {
  const _QuestionLoadError({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 56,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              '問題を取得できませんでした',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text('$error', textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => ref.invalidate(questionsProvider),
              icon: const Icon(Icons.refresh),
              label: const Text('再試行'),
            ),
          ],
        ),
      ),
    );
  }
}
