import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../questions/domain/question.dart';
import '../../questions/domain/question_category.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('SharedPreferences must be overridden at startup.');
});

final appSettingsControllerProvider =
    StateNotifierProvider<AppSettingsController, ThemeMode>((ref) {
  return AppSettingsController(ref.watch(sharedPreferencesProvider));
});

class AppSettingsController extends StateNotifier<ThemeMode> {
  AppSettingsController(this._preferences)
      : super(_themeModeFromName(_preferences.getString(_themeModeKey)));

  static const _themeModeKey = 'theme_mode';

  final SharedPreferences _preferences;

  Future<void> setThemeMode(ThemeMode themeMode) async {
    state = themeMode;
    await _preferences.setString(_themeModeKey, themeMode.name);
  }
}

final learningDataControllerProvider =
    StateNotifierProvider<LearningDataController, LearningSummary>((ref) {
  return LearningDataController(ref.watch(sharedPreferencesProvider));
});

const freeDailyAnswerLimit = 20;

final dailyAnswerLimitControllerProvider =
    StateNotifierProvider<DailyAnswerLimitController, DailyAnswerLimitState>((
      ref,
    ) {
  return DailyAnswerLimitController(ref.watch(sharedPreferencesProvider));
});

/// Persists the set of free-plan questions answered on the current local day.
///
/// A set is used deliberately: opening a question never changes this state and
/// answering the same question again does not consume another free answer.
class DailyAnswerLimitController extends StateNotifier<DailyAnswerLimitState> {
  DailyAnswerLimitController(this._preferences, {DateTime Function()? now})
      : _now = now ?? DateTime.now,
        super(_readState(_preferences, (now ?? DateTime.now)())) {
    unawaited(_persist(state));
  }

  static const _dateKey = 'free_answer_date';
  static const _questionIdsKey = 'free_answer_question_ids';

  final SharedPreferences _preferences;
  final DateTime Function() _now;

  /// Returns false without recording when a free user has used today's quota.
  Future<bool> tryRecordAnswer({
    required String questionId,
    required bool isPremium,
  }) async {
    _rollOverIfNeeded();
    if (isPremium) return true;
    if (state.questionIds.contains(questionId)) return true;
    // Counts written by older versions used the raw normal-question ID.
    // Recognize them for the rest of that day without allowing a duplicate.
    if (questionId.startsWith('normal_') &&
        state.questionIds.contains(questionId.substring('normal_'.length))) {
      return true;
    }
    if (state.answeredCount >= freeDailyAnswerLimit) return false;

    state = DailyAnswerLimitState(
      date: state.date,
      questionIds: {...state.questionIds, questionId},
    );
    await _persist(state);
    return true;
  }

  void refreshDate() => _rollOverIfNeeded();

  void _rollOverIfNeeded() {
    final today = _dateString(_now());
    if (state.date == today) return;
    state = DailyAnswerLimitState(date: today);
    unawaited(_persist(state));
  }

  Future<void> _persist(DailyAnswerLimitState value) async {
    await Future.wait([
      _preferences.setString(_dateKey, value.date),
      _preferences.setStringList(_questionIdsKey, value.questionIds.toList()),
    ]);
  }

  static DailyAnswerLimitState _readState(
    SharedPreferences preferences,
    DateTime now,
  ) {
    final today = _dateString(now);
    if (preferences.getString(_dateKey) != today) {
      return DailyAnswerLimitState(date: today);
    }
    return DailyAnswerLimitState(
      date: today,
      questionIds:
          (preferences.getStringList(_questionIdsKey) ?? const <String>[])
              .toSet(),
    );
  }
}

@immutable
class DailyAnswerLimitState {
  const DailyAnswerLimitState({
    required this.date,
    this.questionIds = const <String>{},
  });

  final String date;
  final Set<String> questionIds;
  int get answeredCount => questionIds.length;
}

