import 'dart:async';
import 'package:flutter/material.dart';
import 'screens/main_screen.dart';

// TODO: change this import to point at your actual Home screen file/widget.
// For example, if your home screen widget is called HomeScreen and lives in
// lib/screens/home_screen.dart, uncomment and fix the line below:
// import 'screens/home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Wait 2 seconds, then move to Home. Adjust the Duration below to make
    // the splash show for longer or shorter.
    Timer(const Duration(seconds: 2), () {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          // TODO: replace HomeScreen() with your actual home screen widget,
          // e.g. builder: (context) => const HomeScreen(),
          builder: (context) => const MainScreen(),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2FAFC), // brand background color
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/custom-in-app-900.png',
              width: 260,
            ),
          ],
        ),
      ),
    );
  }
}

// Temporary placeholder so this file compiles on its own before you wire in
// your real Home screen. Delete this once you've replaced the TODOs above.