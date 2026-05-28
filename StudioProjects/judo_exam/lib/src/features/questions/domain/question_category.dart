enum QuestionCategory {
  anatomy('解剖学'),
  physiology('生理学'),
  kinesiology('運動学'),
  pathology('病理学'),
  clinicalMedicine('一般臨床医学'),
  judoTherapyTheory('柔道整復理論'),
  relatedLaws('関係法規');

  const QuestionCategory(this.label);

  final String label;

  static QuestionCategory fromCsvValue(String value) {
    return QuestionCategory.values.firstWhere(
      (category) => category.name == value || category.label == value,
      orElse: () => throw ArgumentError.value(value, 'value', 'Unknown category'),
    );
  }
}
