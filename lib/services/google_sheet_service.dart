import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../src/features/questions/domain/question.dart';

final googleSheetServiceProvider = Provider<GoogleSheetService>((ref) {
  final client = http.Client();
  ref.onDispose(client.close);

  return GoogleSheetService(client: client);
});

class GoogleSheetService {
  GoogleSheetService({http.Client? client}) : _client = client ?? http.Client();

  static const String spreadsheetId =
      '1Vd7dEb9iD1Gz3piWmdaRMdccCXRqQEjbE942XtAJERs';
  static const String requiredQuestionsCsvUrl =
      'https://docs.google.com/spreadsheets/d/e/'
      '2PACX-1vRmPQkrUIF5M0dysEcyVY_Sijo8zJM3dlWETZDGdeF3_SxuaqXBaQfp8Jtzd0dBRcDDDds0AK7RQE-o7Q/'
      'pub?gid=1870506905&single=true&output=csv';

  final http.Client _client;

  static const List<String> sheetNames = <String>[
    '解剖学',
    '生理学',
    '運動学',
    '病理学',
    '一般臨床医学',
    '外科学',
    '整形外科学',
    'リハビリテーション医学',
    '柔道整復理論',
    '関係法規',
  ];

  /// Sheets that use the shared ten-column layout with `subcategory` in the
  /// third column. Subjects not listed here continue to use the legacy layout.
  static const Set<String> _subcategorySheetNames = <String>{'解剖学', '生理学'};

  Uri _sheetJsonUri(String sheetName) => Uri.https(
    'docs.google.com',
    '/spreadsheets/d/$spreadsheetId/gviz/tq',
    {'tqx': 'out:json', 'sheet': sheetName},
  );

  Future<List<Question>> loadQuestions() async {
    try {
      final questions = <Question>[];

      for (final sheetName in sheetNames) {
        questions.addAll(await _loadQuestionsFromSheet(sheetName));
      }

      return List<Question>.unmodifiable(questions);
    } on GoogleSheetException {
      rethrow;
    } on FormatException catch (error) {
      throw GoogleSheetException('問題データの形式が不正です: ${error.message}');
    } on http.ClientException catch (error) {
      throw GoogleSheetException('Google Sheetsに接続できませんでした: ${error.message}');
    } catch (error) {
      throw GoogleSheetException('問題データの取得中にエラーが発生しました: $error');
    }
  }

  Future<String> fetchRequiredQuestionsCsv() async {
    try {
      final response = await _client.get(Uri.parse(requiredQuestionsCsvUrl));
      if (response.statusCode != 200) {
        throw GoogleSheetException(
          '必修問題を取得できませんでした。ステータスコード: ${response.statusCode}',
        );
      }
      return utf8.decode(response.bodyBytes);
    } on Object catch (error, stackTrace) {
      debugPrint('必修問題CSVの取得に失敗しました: $error\n$stackTrace');
      rethrow;
    }
  }

  Future<List<Question>> loadRequiredQuestions() async {
    final csv = await fetchRequiredQuestionsCsv();
    return parseRequiredQuestionsCsv(csv);
  }

  /// Parses the required-question CSV using the existing [Question] model.
  /// Quoted commas, quotes and embedded newlines are supported.
  List<Question> parseRequiredQuestionsCsv(String source) {
    try {
      final rows = _parseCsv(source);
      if (rows.isEmpty) return const <Question>[];

      const expectedHeader = <String>[
        'id',
        'category',
        'question',
        'choice1',
        'choice2',
        'choice3',
        'choice4',
        'correctAnswer',
        'explanation',
      ];
      final header = List<String>.of(rows.first);
      if (header.isNotEmpty) {
        header[0] = header[0].replaceFirst('\ufeff', '');
      }
      if (header.length < expectedHeader.length ||
          !expectedHeader.indexed.every(
            (entry) => header[entry.$1].trim() == entry.$2,
          )) {
        throw GoogleSheetException('必修問題CSVのヘッダーが不正です: $header');
      }

      final questions = <Question>[];
      for (final entry in rows.skip(1).indexed) {
        final values = entry.$2;
        if (values.every((value) => value.trim().isEmpty)) continue;
        try {
          questions.add(
            Question.fromSheetRow(values, hasSubcategory: false).copyWith(
              isPremium: false,
              isRequired: true,
            ),
          );
        } on Object catch (error) {
          // Add two because [indexed] starts after the header row.
          throw GoogleSheetException(
            '必修問題データの形式が不正です（${entry.$1 + 2}行目）: $error',
          );
        }
      }
      return List<Question>.unmodifiable(questions);
    } on Object catch (error, stackTrace) {
      debugPrint('必修問題CSVのパースに失敗しました: $error\n$stackTrace');
      rethrow;
    }
  }

  List<List<String>> _parseCsv(String source) {
    final rows = <List<String>>[];
    var row = <String>[];
    final field = StringBuffer();
    var quoted = false;
    for (var index = 0; index < source.length; index++) {
      final character = source[index];
      if (character == '"') {
        if (quoted && index + 1 < source.length && source[index + 1] == '"') {
          field.write('"');
          index++;
        } else {
          quoted = !quoted;
        }
      } else if (character == ',' && !quoted) {
        row.add(field.toString().trim());
        field.clear();
      } else if ((character == '\n' || character == '\r') && !quoted) {
        if (character == '\r' && index + 1 < source.length && source[index + 1] == '\n') index++;
        row.add(field.toString().trim());
        field.clear();
        rows.add(row);
        row = <String>[];
      } else {
        field.write(character);
      }
    }
    if (quoted) {
      throw const FormatException('CSVの引用符が閉じられていません。');
    }
    if (field.isNotEmpty || row.isNotEmpty) {
      row.add(field.toString().trim());
      rows.add(row);
    }
    return rows;
  }

