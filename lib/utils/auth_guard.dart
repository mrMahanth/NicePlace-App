import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../screens/login_screen.dart';

class AuthGuard {
  /// Checks if the user is logged in.
  /// If not, optionally shows [message] (e.g. "Please login to post a
  /// property") before opening the Login screen and waiting for the result.
  /// Returns true if the user is logged in (was already, or just logged in now).
  /// Returns false if the user cancelled/went back without logging in.
  static Future<bool> ensureLoggedIn(BuildContext context, {String? message}) async {
    final token = await ApiService.getAccessToken();
    if (token != null) return true;

    if (message != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }

    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );

    return result == true;
  }
}