import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:judo_exam/src/features/questions/application/required_exam_selector.dart';
import 'package:judo_exam/src/features/questions/domain/question.dart';
import 'package:judo_exam/src/features/questions/domain/question_category.dart';

void main() {
  Question question(int id, QuestionCategory category, {bool required = true}) =>
      Question(
        id: '$id',
        category: category,
        questionText: '問題$id',
        choices: const ['1', '2', '3', '4'],
        correctChoiceIndex: 0,
        explanation: '解説',
        isPremium: false,
        isRequired: required,
      );

  List<Question> completePool({int questionsPerSubject = 12}) => [
        for (final category in requiredExamSubjectCounts.keys)
          for (var index = 0; index < questionsPerSubject; index++)
            question(category.index * 100 + index, category),
      ];

  test('科目別の指定数で50問を重複なしに抽出する', () {
    final selected = selectRequiredExamQuestions(
      completePool(),
      random: Random(1),
    );

    expect(selected, hasLength(requiredExamQuestionCount));
    expect(selected.map((item) => item.storageId).toSet(), hasLength(50));
    for (final entry in requiredExamSubjectCounts.entries) {
      expect(
        selected.where((item) => item.category == entry.key),
        hasLength(entry.value),
        reason: entry.key.label,
      );
    }
  });

  test('通常問題と未指定科目は抽出対象にしない', () {
    final pool = completePool()
      ..add(question(9998, QuestionCategory.anatomy, required: false))
      ..add(question(9999, QuestionCategory.unknownRequired));

    final selected = selectRequiredExamQuestions(pool, random: Random(2));

    expect(selected.any((item) => item.id == '9998'), isFalse);
    expect(selected.any((item) => item.id == '9999'), isFalse);
  });

  test('開始ごとの抽選で異なる問題セットを生成できる', () {
    final pool = completePool(questionsPerSubject: 20);
    final first = selectRequiredExamQuestions(pool, random: Random(10));
    final second = selectRequiredExamQuestions(pool, random: Random(11));

    expect(
      first.map((item) => item.storageId).toSet(),
      isNot(second.map((item) => item.storageId).toSet()),
    );
  });

  test('1科目でも指定数に足りなければ50問の試験を作らない', () {
    final pool = completePool();
    pool.removeWhere(
      (item) => item.category == QuestionCategory.relatedLaws && item.id != '1000',
    );

    expect(
      () => selectRequiredExamQuestions(pool, random: Random(3)),
      throwsA(
        isA<StateError>().having(
          (error) => error.message,
          'message',
          contains('関係法規'),
        ),
      ),
    );
  });

  test('重複IDは1問として数える', () {
    final pool = completePool();
    final relatedLaw = pool.firstWhere(
      (item) => item.category == QuestionCategory.relatedLaws,
    );
    pool
      ..removeWhere((item) => item.category == QuestionCategory.relatedLaws)
      ..addAll(List.filled(4, relatedLaw));

    expect(requiredExamQuestionShortages(pool)[QuestionCategory.relatedLaws], 3);
  });
}
