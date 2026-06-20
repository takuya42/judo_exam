import 'dart:convert';

import 'package:csv/csv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../models/question.dart';

final googleSheetServiceProvider = Provider<GoogleSheetService>((ref) {
  final client = http.Client();
  ref.onDispose(client.close);

  return GoogleSheetService(client: client);
});

final questionsProvider = FutureProvider<List<Question>>((ref) async {
  final service = ref.watch(googleSheetServiceProvider);
  return service.loadQuestions();
});

class GoogleSheetService {
  GoogleSheetService({http.Client? client}) : _client = client ?? http.Client();

  static const String _spreadsheetId =
      '1Vd7dEb9iD1Gz3piWmdaRMdccCXRqQEjbE942XtAJERs';

  final http.Client _client;

  Uri get _csvUri => Uri.https(
    'docs.google.com',
    '/spreadsheets/d/$_spreadsheetId/export',
    {'format': 'csv'},
  );

  Future<List<Question>> loadQuestions() async {
    try {
      final response = await _client.get(_csvUri);

      if (response.statusCode != 200) {
        throw GoogleSheetException(
          'Failed to load questions. Status code: ${response.statusCode}',
        );
      }

      final rows = const CsvToListConverter(shouldParseNumbers: false).convert(
        utf8.decode(response.bodyBytes),
      );

      if (rows.isEmpty) {
        return const <Question>[];
      }

      final dataRows = _hasHeaderRow(rows.first) ? rows.skip(1) : rows;

      return dataRows
          .where((row) => row.any((value) => value.toString().trim().isNotEmpty))
          .map(Question.fromCsvRow)
          .toList(growable: false);
    } on GoogleSheetException {
      rethrow;
    } on FormatException catch (error) {
      throw GoogleSheetException(
        'Failed to parse question CSV: ${error.message}',
      );
    } on http.ClientException catch (error) {
      throw GoogleSheetException(
        'Failed to connect to Google Sheets: ${error.message}',
      );
    } catch (error) {
      throw GoogleSheetException(
        'Unexpected error while loading questions: $error',
      );
    }
  }

  bool _hasHeaderRow(List<dynamic> row) {
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

    if (row.length < expectedHeaders.length) {
      return false;
    }

    for (var i = 0; i < expectedHeaders.length; i++) {
      if (row[i].toString().trim().toLowerCase() != expectedHeaders[i]) {
        return false;
      }
    }

    return true;
  }
}

class GoogleSheetException implements Exception {
  const GoogleSheetException(this.message);

  final String message;

  @override
  String toString() => 'GoogleSheetException: $message';
}
