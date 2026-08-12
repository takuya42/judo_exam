import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../services/google_sheet_service.dart';
import '../domain/question.dart';

final questionsProvider = FutureProvider<List<Question>>((ref) async {
  final service = ref.watch(googleSheetServiceProvider);
  return service.loadQuestions();
});

final requiredQuestionsProvider = FutureProvider<List<Question>>((ref) async {
  final service = ref.watch(googleSheetServiceProvider);
  try {
    final questions = await service.loadRequiredQuestions();
    debugPrint(
      '[RequiredQuestionsProvider] Providerへ渡す問題数: ${questions.length}',
    );
    return questions;
  } on Object catch (error, stackTrace) {
    debugPrint(
      '[RequiredQuestionsProvider] エラー: $error\nstackTrace: $stackTrace',
    );
    rethrow;
  }
});
