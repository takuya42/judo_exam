import 'package:flutter_test/flutter_test.dart';
import 'package:judo_exam/src/features/settings/application/settings_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('free answers are unique, persisted, and limited to 20 per day', () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final controller = DailyAnswerLimitController(
      preferences,
      now: () => DateTime(2026, 8, 12, 10),
    );

    for (var index = 0; index < freeDailyAnswerLimit; index++) {
      expect(
        await controller.tryRecordAnswer(questionId: 'q$index', isPremium: false),
        isTrue,
      );
    }
    expect(controller.state.answeredCount, freeDailyAnswerLimit);
    expect(
      await controller.tryRecordAnswer(questionId: 'q0', isPremium: false),
      isTrue,
    );
    expect(controller.state.answeredCount, freeDailyAnswerLimit);
    expect(
      await controller.tryRecordAnswer(questionId: 'q20', isPremium: false),
      isFalse,
    );

    final restored = DailyAnswerLimitController(
      preferences,
      now: () => DateTime(2026, 8, 12, 23),
    );
    expect(restored.state.answeredCount, freeDailyAnswerLimit);
  });

  test('a new local day resets free usage and premium is unlimited', () async {
    SharedPreferences.setMockInitialValues({
      'free_answer_date': '2026-08-11',
      'free_answer_question_ids': List.generate(20, (index) => 'old$index'),
    });
    final preferences = await SharedPreferences.getInstance();
    final controller = DailyAnswerLimitController(
      preferences,
      now: () => DateTime(2026, 8, 12),
    );

    expect(controller.state.answeredCount, 0);
    for (var index = 0; index < 25; index++) {
      expect(
        await controller.tryRecordAnswer(questionId: 'premium$index', isPremium: true),
        isTrue,
      );
    }
    expect(controller.state.answeredCount, 0);
  });

  test('normal and required questions share one 20-answer quota', () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final controller = DailyAnswerLimitController(
      preferences,
      now: () => DateTime(2026, 8, 12),
    );

    for (var index = 0; index < 12; index++) {
      expect(
        await controller.tryRecordAnswer(
          questionId: 'normal_$index',
          isPremium: false,
        ),
        isTrue,
      );
    }
    for (var index = 0; index < 8; index++) {
      expect(
        await controller.tryRecordAnswer(
          questionId: 'required_$index',
          isPremium: false,
        ),
        isTrue,
      );
    }

    expect(controller.state.answeredCount, 20);
    expect(
      await controller.tryRecordAnswer(
        questionId: 'required_9',
        isPremium: false,
      ),
      isFalse,
    );
  });
}
