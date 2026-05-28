import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/data/shared_preferences_provider.dart';
import '../domain/study_progress.dart';

final studyProgressControllerProvider =
    AsyncNotifierProvider<StudyProgressController, StudyProgress>(
      StudyProgressController.new,
    );

class StudyProgressController extends AsyncNotifier<StudyProgress> {
  static const _wrongQuestionIdsKey = 'wrong_question_ids';
  static const _favoriteQuestionIdsKey = 'favorite_question_ids';
  static const _correctCountKey = 'correct_count';
  static const _incorrectCountKey = 'incorrect_count';

  @override
  Future<StudyProgress> build() async {
    final preferences = await ref.watch(sharedPreferencesProvider.future);
    return StudyProgress(
      wrongQuestionIds: preferences.getStringList(_wrongQuestionIdsKey)?.toSet() ?? <String>{},
      favoriteQuestionIds:
          preferences.getStringList(_favoriteQuestionIdsKey)?.toSet() ?? <String>{},
      correctCount: preferences.getInt(_correctCountKey) ?? 0,
      incorrectCount: preferences.getInt(_incorrectCountKey) ?? 0,
    );
  }

  Future<void> recordAnswer({
    required String questionId,
    required bool isCorrect,
  }) async {
    final current = state.value ?? StudyProgress.initial();
    final wrongQuestionIds = Set<String>.of(current.wrongQuestionIds);

    if (isCorrect) {
      wrongQuestionIds.remove(questionId);
    } else {
      wrongQuestionIds.add(questionId);
    }

    final updated = current.copyWith(
      wrongQuestionIds: wrongQuestionIds,
      correctCount: current.correctCount + (isCorrect ? 1 : 0),
      incorrectCount: current.incorrectCount + (isCorrect ? 0 : 1),
    );

    state = AsyncData(updated);
    await _save(updated);
  }

  Future<void> toggleFavorite(String questionId) async {
    final current = state.value ?? StudyProgress.initial();
    final favoriteQuestionIds = Set<String>.of(current.favoriteQuestionIds);

    if (!favoriteQuestionIds.add(questionId)) {
      favoriteQuestionIds.remove(questionId);
    }

    final updated = current.copyWith(favoriteQuestionIds: favoriteQuestionIds);
    state = AsyncData(updated);
    await _save(updated);
  }

  Future<void> _save(StudyProgress progress) async {
    final preferences = await ref.read(sharedPreferencesProvider.future);
    await Future.wait([
      preferences.setStringList(
        _wrongQuestionIdsKey,
        progress.wrongQuestionIds.toList(growable: false),
      ),
      preferences.setStringList(
        _favoriteQuestionIdsKey,
        progress.favoriteQuestionIds.toList(growable: false),
      ),
      preferences.setInt(_correctCountKey, progress.correctCount),
      preferences.setInt(_incorrectCountKey, progress.incorrectCount),
    ]);
  }
}
