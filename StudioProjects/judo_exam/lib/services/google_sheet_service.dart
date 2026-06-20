import 'dart:convert';

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

  final http.Client _client;

  Uri get _sheetJsonUri => Uri.https(
    'docs.google.com',
    '/spreadsheets/d/$spreadsheetId/gviz/tq',
    {'tqx': 'out:json'},
  );

  Future<List<Question>> loadQuestions() async {
    try {
      final response = await _client.get(_sheetJsonUri);

      if (response.statusCode != 200) {
        throw GoogleSheetException(
          'Google Sheetsから問題を取得できませんでした。'
          'ステータスコード: ${response.statusCode}',
        );
      }

      final payload = _decodeVisualizationJson(response.body);
      final table = payload['table'];
      if (table is! Map<String, dynamic>) {
        throw const FormatException('table が見つかりません。');
      }

      final rows = table['rows'];
      if (rows is! List) {
        throw const FormatException('rows が見つかりません。');
      }

      return rows
          .map(_valuesFromRow)
          .where((values) => values.any((value) => value.isNotEmpty))
          .where((values) => !_isHeaderRow(values))
          .map(_questionFromValues)
          .toList(growable: false);
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

    const expectedHeaders = <String>[
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

    for (var i = 0; i < expectedHeaders.length; i++) {
      if (values[i].toLowerCase() != expectedHeaders[i]) {
        return false;
      }
    }

    return true;
  }

  Question _questionFromValues(List<String> values) {
    if (values.length < 9) {
      throw FormatException('問題行には9列以上必要です: $values');
    }

    return Question.fromSheetRow(values);
  }
}

class GoogleSheetException implements Exception {
  const GoogleSheetException(this.message);

  final String message;

  @override
  String toString() => message;
}
