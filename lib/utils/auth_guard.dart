import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../screens/login_screen.dart';

class AuthGuard {
  /// Checks if the user is logged in.
  /// Agar nahi, to "Please login to continue." dialog dikhata hai (Login / Cancel).
  /// Login par tap karne par Login screen khulti hai aur result ka wait karta hai.
  /// Returns true if the user is logged in (was already, or just logged in now).
  /// Returns false if the user cancelled/went back without logging in.
  static Future<bool> ensureLoggedIn(BuildContext context, {String? message}) async {
    final token = await ApiService.getAccessToken();
    if (token != null) return true;

    if (!context.mounted) return false;

    final shouldLogin = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        content: Text(message ?? "Please login to continue."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Login"),
          ),
        ],
      ),
    );

    if (shouldLogin != true || !context.mounted) return false;

    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );

    return result == true;
  }
}