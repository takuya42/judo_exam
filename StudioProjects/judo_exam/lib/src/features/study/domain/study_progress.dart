class StudyProgress {
  const StudyProgress({
    required this.wrongQuestionIds,
    required this.favoriteQuestionIds,
    required this.correctCount,
    required this.incorrectCount,
  });

  factory StudyProgress.initial() {
    return const StudyProgress(
      wrongQuestionIds: <String>{},
      favoriteQuestionIds: <String>{},
      correctCount: 0,
      incorrectCount: 0,
    );
  }

  final Set<String> wrongQuestionIds;
  final Set<String> favoriteQuestionIds;
  final int correctCount;
  final int incorrectCount;

  int get answeredCount => correctCount + incorrectCount;

  double get accuracyRate {
    if (answeredCount == 0) {
      return 0;
    }
    return correctCount / answeredCount;
  }

  bool isFavorite(String questionId) => favoriteQuestionIds.contains(questionId);

  bool isWrong(String questionId) => wrongQuestionIds.contains(questionId);

  StudyProgress copyWith({
    Set<String>? wrongQuestionIds,
    Set<String>? favoriteQuestionIds,
    int? correctCount,
    int? incorrectCount,
  }) {
    return StudyProgress(
      wrongQuestionIds: wrongQuestionIds ?? this.wrongQuestionIds,
      favoriteQuestionIds: favoriteQuestionIds ?? this.favoriteQuestionIds,
      correctCount: correctCount ?? this.correctCount,
      incorrectCount: incorrectCount ?? this.incorrectCount,
    );
  }
}
