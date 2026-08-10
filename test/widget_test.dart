import 'package:flutter_test/flutter_test.dart';
import 'package:judo_exam/src/features/questions/domain/question.dart';
import 'package:judo_exam/src/features/questions/domain/question_category.dart';
import 'package:judo_exam/src/features/questions/domain/question_subcategory.dart';

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
}
