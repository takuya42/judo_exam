import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:judo_exam/src/features/premium/application/premium_providers.dart';
import 'package:judo_exam/src/features/questions/application/question_providers.dart';
import 'package:judo_exam/src/features/questions/application/required_exam_selector.dart';
import 'package:judo_exam/src/features/questions/domain/question.dart';
import 'package:judo_exam/src/features/questions/presentation/required_exam_screen.dart';
import 'package:judo_exam/src/features/questions/presentation/required_question_screen.dart';
import 'package:judo_exam/src/features/settings/application/settings_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final questions = <Question>[
    for (final entry in requiredExamSubjectCounts.entries)
      for (var index = 0; index < entry.value; index++)
        Question(
          id: '${entry.key.name}_$index',
          category: entry.key,
          questionText: '必修問題 ${entry.key.name} $index',
          choices: const ['1', '2', '3', '4'],
          correctChoiceIndex: 0,
          explanation: '解説',
          isPremium: false,
          isRequired: true,
        ),
  ];

  Widget app({required bool isPremium, required Widget home}) => ProviderScope(
        overrides: [isPremiumProvider.overrideWithValue(isPremium)],
        child: MaterialApp(home: home),
      );

  testWidgets('無料ユーザーは開始ボタンから必修問題を開始できない', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          isPremiumProvider.overrideWithValue(false),
          requiredQuestionsProvider.overrideWith((ref) async => questions),
        ],
        child: const MaterialApp(home: RequiredQuestionScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('必修問題を開始'));
    await tester.pumpAndSettle();

    expect(find.text('必修問題はプレミアム限定'), findsOneWidget);
    expect(find.text('プレミアムなら必修問題50問に挑戦できます'), findsOneWidget);
    expect(find.byIcon(Icons.workspace_premium_rounded), findsOneWidget);
    expect(find.byIcon(Icons.close_rounded), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'プレミアムプランを見る'), findsOneWidget);
    expect(find.text('1 / 50'), findsNothing);
  });

  testWidgets('プレミアムユーザーは50問の必修問題を開始できる', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          isPremiumProvider.overrideWithValue(true),
          requiredQuestionsProvider.overrideWith((ref) async => questions),
        ],
        child: const MaterialApp(home: RequiredQuestionScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('必修問題を開始'));
    await tester.pumpAndSettle();

    expect(find.text('1 / 50'), findsOneWidget);
    expect(find.byType(RequiredExamScreen), findsOneWidget);
  });

  testWidgets('無料ユーザーが回答画面へ直接遷移しても回答できない', (tester) async {
    await tester.pumpWidget(
      app(isPremium: false, home: RequiredExamScreen(questions: questions)),
    );

    expect(find.text('必修問題はプレミアム限定です'), findsOneWidget);
    expect(find.text(questions.first.questionText), findsNothing);
    expect(find.byType(OutlinedButton), findsNothing);
  });

  test('回答保存側で無料ユーザーの必修回答を拒否する', () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final controller = LearningDataController(preferences);

    final saved = await controller.recordRequiredExamAnswer(
      question: questions.first,
      isCorrect: true,
      isPremium: false,
    );

    expect(saved, isFalse);
    expect(controller.state.history, isEmpty);
  });
}
