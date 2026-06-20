class Question {
  const Question({
    required this.id,
    required this.category,
    required this.question,
    required this.choice1,
    required this.choice2,
    required this.choice3,
    required this.choice4,
    required this.answer,
    required this.explanation,
  });

  final String id;
  final String category;
  final String question;
  final String choice1;
  final String choice2;
  final String choice3;
  final String choice4;
  final String answer;
  final String explanation;

  List<String> get choices => [choice1, choice2, choice3, choice4];

  factory Question.fromCsvRow(List<dynamic> row) {
    if (row.length < 9) {
      throw const FormatException(
        'Question row must contain at least 9 columns.',
      );
    }

    final values = row.map((value) => value.toString().trim()).toList();

    return Question(
      id: values[0],
      category: values[1],
      question: values[2],
      choice1: values[3],
      choice2: values[4],
      choice3: values[5],
      choice4: values[6],
      answer: values[7],
      explanation: values[8],
    );
  }
}
