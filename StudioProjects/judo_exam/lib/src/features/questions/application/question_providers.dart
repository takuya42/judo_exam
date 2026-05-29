import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/question_csv_loader.dart';
import '../domain/question.dart';
import '../domain/question_category.dart';

final questionCsvLoaderProvider = Provider<QuestionCsvLoader>((ref) {
  return QuestionCsvLoader();
});

final questionsProvider = FutureProvider<List<Question>>((ref) {
  return ref.watch(questionCsvLoaderProvider).loadQuestions();
});

final selectedCategoryProvider = StateProvider<QuestionCategory?>((ref) => null);

final filteredQuestionsProvider = Provider<AsyncValue<List<Question>>>((ref) {
  final selectedCategory = ref.watch(selectedCategoryProvider);

  return ref.watch(questionsProvider).whenData((questions) {
    if (selectedCategory == null) {
      return questions;
    }

    return questions
        .where((question) => question.category == selectedCategory)
        .toList(growable: false);
  });
});

final questionByIdProvider = Provider.family<AsyncValue<Question?>, String>((ref, id) {
  final questions = ref.watch(questionsProvider);

  return questions.whenData((items) {
    for (final question in items) {
      if (question.id == id) {
        return question;
      }
    }
    return null;
  });
});

final freeQuestionCountProvider = Provider<AsyncValue<int>>((ref) {
  return ref.watch(questionsProvider).whenData(
        (questions) => min(30, questions.length),
      );
});

List<Question> pickRandomQuestions(List<Question> questions, int count) {
  final shuffled = List<Question>.of(questions)..shuffle(Random());
  return shuffled.take(min(count, shuffled.length)).toList(growable: false);
}
