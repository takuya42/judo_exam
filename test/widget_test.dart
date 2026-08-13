import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:judo_exam/services/google_sheet_service.dart';
import 'package:judo_exam/src/features/questions/domain/question.dart';
import 'package:judo_exam/src/features/questions/domain/question_category.dart';
import 'package:judo_exam/src/features/questions/domain/question_subcategory.dart';
import 'package:judo_exam/src/features/questions/presentation/daily_free_answer_count_card.dart';
import 'package:judo_exam/src/features/questions/presentation/question_list_screen.dart';
import 'package:judo_exam/src/features/questions/presentation/subcategory_selection_screen.dart';
import 'package:judo_exam/src/features/settings/application/settings_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('無料回答数と進捗、上限到達メッセージを表示する', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: DailyFreeAnswerCountCard(answeredCount: 7)),
      ),
    );

    expect(find.text('今日の回答数'), findsOneWidget);
    expect(find.text('7 / 20問'), findsOneWidget);
    expect(
      tester.widget<LinearProgressIndicator>(
        find.byType(LinearProgressIndicator),
      ).value,
      7 / 20,
    );
    expect(find.text('本日の無料回答上限に達しました'), findsNothing);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: DailyFreeAnswerCountCard(answeredCount: 20)),
      ),
    );

    expect(find.text('20 / 20問'), findsOneWidget);
    expect(find.text('本日の無料回答上限に達しました'), findsOneWidget);
  });

  test('通常問題の科目一覧に公衆衛生学を登録する', () {
    expect(
      GoogleSheetService.sheetNames,
      contains(QuestionCategory.publicHealth.label),
    );
    expect(
      Uri.parse(
        GoogleSheetService.publicHealthQuestionsCsvUrl,
      ).queryParameters['gid'],
      '1580177639',
    );
  });

  test('公衆衛生学CSVはヘッダーと空行を除き9列形式で解析する', () {
    final service = GoogleSheetService();

    final questions = service.parsePublicHealthQuestionsCsv(
      '\ufeffid,category,question,choice1,choice2,choice3,choice4,correctAnswer,explanation\n'
      '\n'
      '1,公衆衛生学,公衆衛生の目的として最も適切なのはどれか,1,2,3,4, 2 ,解説\n'
      ',,,,,,,,',
    );

    expect(questions, hasLength(1));
    expect(questions.single.id, '1');
    expect(questions.single.category, QuestionCategory.publicHealth);
    expect(questions.single.subcategory, isEmpty);
    expect(questions.single.questionText, '公衆衛生の目的として最も適切なのはどれか');
    expect(questions.single.correctChoiceIndex, 1);
  });

  test('公衆衛生学CSVのcorrectAnswerは1〜4の整数に限定する', () {
    final service = GoogleSheetService();
    const header =
        'id,category,question,choice1,choice2,choice3,choice4,correctAnswer,explanation';

    expect(
      () => service.parsePublicHealthQuestionsCsv(
        '$header\n1,公衆衛生学,問題,1,2,3,4,correctAnswer,解説',
      ),
      throwsA(
        isA<FormatException>().having(
          (error) => error.message,
          'message',
          allOf(contains('行番号: 2'), contains('answer: correctAnswer')),
        ),
      ),
    );
    expect(
      () => service.parsePublicHealthQuestionsCsv(
        '$header\n1,公衆衛生学,問題,1,2,3,4,0,解説',
      ),
      throwsA(
        isA<FormatException>().having(
          (error) => error.message,
          'message',
          contains('answer は1〜4である必要があります: 0'),
        ),
      ),
    );
  });

  test('通常問題のidとcorrectAnswerは整数相当の小数表記を変換する', () {
    final service = GoogleSheetService();
    const header =
        'id,category,question,choice1,choice2,choice3,choice4,correctAnswer,explanation';

    final questions = service.parsePublicHealthQuestionsCsv(
      '$header\n1.0,公衆衛生学,問題1,1,2,3,4,1,解説\n'
      '2.0,公衆衛生学,問題2,1,2,3,4,4.0,解説',
    );

    expect(questions.map((question) => question.id), ['1', '2']);
    expect(questions.map((question) => question.correctChoiceIndex), [0, 3]);
  });

  test('通常問題のidとcorrectAnswerの非整数・文字列・空文字はエラーにする', () {
    final service = GoogleSheetService();
    const header =
        'id,category,question,choice1,choice2,choice3,choice4,correctAnswer,explanation';

    for (final invalidId in ['1.5', 'abc', '']) {
      expect(
        () => service.parsePublicHealthQuestionsCsv(
          '$header\n$invalidId,公衆衛生学,問題,1,2,3,4,1,解説',
        ),
        throwsFormatException,
        reason: 'id=$invalidId',
      );
    }
    for (final invalidAnswer in ['1.5', 'abc', '']) {
      expect(
        () => service.parsePublicHealthQuestionsCsv(
          '$header\n1,公衆衛生学,問題,1,2,3,4,$invalidAnswer,解説',
        ),
        throwsFormatException,
        reason: 'correctAnswer=$invalidAnswer',
      );
    }
  });

  test('通常問題を各科目のGoogle Visualization形式で読み込む', () async {
    final service = GoogleSheetService(
      client: MockClient((request) async {
        final sheetName = request.url.queryParameters['sheet'] ??
            QuestionCategory.publicHealth.label;
        if (sheetName == QuestionCategory.publicHealth.label) {
          expect(request.url.queryParameters['gid'], '1580177639');
          expect(request.url.queryParameters['tqx'], 'out:csv');
          return http.Response(
            'id,category,question,choice1,choice2,choice3,choice4,correctAnswer,explanation\n'
            '\n'
            '1.0,,公衆衛生学の問題,選択肢1,選択肢2,選択肢3,選択肢4, 4.0 ,解説\n'
            ',,,,,,,,',
            200,
            headers: {'content-type': 'text/csv'},
          );
        }
        final isMigrated = sheetName == '解剖学' || sheetName == '生理学';
        final values = isMigrated
            ? [
                '1.0',
                sheetName,
                sheetName == '生理学' ? '血液・循環' : '骨格系',
                '$sheetNameの問題',
                '選択肢1',
                '選択肢2',
                '選択肢3',
                '選択肢4',
                '4.0',
                '解説',
              ]
            : [
                '1.0',
                sheetName,
                '$sheetNameの問題',
                '選択肢1',
                '選択肢2',
                '選択肢3',
                '選択肢4',
                '4.0',
                '解説',
                'false',
                '2026',
                '旧形式の追加列',
              ];
        final cells = values.map((value) => '{"v":"$value"}').join(',');
        return http.Response(
          'google.visualization.Query.setResponse('
          '{"table":{"rows":[{"c":[$cells]}]}});',
          200,
        );
      }),
    );

    final questions = await service.loadQuestions();
    final physiology = questions.singleWhere(
      (question) => question.category == QuestionCategory.physiology,
    );
    final kinesiology = questions.singleWhere(
      (question) => question.category == QuestionCategory.kinesiology,
    );

    expect(physiology.subcategory, '血液・循環');
    expect(physiology.questionText, '生理学の問題');
    expect(kinesiology.subcategory, isEmpty);
    expect(kinesiology.questionText, '運動学の問題');
    expect(kinesiology.id, '1');
    expect(kinesiology.correctChoiceIndex, 3);
    expect(kinesiology.isPremium, isFalse);
    expect(kinesiology.year, 2026);
    final publicHealth = questions.singleWhere(
      (question) => question.category == QuestionCategory.publicHealth,
    );
    expect(publicHealth.questionText, '公衆衛生学の問題');
    expect(publicHealth.subcategory, isEmpty);
    expect(publicHealth.id, '1');
    expect(publicHealth.correctChoiceIndex, 3);
  });

  test('先行科目が失敗しても公衆衛生学の取得を開始する', () async {
    var requestedPublicHealth = false;
    final service = GoogleSheetService(
      client: MockClient((request) async {
        if (request.url.queryParameters['gid'] == '1580177639') {
          requestedPublicHealth = true;
          return http.Response(
            'id,category,question,choice1,choice2,choice3,choice4,correctAnswer,explanation\n',
            200,
            headers: {'content-type': 'text/csv'},
          );
        }
        return http.Response('sheet error', 500);
      }),
    );

    await expectLater(
      service.loadQuestions(),
      throwsA(isA<GoogleSheetException>()),
    );

    expect(requestedPublicHealth, isTrue);
  });

  test('不正なanswerではシート行番号・id・subcategory・実値を表示する', () async {
    final service = GoogleSheetService(
      client: MockClient((request) async {
        final sheetName = request.url.queryParameters['sheet'];
        if (sheetName == null) {
          return http.Response(
            'id,category,question,choice1,choice2,choice3,choice4,answer,explanation\n',
            200,
          );
        }
        final values = sheetName == '生理学'
            ? [
                '1',
                '生理学',
                '血液・循環',
                '問題文',
                '選択肢1',
                '選択肢2',
                '選択肢3',
                '選択肢4',
                '正解は1',
                '解説',
              ]
            : [
                '1',
                sheetName,
                '問題文',
                '選択肢1',
                '選択肢2',
                '選択肢3',
                '選択肢4',
                '1',
                '解説',
              ];
        final cells = values.map((value) => '{"v":"$value"}').join(',');
        return http.Response(
          'google.visualization.Query.setResponse('
          '{"table":{"rows":[{"c":[$cells]}]}});',
          200,
        );
      }),
    );

    await expectLater(
      service.loadQuestions(),
      throwsA(
        isA<GoogleSheetException>().having(
          (error) => error.message,
          'message',
          allOf(
            contains('行番号: 2'),
            contains('id: 1'),
            contains('subcategory: 血液・循環'),
            contains('answer: 正解は1'),
            contains('answer は数値である必要があります'),
          ),
        ),
      ),
    );
  });

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

  test('スプレッドシート行の追加列から必修問題フラグを読み込む', () {
    final question = Question.fromSheetRow(const [
      'A-REQUIRED',
      '解剖学',
      '骨格系',
      '問題文',
      '選択肢1',
      '選択肢2',
      '選択肢3',
      '選択肢4',
      '2',
      '解説',
      'false',
      '2026',
      'true',
    ]);

    expect(question.isPremium, isFalse);
    expect(question.year, 2026);
    expect(question.isRequired, isTrue);
  });

  test('isRequiredがない既存データは必修問題にしない', () {
    final question = Question.fromJson({
      'id': 'legacy',
      'category': '運動学',
      'question': '問題文',
      'choices': ['1', '2', '3', '4'],
      'answer': 1,
      'explanation': '解説',
      'isPremium': false,
    });

    expect(question.isRequired, isFalse);
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

  test('生理学の項目は指定された順序で全8件ある', () {
    expect(
      physiologySubcategories.map((subcategory) => subcategory.label),
      const [
        '生理学総論',
        '血液・循環',
        '呼吸',
        '消化・代謝',
        '排泄・体温',
        '内分泌・生殖',
        '神経・感覚',
        '筋',
      ],
    );
  });

  test('解剖学と生理学は共通の項目選択画面設定に登録されている', () {
    expect(
      subcategoriesByCategory[QuestionCategory.anatomy],
      anatomySubcategories,
    );
    expect(
      subcategoriesByCategory[QuestionCategory.physiology],
      physiologySubcategories,
    );
  });

  test('生理学のスプレッドシート行からsubcategoryを読み込む', () {
    final question = Question.fromSheetRow(const [
      'P-1',
      '生理学',
      '血液・循環',
      '問題文',
      '選択肢1',
      '選択肢2',
      '選択肢3',
      '選択肢4',
      '1',
      '解説',
    ]);

    expect(question.category, QuestionCategory.physiology);
    expect(question.subcategory, '血液・循環');
  });

  testWidgets('生理学でも選択した項目の問題だけを直接開始する', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final questions = [
      _question(
        id: '1',
        category: QuestionCategory.physiology,
        subcategory: '血液・循環',
        text: '循環の問題',
      ),
      _question(
        id: '2',
        category: QuestionCategory.physiology,
        subcategory: '呼吸',
        text: '呼吸の問題',
      ),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(preferences)],
        child: MaterialApp(
          home: SubcategorySelectionScreen(
            category: QuestionCategory.physiology,
            questions: questions,
            subcategories: [physiologySubcategories[1]],
          ),
        ),
      ),
    );

    expect(find.text('生理学'), findsOneWidget);
    await tester.tap(find.text('血液・循環'));
    await tester.pumpAndSettle();

    expect(find.text('循環の問題'), findsOneWidget);
    expect(find.text('呼吸の問題'), findsNothing);
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

    expect(find.text('0問  ・  学習進捗 0 / 0'), findsOneWidget);
    expect(find.text('0%'), findsOneWidget);

    await tester.tap(find.text('解剖学総論'));
    await tester.pumpAndSettle();

    expect(find.text('表示できる問題がありません。'), findsOneWidget);
  });

  testWidgets('問題一覧で科目と実データ由来のsubcategoryを絞り込める', (tester) async {
    final questions = [
      _question(id: '1', subcategory: '骨格系', text: '骨格系の問題'),
      _question(id: '2', subcategory: '筋系', text: '筋系の問題'),
      _question(
        id: '3',
        category: QuestionCategory.physiology,
        subcategory: '呼吸',
        text: '呼吸の問題',
      ),
      _question(
        id: '4',
        category: QuestionCategory.pathology,
        subcategory: '',
        text: '病理学の問題',
      ),
      _question(
        id: '5',
        category: QuestionCategory.publicHealth,
        subcategory: '',
        text: '公衆衛生学の問題',
      ),
    ];

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(home: QuestionListScreen(questions: questions)),
      ),
    );

    await tester.tap(find.widgetWithText(FilterChip, '解剖学'));
    await tester.pump();

    expect(find.byKey(const ValueKey('subcategory-filter')), findsOneWidget);
    expect(find.widgetWithText(FilterChip, '骨格系'), findsOneWidget);
    expect(find.widgetWithText(FilterChip, '筋系'), findsOneWidget);
    expect(find.widgetWithText(FilterChip, '神経系'), findsNothing);
    expect(find.text('呼吸の問題'), findsNothing);

    await tester.tap(find.widgetWithText(FilterChip, '筋系'));
    await tester.pump();

    expect(find.text('筋系の問題'), findsOneWidget);
    expect(find.text('骨格系の問題'), findsNothing);

    await tester.tap(find.widgetWithText(FilterChip, '病理学'));
    await tester.pump();

    expect(find.byKey(const ValueKey('subcategory-filter')), findsNothing);
    expect(find.text('病理学の問題'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilterChip, '公衆衛生学'));
    await tester.pump();

    expect(find.text('公衆衛生学の問題'), findsOneWidget);
    expect(find.text('病理学の問題'), findsNothing);
  });
}

Question _question({
  required String id,
  required String subcategory,
  required String text,
  QuestionCategory category = QuestionCategory.anatomy,
}) => Question(
      id: id,
      category: category,
      subcategory: subcategory,
      questionText: text,
      choices: const ['選択肢1', '選択肢2', '選択肢3', '選択肢4'],
      correctChoiceIndex: 0,
      explanation: '解説',
      isPremium: false,
    );
