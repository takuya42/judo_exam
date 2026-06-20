import 'dart:math';

import 'question_category.dart';

class Question {
  const Question({
    required this.id,
    required this.category,
    required this.questionText,
    required this.choices,
    required this.correctChoiceIndex,
    required this.explanation,
    required this.isPremium,
    this.year,
  }) : assert(choices.length == 4, 'Question must have exactly four choices'),
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

  Question shuffledChoices({Random? random}) {
    final indexedChoices = choices.indexed.toList(growable: false)
      ..shuffle(random);
    final shuffledChoices = indexedChoices
        .map((entry) => entry.$2)
        .toList(growable: false);
    final shuffledCorrectChoiceIndex = indexedChoices.indexWhere(
      (entry) => entry.$1 == correctChoiceIndex,
    );

    return copyWith(
      choices: shuffledChoices,
      correctChoiceIndex: shuffledCorrectChoiceIndex,
    );
  }

  bool isCorrect(int choiceIndex) => choiceIndex == correctChoiceIndex;

  factory Question.fromJson(Map<String, dynamic> json) {
    final choices = json['choices'];
    if (choices is! List) {
      throw const FormatException('choices は配列である必要があります。');
    }

    return Question(
      id: _stringValue(json['id']),
      category: QuestionCategory.fromSheetValue(_stringValue(json['category'])),
      questionText: _stringValue(json['questionText'] ?? json['question']),
      choices: choices.map(_stringValue).toList(growable: false),
      correctChoiceIndex: json.containsKey('correctChoiceIndex')
          ? _intValue(
              json['correctChoiceIndex'],
              fieldName: 'correctChoiceIndex',
            )
          : parseAnswerIndex(json['answer']),
      explanation: _stringValue(json['explanation']),
      isPremium: _boolValue(
        json['isPremium'] ?? json['premium'],
        defaultValue: true,
      ),
      year: _optionalIntValue(json['year']),
    );
  }

  factory Question.fromSheetRow(List<dynamic> values) {
    if (values.length < 9) {
      throw FormatException('問題行には9列以上必要です: $values');
    }

    return Question(
      id: _stringValue(values[0]),
      category: QuestionCategory.fromSheetValue(_stringValue(values[1])),
      questionText: _stringValue(values[2]),
      choices: values.sublist(3, 7).map(_stringValue).toList(growable: false),
      correctChoiceIndex: parseAnswerIndex(values[7]),
      explanation: _stringValue(values[8]),
      isPremium: values.length > 9
          ? _boolValue(values[9], defaultValue: true)
          : true,
      year: values.length > 10 ? _optionalIntValue(values[10]) : null,
    );
  }

  static int parseAnswerIndex(Object? value) {
    final answer = _intValue(value, fieldName: 'answer');

    if (answer >= 1 && answer <= 4) {
      return answer - 1;
    }
    if (answer >= 0 && answer < 4) {
      return answer;
    }

    throw FormatException('answer は0〜3または1〜4である必要があります: $value');
  }

  static String _stringValue(Object? value) => value?.toString().trim() ?? '';

  static int _intValue(Object? value, {required String fieldName}) {
    if (value is int) {
      return value;
    }
    if (value is double) {
      return value.toInt();
    }

    final normalized = _stringValue(value);
    final parsed =
        int.tryParse(normalized) ?? double.tryParse(normalized)?.toInt();
    if (parsed == null) {
      throw FormatException('$fieldName は数値である必要があります: $value');
    }

    return parsed;
  }

  static int? _optionalIntValue(Object? value) {
    if (value == null || _stringValue(value).isEmpty) {
      return null;
    }

    return _intValue(value, fieldName: 'year');
  }

  static bool _boolValue(Object? value, {required bool defaultValue}) {
    if (value is bool) {
      return value;
    }

    final normalized = _stringValue(value).toLowerCase();
    if (normalized.isEmpty) {
      return defaultValue;
    }
    if (normalized == 'true' ||
        normalized == '1' ||
        normalized == '1.0' ||
        normalized == '有料') {
      return true;
    }
    if (normalized == 'false' ||
        normalized == '0' ||
        normalized == '0.0' ||
        normalized == '無料') {
      return false;
    }

    return defaultValue;
  }

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
}
