import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/question_providers.dart';
import '../domain/question.dart';
import '../domain/question_category.dart';
import 'question_exam_screen.dart';

class QuestionListScreen extends ConsumerStatefulWidget {
  const QuestionListScreen({super.key, this.questions, this.title = '問題'});

  final List<Question>? questions;
  final String title;

  @override
  ConsumerState<QuestionListScreen> createState() =>
      _QuestionListScreenState();
}

class _QuestionListScreenState extends ConsumerState<QuestionListScreen> {
  QuestionCategory? _selectedCategory;
  String? _selectedSubcategory;

  @override
  Widget build(BuildContext context) {
    final questionsAsync = widget.questions == null
        ? ref.watch(questionsProvider)
        : AsyncValue<List<Question>>.data(widget.questions!);

    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: questionsAsync.when(
        loading: () => const _LoadingQuestions(),
        error: (error, _) => _QuestionLoadError(error: error),
        data: _buildQuestionList,
      ),
    );
  }

  Widget _buildQuestionList(List<Question> questions) {
    if (questions.isEmpty) {
      return const _EmptyQuestionList();
    }

    final subcategories = _selectedCategory?.supportsSubcategories == true
        ? questions
              .where((question) => question.category == _selectedCategory)
              .map((question) => question.subcategory)
              .where((subcategory) => subcategory.isNotEmpty)
              .toSet()
              .toList(growable: false)
        : const <String>[];
    final filteredQuestions = questions.where((question) {
      final matchesCategory =
          _selectedCategory == null || question.category == _selectedCategory;
      final matchesSubcategory =
          _selectedSubcategory == null ||
          question.subcategory == _selectedSubcategory;
      return matchesCategory && matchesSubcategory;
    }).toList(growable: false);

    return Column(
      children: [
        _QuestionFilters(
          selectedCategory: _selectedCategory,
          selectedSubcategory: _selectedSubcategory,
          subcategories: subcategories,
          onCategorySelected: (category) {
            setState(() {
              _selectedCategory = category;
              _selectedSubcategory = null;
            });
          },
          onSubcategorySelected: (subcategory) {
            setState(() => _selectedSubcategory = subcategory);
          },
        ),
        Expanded(
          child: filteredQuestions.isEmpty
              ? const _EmptyQuestionList()
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                  itemCount: filteredQuestions.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final question = filteredQuestions[index];
                    return _QuestionCard(
                      question: question,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => QuestionExamScreen(
                            questions: [question],
                            title: widget.title,
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

extension on QuestionCategory {
  bool get supportsSubcategories =>
      this == QuestionCategory.anatomy || this == QuestionCategory.physiology;
}

class _QuestionFilters extends StatelessWidget {
  const _QuestionFilters({
    required this.selectedCategory,
    required this.selectedSubcategory,
    required this.subcategories,
    required this.onCategorySelected,
    required this.onSubcategorySelected,
  });

  final QuestionCategory? selectedCategory;
  final String? selectedSubcategory;
  final List<String> subcategories;
  final ValueChanged<QuestionCategory?> onCategorySelected;
  final ValueChanged<String?> onSubcategorySelected;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Padding(
        padding: const EdgeInsets.only(top: 8, bottom: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _FilterRow(
              children: [
                _filterChip(
                  context: context,
                  label: 'すべて',
                  selected: selectedCategory == null,
                  onSelected: () => onCategorySelected(null),
                ),
                for (final category in QuestionCategory.values)
                  _filterChip(
                    context: context,
                    label: category.label,
                    selected: selectedCategory == category,
                    onSelected: () => onCategorySelected(category),
                  ),
              ],
            ),
            if (selectedCategory?.supportsSubcategories == true &&
                subcategories.isNotEmpty) ...[
              const SizedBox(height: 4),
              _FilterRow(
                key: const ValueKey('subcategory-filter'),
                children: [
                  _filterChip(
                    context: context,
                    label: 'すべて',
                    selected: selectedSubcategory == null,
                    onSelected: () => onSubcategorySelected(null),
                  ),
                  for (final subcategory in subcategories)
                    _filterChip(
                      context: context,
                      label: subcategory,
                      selected: selectedSubcategory == subcategory,
                      onSelected: () => onSubcategorySelected(subcategory),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _filterChip({
    required BuildContext context,
    required String label,
    required bool selected,
    required VoidCallback onSelected,
  }) {
    final colors = Theme.of(context).colorScheme;
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onSelected(),
      showCheckmark: false,
      selectedColor: colors.primary,
      backgroundColor: colors.surface,
      side: BorderSide(
        color: selected ? colors.primary : colors.outlineVariant,
      ),
      labelStyle: TextStyle(
        color: selected ? colors.onPrimary : colors.onSurfaceVariant,
        fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
      ),
      visualDensity: const VisualDensity(horizontal: -1, vertical: -1),
    );
  }
}

class _FilterRow extends StatelessWidget {
  const _FilterRow({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: children.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (_, index) => children[index],
      ),
    );
  }
}

class _QuestionCard extends StatelessWidget {
  const _QuestionCard({required this.question, required this.onTap});

  final Question question;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Card(
      margin: EdgeInsets.zero,
      elevation: 1,
      shadowColor: Colors.black.withValues(alpha: 0.06),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 10, 11),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    question.category.label,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: colors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: colors.secondaryContainer,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      question.isPremium ? '有料' : '無料',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colors.onSecondaryContainer,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      question.questionText,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        height: 1.45,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: colors.onSurfaceVariant,
                  ),
                ],
              ),
              if (question.subcategory.isNotEmpty) ...[
                const SizedBox(height: 7),
                Text(
                  '# ${question.subcategory}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyQuestionList extends StatelessWidget {
  const _EmptyQuestionList();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text('表示できる問題がありません。', textAlign: TextAlign.center),
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
          Text('読み込み中...'),
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
