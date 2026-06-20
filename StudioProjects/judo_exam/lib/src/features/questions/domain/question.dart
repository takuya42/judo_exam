import 'question_category.dart';

class Question {
  Question({
    required this.id,
    required this.category,
    required this.questionText,
    required this.choices,
    required this.correctChoiceIndex,
    required this.explanation,
    required this.isPremium,
    this.year,
  }) : assert(
  choices.length == 4,
  'Question must have exactly four choices',
  ),
        assert(
        correctChoiceIndex >= 0 && correctChoiceIndex < 4,
        'correctChoiceIndex must be between 0 and 3',
        );

  final String id;
  final QuestionCategory category;
  final String questionText;
  final List<String> choices;
  final int correctChoiceIndex;
  final String explanation;
  final bool isPremium;
  final int? year;

  String get correctChoice => choices[correctChoiceIndex];

  bool isCorrect(int choiceIndex) => choiceIndex == correctChoiceIndex;

  Question copyWith({
    String? id,
    QuestionCategory? category,
    String? questionText,
    List<String>? choices,
    int? correctChoiceIndex,
    String? explanation,
    bool? isPremium,
    int? year,
  }) {
    return Question(
      id: id ?? this.id,
      category: category ?? this.category,
      questionText: questionText ?? this.questionText,
      choices: choices ?? this.choices,
      correctChoiceIndex: correctChoiceIndex ?? this.correctChoiceIndex,
      explanation: explanation ?? this.explanation,
      isPremium: isPremium ?? this.isPremium,
      year: year ?? this.year,
    );
  }

  factory Question.fromCsvRecord(List<String> record) {
    if (record.length < 9) {
      throw ArgumentError.value(
        record,
        'record',
        'Question CSV requires 9 columns',
      );
    }

    return Question(
      id: record[0],
      category: QuestionCategory.fromCsvValue(record[1]),
      questionText: record[2],
      choices: record.sublist(3, 7),
      correctChoiceIndex: int.parse(record[7]),
      explanation: record[8],
      isPremium:
      record.length > 9 ? record[9].toLowerCase() == 'true' : true,
      year:
      record.length > 10 && record[10].isNotEmpty
          ? int.parse(record[10])
          : null,
    );
  }
}