import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:judo_exam/src/app/judo_exam_app.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('shows home screen', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const ProviderScope(child: JudoExamApp()));
    await tester.pumpAndSettle();

    expect(find.text('柔道整復師国試対策'), findsWidgets);
    expect(find.text('カテゴリ'), findsOneWidget);
    expect(find.text('問題を解く'), findsOneWidget);
  });
}
