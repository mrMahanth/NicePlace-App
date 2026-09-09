import 'package:flutter/material.dart';
import 'screens/splash_decider.dart';
import 'theme/app_theme.dart';
import 'splash_screen.dart';

void main() {
  runApp(const NicePlaceApp());
}

class NicePlaceApp extends StatelessWidget {
  const NicePlaceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NicePlace',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const SplashDecider(),
    );
  }
}