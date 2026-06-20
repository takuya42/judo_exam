import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/question.dart';
import '../domain/question_category.dart';

final sampleQuestionsProvider = Provider<List<Question>>((ref) {
  return  [
    Question(
      id: 'sample-anatomy-001',
      category: QuestionCategory.anatomy,
      questionText: '上腕骨に存在する部位はどれか。',
      choices: ['大転子', '結節間溝', '粗線', '内果'],
      correctChoiceIndex: 1,
      explanation: '結節間溝は上腕骨近位部にある構造です。',
      isPremium: false,
      year: 2026,
    ),
    Question(
      id: 'sample-physiology-001',
      category: QuestionCategory.physiology,
      questionText: '呼吸運動の主な吸気筋はどれか。',
      choices: ['横隔膜', '腹直筋', '内肋間筋', '広背筋'],
      correctChoiceIndex: 0,
      explanation: '安静吸気では横隔膜の収縮が中心的な役割を担います。',
      isPremium: false,
      year: 2026,
    ),
  ];
});

final freeQuestionCountProvider = Provider<int>((ref) {
  return ref.watch(sampleQuestionsProvider).where((question) => !question.isPremium).length;
});
