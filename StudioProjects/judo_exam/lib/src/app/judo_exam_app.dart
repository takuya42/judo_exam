import 'package:flutter/material.dart';

import 'theme/app_theme.dart';
import '../features/navigation/presentation/root_navigation.dart';

class JudoExamApp extends StatelessWidget {
  const JudoExamApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '柔道整復師国試対策',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      home: const RootNavigation(),
    );
  }
}
