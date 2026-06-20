import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'theme/app_theme.dart';
import '../features/navigation/presentation/root_navigation.dart';
import '../features/settings/application/settings_providers.dart';

class JudoExamApp extends ConsumerWidget {
  const JudoExamApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(appSettingsControllerProvider);

    return MaterialApp(
      title: '柔道整復師国試対策',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      home: const RootNavigation(),
    );
  }
}
