import 'package:flutter/services.dart';

import '../domain/question.dart';

class QuestionCsvLoader {
  QuestionCsvLoader({AssetBundle? assetBundle})
    : _assetBundle = assetBundle ?? rootBundle;

  static const defaultAssetPath = 'assets/questions/sample_questions.csv';

  final AssetBundle _assetBundle;

  Future<List<Question>> loadQuestions({String path = defaultAssetPath}) async {
    final csvText = await _assetBundle.loadString(path);
    final rows = _parseCsv(csvText);

    if (rows.length <= 1) {
      return const [];
    }

    return rows.skip(1).where((row) => row.any((cell) => cell.isNotEmpty)).map(
      Question.fromCsvRecord,
    ).toList(growable: false);
  }

  List<List<String>> _parseCsv(String input) {
    final rows = <List<String>>[];
    var row = <String>[];
    final cell = StringBuffer();
    var inQuotes = false;

    for (var i = 0; i < input.length; i++) {
      final char = input[i];

      if (char == '"') {
        final isEscapedQuote = inQuotes && i + 1 < input.length && input[i + 1] == '"';
        if (isEscapedQuote) {
          cell.write('"');
          i++;
        } else {
          inQuotes = !inQuotes;
        }
      } else if (char == ',' && !inQuotes) {
        row.add(cell.toString());
        cell.clear();
      } else if ((char == '\n' || char == '\r') && !inQuotes) {
        if (char == '\r' && i + 1 < input.length && input[i + 1] == '\n') {
          i++;
        }
        row.add(cell.toString());
        cell.clear();
        rows.add(row);
        row = <String>[];
      } else {
        cell.write(char);
      }
    }

    if (cell.isNotEmpty || row.isNotEmpty) {
      row.add(cell.toString());
      rows.add(row);
    }

    return rows;
  }
}
