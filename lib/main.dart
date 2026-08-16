import 'package:flutter/material.dart';

import 'screens/splash_screen.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const FitFastApp());
}

class FitFastApp extends StatelessWidget {
  const FitFastApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'FitFast',
      theme: AppTheme.light,
      home: const SplashScreen(),
    );
  }
}
