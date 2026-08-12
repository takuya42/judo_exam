import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../src/features/questions/domain/question.dart';
import '../src/features/questions/domain/question_category.dart';

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
      'https://docs.google.com/spreadsheets/d/$spreadsheetId/'
      'gviz/tq?tqx=out:csv&gid=1870506905';
  static const String publicHealthQuestionsCsvUrl =
      'https://docs.google.com/spreadsheets/d/$spreadsheetId/'
      'gviz/tq?tqx=out:csv&gid=1580177639';

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
      questions.addAll(
        await _loadPublicHealthQuestionsFromCsv(publicHealthQuestionsCsvUrl),
      );

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
    final uri = Uri.parse(requiredQuestionsCsvUrl);
    debugPrint('[RequiredQuestions] 取得URL: $uri');
    try {
      final response = await _client.get(uri);
      final contentType = response.headers['content-type'] ?? '(なし)';
      final bodyForLog = utf8.decode(response.bodyBytes, allowMalformed: true);
      final bodyPreview = bodyForLog.substring(
        0,
        bodyForLog.length < 500 ? bodyForLog.length : 500,
      );
      debugPrint('[RequiredQuestions] statusCode: ${response.statusCode}');
      debugPrint('[RequiredQuestions] Content-Type: $contentType');
      debugPrint('[RequiredQuestions] response.body先頭500文字: $bodyPreview');

      if (response.statusCode != 200) {
        throw GoogleSheetException(
          '必修問題を取得できませんでした。ステータスコード: ${response.statusCode}',
        );
      }
      final normalizedContentType = contentType.toLowerCase();
      final normalizedBody = bodyForLog.trimLeft().toLowerCase();
      if (normalizedContentType.contains('text/html') ||
          normalizedBody.startsWith('<!doctype html') ||
          normalizedBody.startsWith('<html')) {
        throw GoogleSheetException(
          'Google SheetsからCSVではなくHTMLが返されました。'
          '公開設定またはgidを確認してください。',
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
      debugPrint('[RequiredQuestions] CSVの行数: ${rows.length}');
      if (rows.isEmpty) {
        debugPrint('[RequiredQuestions] 解析したヘッダー: []');
        debugPrint('[RequiredQuestions] Questionへの変換成功件数: 0');
        return const <Question>[];
      }

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
      debugPrint('[RequiredQuestions] 解析したヘッダー: $header');
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
            Question.fromSheetRow(
              values,
              hasSubcategory: false,
              categoryParser: QuestionCategory.fromRequiredSheetValue,
            ).copyWith(
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
      debugPrint(
        '[RequiredQuestions] Questionへの変換成功件数: ${questions.length}',
      );
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

  Future<List<Question>> _loadPublicHealthQuestionsFromCsv(String csvUrl) async {
    const sheetName = '公衆衛生学';
    final response = await _client.get(Uri.parse(csvUrl));
    if (response.statusCode != 200) {
      throw GoogleSheetException(
        'Google Sheetsから問題を取得できませんでした。'
        'シート: $sheetName, ステータスコード: ${response.statusCode}',
      );
    }

    final body = utf8.decode(response.bodyBytes);
    final normalizedBody = body.trimLeft().toLowerCase();
    final contentType = response.headers['content-type']?.toLowerCase() ?? '';
    if (contentType.contains('text/html') ||
        normalizedBody.startsWith('<!doctype html') ||
        normalizedBody.startsWith('<html')) {
      throw GoogleSheetException(
        'Google SheetsからCSVではなくHTMLが返されました。'
        'シート: $sheetName, 公開設定またはgidを確認してください。',
      );
    }

    return parsePublicHealthQuestionsCsv(body);
  }

  /// Parses the dedicated 9-column public-health CSV.
  ///
  /// Header removal happens here, on the path used by [loadQuestions], before
  /// any row can reach [Question.fromSheetRow]. This sheet intentionally has
  /// no `subcategory` column.
  List<Question> parsePublicHealthQuestionsCsv(String source) {
    const sheetName = '公衆衛生学';
    final rows = _parseCsv(source)
        .map(_normalizedRow)
        .toList(growable: false);
    final headerRemoved = rows.isNotEmpty &&
        _isPublicHealthHeaderRow(rows.first);
    final indexedRows = rows.indexed
        .skip(headerRemoved ? 1 : 0)
        .where((entry) => !entry.$2.every((value) => value.isEmpty))
        .toList(growable: false);
    final dataRows = indexedRows
        .map((entry) => entry.$2)
        .toList(growable: false);

    debugPrint('sheet: $sheetName');
    debugPrint('raw rows: ${rows.length}');
    debugPrint('first raw row: ${rows.isEmpty ? <String>[] : rows.first}');
    debugPrint('header removed: $headerRemoved');
    debugPrint('data rows: ${dataRows.length}');
    debugPrint(
      'first data row: ${dataRows.isEmpty ? <String>[] : dataRows.first}',
    );

    final questions = <Question>[];
    for (final entry in indexedRows) {
      final rowIndex = entry.$1;
      final values = entry.$2;

      try {
        if (values.length < 9) {
          throw FormatException('問題行には9列以上必要です: $values');
        }
        final rowForQuestion = List<String>.of(values);
        // The gid is dedicated to public health. Do not allow an empty or
        // accidentally copied category cell to classify this row elsewhere.
        rowForQuestion[1] = sheetName;
        final rawAnswer = rowForQuestion[7];
        final answer = int.tryParse(rawAnswer.toString().trim());
        if (answer == null) {
          throw FormatException('answer は数値である必要があります: $rawAnswer');
        }
        if (answer < 1 || answer > 4) {
          throw FormatException('answer は1〜4である必要があります: $rawAnswer');
        }
        rowForQuestion[7] = answer.toString();
        questions.add(
          Question.fromSheetRow(rowForQuestion, hasSubcategory: false),
        );
      } on FormatException catch (error) {
        throw FormatException(
          _rowErrorMessage(
            values,
            sheetName: sheetName,
            rowNumber: rowIndex + 1,
            detail: error.message,
          ),
        );
      } on ArgumentError catch (error) {
        throw FormatException(
          _rowErrorMessage(
            values,
            sheetName: sheetName,
            rowNumber: rowIndex + 1,
            detail: error.message?.toString() ?? error.toString(),
          ),
        );
      }
    }
    debugPrint('parsed questions: ${questions.length}');
    if (questions.isNotEmpty) {
      final first = questions.first;
      debugPrint(
        '[$sheetName] 最初の問題: id=${first.id}, '
        'category=${first.category.label}, question=${first.questionText}, '
        'correctAnswer=${first.correctChoiceIndex + 1}',
      );
    }
    return List<Question>.unmodifiable(questions);
  }

  bool _isPublicHealthHeaderRow(List<String> values) {
    if (values.length < 9) return false;

    String headerAt(int index) => values[index].trim().toLowerCase();
    return headerAt(0) == 'id' &&
        headerAt(1) == 'category' &&
        headerAt(2) == 'question' &&
        headerAt(7) == 'correctanswer';
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
    const csvHeaders = <String>[
      'id',
      'category',
      'question',
      'choice1',
      'choice2',
      'choice3',
      'choice4',
      'correctanswer',
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
    const subcategoryCsvHeaders = <String>[
      'id',
      'category',
      'subcategory',
      'question',
      'choice1',
      'choice2',
      'choice3',
      'choice4',
      'correctanswer',
      'explanation',
    ];

    bool matches(List<String> headers) => values.length >= headers.length &&
        headers.indexed.every(
          (entry) => values[entry.$1].toLowerCase() == entry.$2,
        );
    return matches(legacyHeaders) ||
        matches(csvHeaders) ||
        matches(subcategoryHeaders) ||
        matches(subcategoryCsvHeaders);
  }

  List<String> _normalizedRow(List<String> values) {
    final normalized = List<String>.of(values);
    if (normalized.isNotEmpty) {
      normalized[0] = normalized[0].replaceFirst('\ufeff', '').trim();
    }
    return normalized;
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
