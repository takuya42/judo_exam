import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

class LearningDataController extends StateNotifier<LearningSummary> {
  LearningDataController(this._preferences)
      : super(LearningSummary.fromPreferences(_preferences));

  static const _learnedCountKey = 'learned_question_count';
  static const _correctRateKey = 'correct_rate';
  static const _streakKey = 'correct_streak';
  static const _categoryRatesKey = 'category_correct_rates';
  static const _historyKey = 'study_history';
  static const _favoritesKey = 'favorite_questions';

  static const resetKeys = <String>{
    _learnedCountKey,
    _correctRateKey,
    _streakKey,
    _categoryRatesKey,
    _historyKey,
    _favoritesKey,
  };

  final SharedPreferences _preferences;

  Future<void> resetLearningData() async {
    for (final key in resetKeys) {
      await _preferences.remove(key);
    }
    state = const LearningSummary();
  }
}

@immutable
class LearningSummary {
  const LearningSummary({
    this.learnedQuestionCount = 0,
    this.correctRate = 0,
    this.correctStreak = 0,
  });

  factory LearningSummary.fromPreferences(SharedPreferences preferences) {
    return LearningSummary(
      learnedQuestionCount: preferences.getInt(
            LearningDataController._learnedCountKey,
          ) ??
          0,
      correctRate: preferences.getInt(LearningDataController._correctRateKey) ?? 0,
      correctStreak: preferences.getInt(LearningDataController._streakKey) ?? 0,
    );
  }

  final int learnedQuestionCount;
  final int correctRate;
  final int correctStreak;
}

ThemeMode _themeModeFromName(String? name) {
  return ThemeMode.values.firstWhere(
    (themeMode) => themeMode.name == name,
    orElse: () => ThemeMode.system,
  );
}
