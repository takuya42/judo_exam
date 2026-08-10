import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:judo_exam/src/features/questions/domain/question.dart';
import 'package:judo_exam/src/features/questions/domain/question_category.dart';
import 'package:judo_exam/src/features/questions/domain/question_subcategory.dart';
import 'package:judo_exam/src/features/questions/presentation/subcategory_selection_screen.dart';
import 'package:judo_exam/src/features/settings/application/settings_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('スプレッドシート行からsubcategoryを読み込む', () {
    final question = Question.fromSheetRow(const [
      'A-1',
      '解剖学',
      '骨格系',
      '問題文',
      '選択肢1',
      '選択肢2',
      '選択肢3',
      '選択肢4',
      '2',
      '解説',
    ]);

    expect(question.category, QuestionCategory.anatomy);
    expect(question.subcategory, '骨格系');
    expect(question.questionText, '問題文');
    expect(question.correctChoiceIndex, 1);
  });

  test('解剖学の項目は指定された順序で全13件ある', () {
    expect(
      anatomySubcategories.map((subcategory) => subcategory.label),
      const [
        '解剖学総論',
        '骨格系',
        '関節・靱帯',
        '筋系',
        '神経系',
        '循環器系',
        'リンパ系',
        '呼吸器系',
        '消化器系',
        '泌尿器系',
        '生殖器系',
        '内分泌系',
        '感覚器',
      ],
    );
  });

  testWidgets(
    '項目を選択すると同じsubcategoryの問題をランダム順で直接開始する',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final preferences = await SharedPreferences.getInstance();
      final questions = [
        _question(id: '1', subcategory: '解剖学総論', text: '解剖学総論の1問目'),
        _question(id: '2', subcategory: '骨格系', text: '骨格系の問題'),
        _question(id: '3', subcategory: '解剖学総論', text: '解剖学総論の2問目'),
      ];
      var shuffleCallCount = 0;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [sharedPreferencesProvider.overrideWithValue(preferences)],
          child: MaterialApp(
            home: SubcategorySelectionScreen(
              category: QuestionCategory.anatomy,
              questions: questions,
              subcategories: [anatomySubcategories.first],
              questionShuffler: (subcategoryQuestions) {
                shuffleCallCount += 1;
                return subcategoryQuestions.reversed.toList();
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('解剖学総論'));
      await tester.pumpAndSettle();

      expect(shuffleCallCount, 1);
      expect(find.text('解剖学総論の2問目'), findsOneWidget);
      expect(find.text('骨格系の問題'), findsNothing);
      expect(find.text('1 / 2'), findsOneWidget);

      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.tap(find.text('解剖学総論'));
      await tester.pumpAndSettle();

      expect(shuffleCallCount, 2);
    },
  );

  testWidgets('問題がない項目では空状態を表示する', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(preferences)],
        child: MaterialApp(
          home: SubcategorySelectionScreen(
            category: QuestionCategory.anatomy,
            questions: const [],
            subcategories: [anatomySubcategories.first],
          ),
        ),
      ),
    );

    await tester.tap(find.text('解剖学総論'));
    await tester.pumpAndSettle();

    expect(find.text('表示できる問題がありません。'), findsOneWidget);
  });
}

Question _question({
  required String id,
  required String subcategory,
  required String text,
}) => Question(
      id: id,
      category: QuestionCategory.anatomy,
      subcategory: subcategory,
      questionText: text,
      choices: const ['選択肢1', '選択肢2', '選択肢3', '選択肢4'],
      correctChoiceIndex: 0,
      explanation: '解説',
      isPremium: false,
    );
