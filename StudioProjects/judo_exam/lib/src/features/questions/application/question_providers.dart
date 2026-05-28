import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/question_csv_loader.dart';
import '../domain/question.dart';

final questionCsvLoaderProvider = Provider<QuestionCsvLoader>((ref) {
  return QuestionCsvLoader();
});

final questionsProvider = FutureProvider<List<Question>>((ref) {
  return ref.watch(questionCsvLoaderProvider).loadQuestions();
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
    (questions) => questions.where((question) => !question.isPremium).length,
  );
});
