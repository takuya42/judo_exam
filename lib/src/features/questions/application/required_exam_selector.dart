import 'dart:math';

import '../domain/question.dart';
import '../domain/question_category.dart';

const requiredExamQuestionCount = 50;
const requiredExamPassingScore = 40;

/// Builds a balanced, duplicate-free required-question exam.
///
/// One question is drawn from each available subject in rounds before another
/// question is taken from the same subject. The final list is shuffled so the
/// subject rotation is not visible to the learner.
List<Question> selectRequiredExamQuestions(
  List<Question> questions, {
  Random? random,
  int count = requiredExamQuestionCount,
}) {
  final rng = random ?? Random();
  final uniqueQuestions = <String, Question>{};
  for (final question in questions.where((question) => question.isRequired)) {
    uniqueQuestions.putIfAbsent(question.storageId, () => question);
  }

  final buckets = <QuestionCategory, List<Question>>{};
  for (final question in uniqueQuestions.values) {
    buckets.putIfAbsent(question.category, () => <Question>[]).add(question);
  }
  for (final bucket in buckets.values) {
    bucket.shuffle(rng);
  }

  final selected = <Question>[];
  final categories = buckets.keys.toList(growable: false);
  while (selected.length < count) {
    final availableCategories = categories
        .where((category) => buckets[category]!.isNotEmpty)
        .toList(growable: false)
      ..shuffle(rng);
    if (availableCategories.isEmpty) break;

    for (final category in availableCategories) {
      selected.add(buckets[category]!.removeLast());
      if (selected.length == count) break;
    }
  }

  selected.shuffle(rng);
  return List.unmodifiable(selected);
}
