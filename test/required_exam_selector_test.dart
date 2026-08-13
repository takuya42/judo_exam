import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:judo_exam/src/features/questions/application/required_exam_selector.dart';
import 'package:judo_exam/src/features/questions/domain/question.dart';
import 'package:judo_exam/src/features/questions/domain/question_category.dart';

void main() {
  Question question(int id, QuestionCategory category, {bool required = true}) => Question(
        id: '$id',
        category: category,
        questionText: '問題$id',
        choices: const ['1', '2', '3', '4'],
        correctChoiceIndex: 0,
        explanation: '解説',
        isPremium: false,
        isRequired: required,
      );

  test('50問を重複なしで抽出する', () {
    final questions = List.generate(
      100,
      (index) => question(index, QuestionCategory.values[index % 11]),
    );

    final selected = selectRequiredExamQuestions(questions, random: Random(1));

    expect(selected, hasLength(requiredExamQuestionCount));
    expect(selected.map((item) => item.storageId).toSet(), hasLength(50));
  });

  test('複数科目から可能な限り均等に抽出する', () {
    final questions = <Question>[
      for (var index = 0; index < 90; index++) question(index, QuestionCategory.anatomy),
      for (var index = 90; index < 100; index++) question(index, QuestionCategory.physiology),
    ];

    final selected = selectRequiredExamQuestions(questions, random: Random(2));
    final physiologyCount = selected.where((item) => item.category == QuestionCategory.physiology).length;

    expect(physiologyCount, 10);
    expect(selected.where((item) => item.category == QuestionCategory.anatomy), hasLength(40));
  });

  test('重複IDと通常問題を除外し、登録数未満なら存在する問題だけを返す', () {
    final required = question(1, QuestionCategory.anatomy);
    final selected = selectRequiredExamQuestions(
      [required, required, question(2, QuestionCategory.physiology, required: false)],
      random: Random(3),
    );

    expect(selected, [required]);
  });
}