  Future<List<Question>> _loadQuestionsFromSheet(String sheetName) async {
    final response = await _client.get(_sheetJsonUri(sheetName));

    if (response.statusCode != 200) {
      throw GoogleSheetException(
        'Google Sheetsから問題を取得できませんでした。'
        'シート: $sheetName, ステータスコード: ${response.statusCode}',
      );
    }

    final payload = _decodeVisualizationJson(response.body);
    final table = payload['table'];
    if (table is! Map<String, dynamic>) {
      throw FormatException('table が見つかりません。シート: $sheetName');
    }

    final rows = table['rows'];
    if (rows is! List) {
      throw FormatException('rows が見つかりません。シート: $sheetName');
    }

    final questions = <Question>[];
    for (final (rowIndex, row) in rows.indexed) {
      final values = _valuesFromRow(row);
      if (values.every((value) => value.isEmpty) || _isHeaderRow(values)) {
        continue;
      }

      try {
        questions.add(_questionFromValues(values, sheetName: sheetName));
      } on FormatException catch (error) {
        // Google Visualization returns the data rows after the header row, so
        // its zero-based index maps to the spreadsheet row by adding two.
        throw FormatException(
          _rowErrorMessage(
            values,
            sheetName: sheetName,
            rowNumber: rowIndex + 2,
            detail: error.message,
          ),
        );
      } on ArgumentError catch (error) {
        throw FormatException(
          _rowErrorMessage(
            values,
            sheetName: sheetName,
            rowNumber: rowIndex + 2,
            detail: error.message?.toString() ?? error.toString(),
          ),
        );
      }
    }

    return List<Question>.unmodifiable(questions);
  }

  Map<String, dynamic> _decodeVisualizationJson(String responseBody) {
    const prefix = 'google.visualization.Query.setResponse(';
    final start = responseBody.indexOf(prefix);
    final end = responseBody.lastIndexOf(');');
    if (start == -1 || end == -1 || end <= start) {
      throw const FormatException('Google Sheetsのレスポンス形式が不正です。');
    }

    final jsonText = responseBody.substring(start + prefix.length, end);
    final decoded = jsonDecode(jsonText);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Google SheetsのJSON形式が不正です。');
    }

    return decoded;
  }

  List<String> _valuesFromRow(dynamic row) {
    if (row is! Map<String, dynamic>) {
      throw const FormatException('行データの形式が不正です。');
    }

    final cells = row['c'];
    if (cells is! List) {
      return const <String>[];
    }

    return cells.map((cell) {
      if (cell is! Map<String, dynamic>) {
        return '';
      }
      final value = cell['v'] ?? cell['f'] ?? '';
      return value.toString().trim();
    }).toList(growable: false);
  }

  bool _isHeaderRow(List<String> values) {
    if (values.length < 9) {
      return false;
    }

    const legacyHeaders = <String>[
      'id',
      'category',
      'question',
      'choice1',
      'choice2',
      'choice3',
      'choice4',
      'answer',
      'explanation',
    ];
    const subcategoryHeaders = <String>[
      'id',
      'category',
      'subcategory',
      'question',
      'choice1',
      'choice2',
      'choice3',
      'choice4',
      'answer',
      'explanation',
    ];

    bool matches(List<String> headers) => values.length >= headers.length &&
        headers.indexed.every(
          (entry) => values[entry.$1].toLowerCase() == entry.$2,
        );
    return matches(legacyHeaders) || matches(subcategoryHeaders);
  }

  Question _questionFromValues(
    List<String> values, {
    required String sheetName,
  }) {
    if (values.length < 9) {
      throw FormatException('問題行には9列以上必要です: $values');
    }

    final valuesWithCategory = List<String>.of(values);
    if (valuesWithCategory[1].isEmpty) {
      valuesWithCategory[1] = sheetName;
    }

    // Only migrated sheets interpret the third column as a subcategory.
    // Keeping this decision independent of row length prevents optional
    // columns in a legacy sheet from shifting question and answer fields.
    final hasSubcategory = _subcategorySheetNames.contains(sheetName);
    return Question.fromSheetRow(
      valuesWithCategory,
      hasSubcategory: hasSubcategory,
    );
  }

  String _rowErrorMessage(
    List<String> values, {
    required String sheetName,
    required int rowNumber,
    required String detail,
  }) {
    final hasSubcategory = _subcategorySheetNames.contains(sheetName);
    final subcategory = hasSubcategory ? _valueAt(values, 2) : '';
    final answer = _valueAt(values, hasSubcategory ? 8 : 7);

    String display(String value) => value.isEmpty ? '<空>' : value;

    return 'シート: $sheetName, 行番号: $rowNumber, '
        'id: ${display(_valueAt(values, 0))}, '
        'subcategory: ${display(subcategory)}, '
        'answer: ${display(answer)} ($detail)';
  }

  String _valueAt(List<String> values, int index) =>
      index < values.length ? values[index] : '';
}

class GoogleSheetException implements Exception {
  const GoogleSheetException(this.message);

  final String message;

  @override
  String toString() => message;
}
