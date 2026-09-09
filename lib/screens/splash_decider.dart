import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/app_lock_service.dart';
import 'login_screen.dart';
import 'app_lock_screen.dart';
import 'main_screen.dart';

class SplashDecider extends StatefulWidget {
  const SplashDecider({super.key});

  @override
  State<SplashDecider> createState() => _SplashDeciderState();
}

class _SplashDeciderState extends State<SplashDecider> {
  @override
  void initState() {
    super.initState();
    _decide();
  }

  Future<void> _decide() async {
    final token = await ApiService.getAccessToken();

    if (!mounted) return;

    if (token == null) {
      // Ab push use kar rahe hain (pushReplacement nahi), taaki SplashDecider
      // stack mein "neeche" bana rahe - LoginScreen ke pop(true) karne par
      // wapas yahin aake aage badh sakein.
      final loggedIn = await Navigator.push<bool>(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );

      if (!mounted) return;

      if (loggedIn == true) {
        await _goToNextScreen();
      }
      // Agar loggedIn null/false ho (user login kiye bina back aa gaya),
      // filhaal yahi rehne dete hain - splash spinner dikhega.
      return;
    }

    await _goToNextScreen();
  }

  Future<void> _goToNextScreen() async {
    final bool lockEnabled = await AppLockService.isAppLockEnabled();

    if (!mounted) return;

    if (lockEnabled) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const AppLockScreen()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MainScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}