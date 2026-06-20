import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../services/google_sheet_service.dart';
import '../domain/question.dart';

final questionsProvider = FutureProvider<List<Question>>((ref) async {
  final service = ref.watch(googleSheetServiceProvider);
  return service.loadQuestions();
});
