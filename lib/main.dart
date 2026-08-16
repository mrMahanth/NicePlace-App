import 'package:flutter/material.dart';
import 'screens/login_screen.dart';

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
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const LoginScreen(),
    );
  }
}