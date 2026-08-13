import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:judo_exam/src/features/questions/application/question_providers.dart';
import 'package:judo_exam/src/features/questions/domain/question.dart';
import 'package:judo_exam/src/features/questions/domain/question_category.dart';

void main() {
  test('全科目をランダム順に含め、連続する演習の先頭問題を変える', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final questions = QuestionCategory.values
        .where((category) => category != QuestionCategory.unknownRequired)
        .map(_question)
        .toList();
    final randomizer = container.read(randomQuestionOrderProvider.notifier);

    final firstExam = randomizer.create(questions, random: Random(42));
    final secondExam = randomizer.create(questions, random: Random(42));

    expect(firstExam, hasLength(questions.length));
    expect(firstExam.map((question) => question.category).toSet(), {
      ...questions.map((question) => question.category),
    });
    expect(secondExam.first.storageId, isNot(firstExam.first.storageId));
  });

  test('問題がない場合も空の出題順を返す', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(
      container.read(randomQuestionOrderProvider.notifier).create(const []),
      isEmpty,
    );
  });
}

Question _question(QuestionCategory category) => Question(
      id: category.name,
      category: category,
      questionText: '${category.label}の問題',
      choices: const ['1', '2', '3', '4'],
      correctChoiceIndex: 0,
      explanation: '解説',
      isPremium: false,
    );