String _dateString(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-'
    '${date.month.toString().padLeft(2, '0')}-'
    '${date.day.toString().padLeft(2, '0')}';

class LearningDataController extends StateNotifier<LearningSummary> {
  LearningDataController(this._preferences)
      : super(LearningSummary.fromPreferences(_preferences));

  static const _historyKey = 'study_history';
  static const _favoritesKey = 'favorite_questions';

  static const resetKeys = <String>{
    _historyKey,
    _favoritesKey,
    'learned_question_count',
    'correct_rate',
    'correct_streak',
    'category_correct_rates',
  };

  final SharedPreferences _preferences;

  Future<void> recordAnswer({
    required Question question,
    required bool isCorrect,
  }) async {
    final history = [
      StudyHistoryEntry(
        id: '${DateTime.now().microsecondsSinceEpoch}_${question.id}',
        questionId: question.id,
        questionText: question.questionText,
        answeredAt: DateTime.now(),
        isCorrect: isCorrect,
        category: question.category,
        questionType: question.questionType,
      ),
      ...state.history,
    ];
    final next = state.copyWith(
      history: history,
      correctStreak: isCorrect ? state.correctStreak + 1 : 0,
    );
    await _save(next);
  }

  Future<void> toggleFavorite(Question question) async {
    final favorites = [...state.favorites];
    final index = favorites.indexWhere(
      (favorite) => favorite.storageQuestionId == question.storageId ||
          (!question.isRequired && favorite.questionId == question.id),
    );
    if (index == -1) {
      favorites.insert(0, FavoriteQuestion.fromQuestion(question));
    } else {
      favorites.removeAt(index);
    }
    await _save(state.copyWith(favorites: favorites));
  }

  Future<void> resetLearningData() async {
    for (final key in resetKeys) {
      await _preferences.remove(key);
    }
    state = const LearningSummary();
  }

  Future<void> _save(LearningSummary summary) async {
    state = summary;
    await Future.wait([
      _preferences.setStringList(
        _historyKey,
        summary.history.map((entry) => jsonEncode(entry.toJson())).toList(),
      ),
      _preferences.setStringList(
        _favoritesKey,
        summary.favorites.map((favorite) => jsonEncode(favorite.toJson())).toList(),
      ),
    ]);
  }
}

@immutable
class LearningSummary {
  const LearningSummary({
    this.history = const <StudyHistoryEntry>[],
    this.favorites = const <FavoriteQuestion>[],
    this.correctStreak = 0,
  });

  factory LearningSummary.fromPreferences(SharedPreferences preferences) {
    final history = (preferences.getStringList(LearningDataController._historyKey) ?? const <String>[])
        .map(_decodeJson)
        .whereType<Map<String, dynamic>>()
        .map(StudyHistoryEntry.fromJson)
        .toList(growable: false)
      ..sort((a, b) => b.answeredAt.compareTo(a.answeredAt));

    return LearningSummary(
      history: history,
      favorites: (preferences.getStringList(LearningDataController._favoritesKey) ?? const <String>[])
          .map(_decodeJson)
          .whereType<Map<String, dynamic>>()
          .map(FavoriteQuestion.fromJson)
          .toList(growable: false),
      correctStreak: _calculateCurrentStreak(history),
    );
  }

  final List<StudyHistoryEntry> history;
  final List<FavoriteQuestion> favorites;
  final int correctStreak;

  int get learnedQuestionCount => history.length;
  int get answeredCount => history.length;
  int get correctCount => history.where((entry) => entry.isCorrect).length;
  int get correctRate => answeredCount == 0 ? 0 : (correctCount * 100 / answeredCount).round();

  int categoryCorrectRate(QuestionCategory category) {
    final entries = history.where((entry) => entry.category == category).toList(growable: false);
    if (entries.isEmpty) return 0;
    return (entries.where((entry) => entry.isCorrect).length * 100 / entries.length).round();
  }

  bool isFavorite(String questionId) => favorites.any((favorite) => favorite.questionId == questionId);

  bool isFavoriteQuestion(Question question) => favorites.any(
        (favorite) => favorite.storageQuestionId == question.storageId ||
            (!question.isRequired && favorite.questionId == question.id),
      );

  LearningSummary copyWith({
    List<StudyHistoryEntry>? history,
    List<FavoriteQuestion>? favorites,
    int? correctStreak,
  }) {
    return LearningSummary(
      history: history ?? this.history,
      favorites: favorites ?? this.favorites,
      correctStreak: correctStreak ?? this.correctStreak,
    );
  }
}

@immutable
class StudyHistoryEntry {
  const StudyHistoryEntry({
    required this.id,
    required this.questionId,
    required this.questionText,
    required this.answeredAt,
    required this.isCorrect,
    required this.category,
    this.questionType = 'normal',
  });

  factory StudyHistoryEntry.fromJson(Map<String, dynamic> json) => StudyHistoryEntry(
        id: json['id']?.toString() ?? '',
        questionId: json['questionId']?.toString() ?? '',
        questionText: json['questionText']?.toString() ?? '',
        answeredAt: DateTime.tryParse(json['answeredAt']?.toString() ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0),
        isCorrect: json['isCorrect'] == true,
        category: QuestionCategory.fromSheetValue(json['category']?.toString() ?? QuestionCategory.anatomy.name),
        questionType: json['questionType']?.toString() == 'required' ? 'required' : 'normal',
      );

  final String id;
  final String questionId;
  final String questionText;
  final DateTime answeredAt;
  final bool isCorrect;
  final QuestionCategory category;
  final String questionType;
  String get storageQuestionId => questionId.startsWith('${questionType}_')
      ? questionId
      : '${questionType}_$questionId';

  Map<String, dynamic> toJson() => {
        'id': id,
        'questionId': questionId,
        'questionText': questionText,
        'answeredAt': answeredAt.toIso8601String(),
        'isCorrect': isCorrect,
        'category': category.name,
        'questionType': questionType,
      };
}

@immutable
class FavoriteQuestion {
  const FavoriteQuestion({
    required this.questionId,
    required this.questionText,
    required this.category,
    required this.savedAt,
    this.questionType = 'normal',
  });

  factory FavoriteQuestion.fromQuestion(Question question) => FavoriteQuestion(
        questionId: question.storageId,
        questionText: question.questionText,
        category: question.category,
        savedAt: DateTime.now(),
        questionType: question.questionType,
      );

  factory FavoriteQuestion.fromJson(Map<String, dynamic> json) => FavoriteQuestion(
        questionId: json['questionId']?.toString() ?? '',
        questionText: json['questionText']?.toString() ?? '',
        category: QuestionCategory.fromSheetValue(json['category']?.toString() ?? QuestionCategory.anatomy.name),
        savedAt: DateTime.tryParse(json['savedAt']?.toString() ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0),
        questionType: json['questionType']?.toString() == 'required' ? 'required' : 'normal',
      );

  final String questionId;
  final String questionText;
  final QuestionCategory category;
  final DateTime savedAt;
  final String questionType;
  String get storageQuestionId => questionId.startsWith('${questionType}_')
      ? questionId
      : '${questionType}_$questionId';

  Map<String, dynamic> toJson() => {
        'questionId': questionId,
        'questionText': questionText,
        'category': category.name,
        'savedAt': savedAt.toIso8601String(),
        'questionType': questionType,
      };
}

Map<String, dynamic>? _decodeJson(String source) {
  try {
    final decoded = jsonDecode(source);
    return decoded is Map<String, dynamic> ? decoded : null;
  } on FormatException {
    return null;
  }
}

int _calculateCurrentStreak(List<StudyHistoryEntry> history) {
  var streak = 0;
  for (final entry in history) {
    if (!entry.isCorrect) break;
    streak++;
  }
  return streak;
}

ThemeMode _themeModeFromName(String? name) {
  return ThemeMode.values.firstWhere(
    (themeMode) => themeMode.name == name,
    orElse: () => ThemeMode.system,
  );
}
