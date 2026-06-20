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
