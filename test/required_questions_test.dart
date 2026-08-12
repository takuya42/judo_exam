import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:judo_exam/services/google_sheet_service.dart';
import 'package:judo_exam/src/features/questions/application/question_providers.dart';
import 'package:judo_exam/src/features/questions/domain/question.dart';
import 'package:judo_exam/src/features/questions/domain/question_category.dart';

void main() {
  const csvHeader =
      'id,category,question,choice1,choice2,choice3,choice4,correctAnswer,explanation';

  test('必修問題は指定された公開CSV URLから取得する', () async {
    late Uri requestedUri;
    final service = GoogleSheetService(
      client: MockClient((request) async {
        requestedUri = request.url;
        return http.Response('$csvHeader\n', 200);
      }),
    );

    await service.loadRequiredQuestions();

    expect(
      requestedUri.toString(),
      GoogleSheetService.requiredQuestionsCsvUrl,
    );
    expect(
      requestedUri.path,
      contains('/spreadsheets/d/${GoogleSheetService.spreadsheetId}/gviz/tq'),
    );
    expect(requestedUri.queryParameters['gid'], '1870506905');
    expect(requestedUri.queryParameters['tqx'], 'out:csv');
  });

  test('ヘッダーと空行を除外し、CSVの必修問題をQuestionとして読み込む', () {
    final service = GoogleSheetService();
    final questions = service.parseRequiredQuestionsCsv('''
$csvHeader

R-1,解剖学,"カンマ,を含む問題",選択肢1,選択肢2,選択肢3,選択肢4,2,"解説,詳細"

'''.trimLeft());

    expect(questions, hasLength(1));
    expect(questions.single.id, 'R-1');
    expect(questions.single.category, QuestionCategory.anatomy);
    expect(questions.single.questionText, 'カンマ,を含む問題');
    expect(questions.single.correctChoiceIndex, 1);
    expect(questions.single.explanation, '解説,詳細');
    expect(questions.single.isRequired, isTrue);
    expect(questions.single.isPremium, isFalse);
    expect(questions.single.subcategory, isEmpty);
  });

  test('CSVの1行目が所定のヘッダーでなければエラーにする', () {
    final service = GoogleSheetService();

    expect(
      () => service.parseRequiredQuestionsCsv(
        'R-1,解剖学,問題,1,2,3,4,1,解説',
      ),
      throwsA(isA<GoogleSheetException>()),
    );
  });

  test('公開CSVの取得失敗を呼び出し元へ返す', () async {
    final service = GoogleSheetService(
      client: MockClient((_) async => http.Response('not found', 404)),
    );

    await expectLater(
      service.loadRequiredQuestions(),
      throwsA(
        isA<GoogleSheetException>().having(
          (error) => error.message,
          'message',
          contains('404'),
        ),
      ),
    );
  });

  test('HTMLの200レスポンスをCSVとして解析しない', () async {
    final service = GoogleSheetService(
      client: MockClient(
        (_) async => http.Response(
          '<!doctype html><html><body>login</body></html>',
          200,
          headers: {'content-type': 'text/html; charset=utf-8'},
        ),
      ),
    );

    await expectLater(
      service.loadRequiredQuestions(),
      throwsA(
        isA<GoogleSheetException>().having(
          (error) => error.message,
          'message',
          contains('HTML'),
        ),
      ),
    );
  });

  test('UTF-8 BOMとCRLFを含むCSVを読み込む', () {
    final service = GoogleSheetService();
    final questions = service.parseRequiredQuestionsCsv(
      '\ufeff$csvHeader\r\nR-2,生理学,問題,1,2,3,4,3,解説\r\n',
    );

    expect(questions, hasLength(1));
    expect(questions.single.correctChoiceIndex, 2);
  });

  test('公衆衛生学を必修問題のカテゴリとして読み込む', () {
    final service = GoogleSheetService();
    final questions = service.parseRequiredQuestionsCsv(
      '$csvHeader\nR-PH,公衆衛生学,問題,1,2,3,4,1,解説\n',
    );

    expect(questions, hasLength(1));
    expect(questions.single.category, QuestionCategory.publicHealth);
    expect(questions.single.category.label, '公衆衛生学');
  });

  test('衛生学は公衆衛生学の別名として扱わない', () {
    expect(
      () => QuestionCategory.fromSheetValue('衛生学'),
      throwsArgumentError,
    );
    expect(
      QuestionCategory.fromRequiredSheetValue('衛生学'),
      QuestionCategory.unknownRequired,
    );
  });

  test('未対応カテゴリがあっても必修問題50問すべてを読み込む', () {
    final service = GoogleSheetService();
    const categories = <String>[
      '解剖学',
      '生理学',
      '運動学',
      '病理学',
      '公衆衛生学',
      '一般臨床医学',
      '外科学',
      '整形外科学',
      'リハビリテーション医学',
      '柔道整復理論',
      '関係法規',
      '将来追加される科目',
    ];
    final rows = List.generate(50, (index) {
      final category = categories[index % categories.length];
      return 'R-${index + 1},$category,問題${index + 1},1,2,3,4,1,解説';
    });

    final questions = service.parseRequiredQuestionsCsv(
      '$csvHeader\n${rows.join('\n')}\n',
    );

    expect(questions, hasLength(50));
    expect(
      questions.where((q) => q.category == QuestionCategory.unknownRequired),
      isNotEmpty,
    );
    expect(questions.every((q) => q.isRequired), isTrue);
  });

  test('通常問題の未知カテゴリは従来どおりエラーにする', () {
    expect(
      () => Question.fromSheetRow([
        'N-1',
        '未知の科目',
        '',
        '問題',
        '1',
        '2',
        '3',
        '4',
        '1',
        '解説',
      ]),
      throwsArgumentError,
    );
  });

  test('correctAnswerはStringと数値のどちらも変換できる', () {
    List<dynamic> row(Object answer) => <dynamic>[
      'R-3',
      '解剖学',
      '問題',
      '選択肢1',
      '選択肢2',
      '選択肢3',
      '選択肢4',
      answer,
      '解説',
    ];

    expect(
      Question.fromSheetRow(
        row('2'),
        hasSubcategory: false,
      ).correctChoiceIndex,
      1,
    );
    expect(
      Question.fromSheetRow(
        row(2),
        hasSubcategory: false,
      ).correctChoiceIndex,
      1,
    );
    expect(
      Question.fromSheetRow(
        row(2.0),
        hasSubcategory: false,
      ).correctChoiceIndex,
      1,
    );
    expect(
      () => Question.fromSheetRow(
        row('2.5'),
        hasSubcategory: false,
      ),
      throwsFormatException,
    );
  });

  test('必修問題の一覧が専用Providerまで渡る', () async {
    final service = GoogleSheetService(
      client: MockClient(
        (_) async => http.Response(
          '$csvHeader\nR-4,解剖学,問題,1,2,3,4,1,解説\n',
          200,
          headers: {'content-type': 'text/csv; charset=utf-8'},
        ),
      ),
    );
    final container = ProviderContainer(
      overrides: [googleSheetServiceProvider.overrideWithValue(service)],
    );
    addTearDown(container.dispose);

    final questions = await container.read(requiredQuestionsProvider.future);

    expect(questions, hasLength(1));
    expect(questions.single.id, 'R-4');
    expect(questions.single.isRequired, isTrue);
  });
}
