import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../services/google_sheet_service.dart';
import '../domain/question.dart';
import '../domain/question_category.dart';

final questionsProvider = FutureProvider<List<Question>>((ref) async {
  final service = ref.watch(googleSheetServiceProvider);
  return service.loadQuestions();
});

final freeQuestionCountProvider = Provider<AsyncValue<int>>((ref) {
  return ref.watch(questionsProvider).whenData(
        (questions) => questions.where((question) => !question.isPremium).length,
      );
});

final selectedQuestionCategoryProvider = StateProvider<QuestionCategory?>((ref) => null);

final randomQuestionModeProvider = StateProvider<bool>((ref) => false);

final randomQuestionsProvider = Provider<AsyncValue<List<Question>>>((ref) {
  return ref.watch(questionsProvider).whenData((questions) {
    final shuffled = List<Question>.of(questions)..shuffle(Random());
    for (var i = 1; i < shuffled.length; i++) {
      if (shuffled[i].id == shuffled[i - 1].id && i + 1 < shuffled.length) {
        final current = shuffled[i];
        shuffled[i] = shuffled[i + 1];
        shuffled[i + 1] = current;
      }
    }
    return List<Question>.unmodifiable(shuffled);
  });
});
