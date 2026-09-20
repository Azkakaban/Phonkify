import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'features/recommendation/pages/similarity_test_page.dart';
import 'features/splash/pages/splash_page.dart';

class PhonkifyApp extends StatelessWidget {
  const PhonkifyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Phonkify',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const SplashPage(),
      routes: {
        '/similarity-test': (context) =>
            const SimilarityTestPage(),
      },
    );
  }
}