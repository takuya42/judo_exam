import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:judo_exam/services/google_sheet_service.dart';
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
    expect(requestedUri.path, contains('/spreadsheets/d/e/'));
    expect(requestedUri.queryParameters['gid'], '1870506905');
    expect(requestedUri.queryParameters['single'], 'true');
    expect(requestedUri.queryParameters['output'], 'csv');
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
}
