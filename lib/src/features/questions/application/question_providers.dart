import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../services/google_sheet_service.dart';
import '../domain/question.dart';

final questionsProvider = FutureProvider<List<Question>>((ref) async {
  final service = ref.watch(googleSheetServiceProvider);
  return service.loadQuestions();
});

final randomQuestionOrderProvider =
    NotifierProvider<RandomQuestionOrder, String?>(RandomQuestionOrder.new);

/// 全科目の問題を出題ごとに並べ替え、直前の開始問題との重複も避ける。
class RandomQuestionOrder extends Notifier<String?> {
  @override
  String? build() => null;

  List<Question> create(List<Question> questions, {Random? random}) {
    final ordered = List<Question>.of(questions)..shuffle(random);
    if (ordered.length > 1 && ordered.first.storageId == state) {
      final replacementIndex = ordered.indexWhere(
        (question) => question.storageId != state,
        1,
      );
      if (replacementIndex != -1) {
        final first = ordered.first;
        ordered[0] = ordered[replacementIndex];
        ordered[replacementIndex] = first;
      }
    }
    state = ordered.firstOrNull?.storageId;
    return ordered;
  }
}

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
