import 'dart:math';

import '../domain/question.dart';
import '../domain/question_category.dart';

const requiredExamQuestionCount = 50;
const requiredExamPassingScore = 40;

/// The required-exam distribution mandated for each new 50-question exam.
const Map<QuestionCategory, int> requiredExamSubjectCounts = {
  QuestionCategory.anatomy: 5,
  QuestionCategory.physiology: 5,
  QuestionCategory.kinesiology: 5,
  QuestionCategory.pathology: 5,
  QuestionCategory.publicHealth: 5,
  QuestionCategory.clinicalMedicine: 5,
  QuestionCategory.surgery: 4,
  QuestionCategory.orthopedics: 4,
  QuestionCategory.judoTherapyTheory: 4,
  QuestionCategory.rehabilitationMedicine: 4,
  QuestionCategory.relatedLaws: 4,
};

/// Returns subjects that do not yet contain enough unique questions.
///
/// [questions] must be the contents of the dedicated required-question sheet.
Map<QuestionCategory, int> requiredExamQuestionShortages(
  List<Question> questions,
) {
  final availableIds = <QuestionCategory, Set<String>>{};
  for (final question in questions) {
    availableIds
        .putIfAbsent(question.category, () => <String>{})
        .add(question.storageId);
  }

  return {
    for (final entry in requiredExamSubjectCounts.entries)
      if ((availableIds[entry.key]?.length ?? 0) < entry.value)
        entry.key: entry.value - (availableIds[entry.key]?.length ?? 0),
  };
}

/// Selects the prescribed number of questions from each required-exam subject.
///
/// [questions] must come from the dedicated required-question sheet; the
/// `isRequired` model field is deliberately not used as an extraction
/// condition. Duplicate storage IDs are removed before sampling, then the
/// complete 50-question exam is shuffled so subjects do not appear in blocks.
List<Question> selectRequiredExamQuestions(
  List<Question> questions, {
  Random? random,
}) {
  final rng = random ?? Random();
  final uniqueQuestions = <String, Question>{};
  for (final question in questions) {
    uniqueQuestions.putIfAbsent(question.storageId, () => question);
  }

  final buckets = <QuestionCategory, List<Question>>{};
  for (final question in uniqueQuestions.values) {
    buckets.putIfAbsent(question.category, () => <Question>[]).add(question);
  }

  final shortages = requiredExamQuestionShortages(
    uniqueQuestions.values.toList(growable: false),
  );
  if (shortages.isNotEmpty) {
    final details = shortages.entries
        .map((entry) => '${entry.key.label}: あと${entry.value}問')
        .join('、');
    throw StateError('必修問題の登録数が不足しています（$details）');
  }

  final selected = <Question>[];
  for (final entry in requiredExamSubjectCounts.entries) {
    final candidates = buckets[entry.key]!..shuffle(rng);
    selected.addAll(candidates.take(entry.value));
  }
  selected.shuffle(rng);
  return List.unmodifiable(selected);
}
