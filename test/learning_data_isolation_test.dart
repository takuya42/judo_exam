import 'package:flutter_test/flutter_test.dart';
import 'package:judo_exam/src/features/questions/domain/question.dart';
import 'package:judo_exam/src/features/questions/domain/question_category.dart';
import 'package:judo_exam/src/features/settings/application/settings_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MemoryLearningDataStore implements LearningDataStore {
  final Map<String, LearningSummary> values = {};

  @override
  Future<LearningSummary?> load(String uid) async => values[uid];

  @override
  Future<void> save(String uid, LearningSummary summary) async {
    values[uid] = summary;
  }
}

const question = Question(
  id: '1',
  category: QuestionCategory.anatomy,
  questionText: 'question',
  choices: ['a', 'b', 'c', 'd'],
  correctChoiceIndex: 0,
  explanation: 'explanation',
  isPremium: false,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('learning history follows the Firebase uid across account switches', () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final store = MemoryLearningDataStore();

    final accountA = LearningDataController(
      preferences,
      uid: 'account-a',
      store: store,
    );
    await Future<void>.delayed(Duration.zero);
    for (var index = 0; index < 10; index++) {
      await accountA.recordAnswer(
        question: question,
        isCorrect: index != 9,
        isPremium: false,
      );
    }
    expect(accountA.state.learnedQuestionCount, 10);
    expect(accountA.state.correctRate, 90);
    accountA.dispose();

    final signedOut = LearningDataController(preferences);
    expect(signedOut.state.learnedQuestionCount, 0);
    expect(signedOut.state.correctRate, 0);
    expect(signedOut.state.correctStreak, 0);
    signedOut.dispose();

    final accountB = LearningDataController(
      preferences,
      uid: 'account-b',
      store: store,
    );
    await Future<void>.delayed(Duration.zero);
    expect(accountB.state.learnedQuestionCount, 0);
    expect(accountB.state.correctRate, 0);
    for (var index = 0; index < 5; index++) {
      await accountB.recordAnswer(
        question: question,
        isCorrect: true,
        isPremium: false,
      );
    }
    expect(accountB.state.learnedQuestionCount, 5);
    expect(accountB.state.correctRate, 100);
    accountB.dispose();

    final restoredA = LearningDataController(
      preferences,
      uid: 'account-a',
      store: store,
    );
    await Future<void>.delayed(Duration.zero);
    expect(restoredA.state.learnedQuestionCount, 10);
    expect(restoredA.state.correctRate, 90);
  });

  test('daily answered-question cache is separated by uid', () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final now = () => DateTime(2026, 8, 13);
    final accountA = DailyAnswerLimitController(
      preferences,
      uid: 'account-a',
      now: now,
    );
    await accountA.tryRecordAnswer(questionId: 'normal_1', isPremium: false);

    final accountB = DailyAnswerLimitController(
      preferences,
      uid: 'account-b',
      now: now,
    );
    expect(accountB.state.answeredCount, 0);
  });
}
