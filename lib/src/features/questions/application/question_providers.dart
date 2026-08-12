import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../services/google_sheet_service.dart';
import '../domain/question.dart';
import '../../settings/application/settings_providers.dart';

final questionsProvider = FutureProvider<List<Question>>((ref) async {
  final service = ref.watch(googleSheetServiceProvider);
  return service.loadQuestions();
});

const _requiredQuestionsCacheKey = 'required_questions_csv_cache';

final requiredQuestionsProvider = FutureProvider<List<Question>>((ref) async {
  final service = ref.watch(googleSheetServiceProvider);
  final preferences = ref.watch(sharedPreferencesProvider);
  try {
    final csv = await service.fetchRequiredQuestionsCsv();
    final questions = service.parseRequiredQuestionsCsv(csv);
    await preferences.setString(_requiredQuestionsCacheKey, csv);
    return questions;
  } on Object {
    final cached = preferences.getString(_requiredQuestionsCacheKey);
    if (cached != null && cached.isNotEmpty) {
      return service.parseRequiredQuestionsCsv(cached);
    }
    rethrow;
  }
});
