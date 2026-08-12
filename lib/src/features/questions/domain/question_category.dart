enum QuestionCategory {
  anatomy('解剖学'),
  physiology('生理学'),
  kinesiology('運動学'),
  pathology('病理学'),
  publicHealth('公衆衛生学'),
  clinicalMedicine('一般臨床医学'),
  surgery('外科学'),
  orthopedics('整形外科学'),
  rehabilitationMedicine('リハビリテーション医学'),
  judoTherapyTheory('柔道整復理論'),
  relatedLaws('関係法規'),
  unknownRequired('その他');

  const QuestionCategory(this.label);

  final String label;

  static QuestionCategory fromSheetValue(String value) {
    return QuestionCategory.values.firstWhere(
      (category) => category.name == value || category.label == value,
      orElse: () => throw ArgumentError.value(value, 'value', 'Unknown category'),
    );
  }

  /// Parses categories used by the required-question CSV.
  ///
  /// Unlike normal questions, required questions must remain loadable when the
  /// sheet introduces a category that this app version does not know yet.
  static QuestionCategory fromRequiredSheetValue(String value) {
    return QuestionCategory.values.firstWhere(
      (category) =>
          category != QuestionCategory.unknownRequired &&
          (category.name == value || category.label == value),
      orElse: () => QuestionCategory.unknownRequired,
    );
  }
}
