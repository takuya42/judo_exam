import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:judo_exam/src/features/auth/presentation/auth_dialogs.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

void main() {
  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('iPhone login dialog shows Google and Apple at the same level', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;

    await _showLoginDialog(tester, const Size(390, 844));

    expect(find.text('Googleログイン'), findsOneWidget);
    expect(find.byType(SignInWithAppleButton), findsOneWidget);
    expect(find.text('Appleでログイン'), findsOneWidget);
    expect(find.text('メールログイン'), findsOneWidget);
    expect(find.text('新規登録'), findsOneWidget);
  });

  testWidgets('iPad login dialog also shows Apple sign-in', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;

    await _showLoginDialog(tester, const Size(1024, 1366));

    expect(find.text('Googleログイン'), findsOneWidget);
    expect(find.byType(SignInWithAppleButton), findsOneWidget);
  });

  testWidgets('Android login dialog does not show Apple sign-in', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;

    await _showLoginDialog(tester, const Size(390, 844));

    expect(find.text('Googleログイン'), findsOneWidget);
    expect(find.byType(SignInWithAppleButton), findsNothing);
    expect(find.text('Appleでログイン'), findsNothing);
  });
}

Future<void> _showLoginDialog(WidgetTester tester, Size size) async {
  await tester.binding.setSurfaceSize(size);
  addTearDown(() => tester.binding.setSurfaceSize(null));

  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        home: Consumer(
          builder: (context, ref, _) => Scaffold(
            body: ElevatedButton(
              onPressed: () => showLoginRequiredDialog(context, ref),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}
