import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // Yahan apna hotspot IP daala hai. Agar IP kabhi change ho, sirf yahan update karna.
  static const String baseUrl = "http://192.168.137.1:8000/api";

  // ---------- LOGIN ----------
  static Future<Map<String, dynamic>> login(String username, String password) async {
    final url = Uri.parse("$baseUrl/auth/login/");

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "username": username,
        "password": password,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      // Token ko phone mein save kar rahe hain taaki dobara login na maangna pade
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString("access_token", data["access"]);
      await prefs.setString("refresh_token", data["refresh"]);

      return {"success": true, "data": data};
    } else {
      return {"success": false, "error": response.body};
    }
  }

  // ---------- REGISTER ----------
  static Future<Map<String, dynamic>> register(Map<String, dynamic> userData) async {
    final url = Uri.parse("$baseUrl/auth/register/");

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(userData),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      return {"success": true, "data": jsonDecode(response.body)};
    } else {
      return {"success": false, "error": response.body};
    }
  }

  // ---------- SAVED TOKEN NIKALNA (baad mein properties fetch karne ke liye chahiye) ----------
  static Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("access_token");
  }
  // ---------- TOKEN SE LOGGED-IN USER KA ID NIKALNA ----------
  static Future<int?> getCurrentUserId() async {
    final token = await getAccessToken();
    if (token == null) return null;

    final parts = token.split('.');
    if (parts.length != 3) return null; // valid JWT mein 3 parts hote hain

    try {
      final payload = _decodeBase64(parts[1]);
      final data = jsonDecode(payload);
      return data['user_id'];
    } catch (e) {
      return null;
    }
  }

  // JWT ke middle part (payload) ko decode karne ke liye helper
  static String _decodeBase64(String str) {
    String output = str.replaceAll('-', '+').replaceAll('_', '/');
    switch (output.length % 4) {
      case 0:
        break;
      case 2:
        output += '==';
        break;
      case 3:
        output += '=';
        break;
      default:
        throw Exception('Invalid token format');
    }
    return utf8.decode(base64Url.decode(output));
  }

  // ---------- OTP REQUEST ----------
  // Tries 'login' first; if the phone isn't registered yet, automatically
  // retries with 'register' so the user doesn't need to know which one applies.
  static Future<Map<String, dynamic>> requestOtp(String phone) async {
    final loginAttempt = await _requestOtpWithPurpose(phone, 'login');
    if (loginAttempt["success"] == true) {
      return loginAttempt;
    }

    // If login failed because the number isn't registered, try register purpose
    final errorText = loginAttempt["error"]?.toString() ?? '';
    if (errorText.contains("No account found")) {
      return await _requestOtpWithPurpose(phone, 'register');
    }

    return loginAttempt;
  }

  static Future<Map<String, dynamic>> _requestOtpWithPurpose(
      String phone, String purpose) async {
    final url = Uri.parse("$baseUrl/auth/otp/request/");

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"phone": phone, "purpose": purpose}),
    );

    if (response.statusCode == 200) {
      return {"success": true, "data": jsonDecode(response.body)};
    } else {
      final body = jsonDecode(response.body);
      return {"success": false, "error": body["error"] ?? "Could not send OTP."};
    }
  }

  // ---------- OTP VERIFY ----------
  static Future<Map<String, dynamic>> verifyOtp(String phone, String code) async {
    final url = Uri.parse("$baseUrl/auth/otp/verify/");

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"phone": phone, "code": code}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString("access_token", data["access"]);
      await prefs.setString("refresh_token", data["refresh"]);

      return {"success": true, "data": data};
    } else {
      final body = jsonDecode(response.body);
      return {"success": false, "error": body["error"] ?? "Invalid OTP."};
    }
  }

  // ---------- TOKEN REFRESH (handles 15-min access token expiry) ----------
  // Prevents multiple simultaneous refresh calls if several API requests
  // fail at the same time - they all wait for the same refresh attempt.
  static Future<bool>? _refreshInProgress;

  static Future<bool> _refreshAccessToken() async {
    _refreshInProgress ??= _performRefresh();
    final result = await _refreshInProgress!;
    _refreshInProgress = null;
    return result;
  }

  static Future<bool> _performRefresh() async {
    final prefs = await SharedPreferences.getInstance();
    final refreshToken = prefs.getString("refresh_token");
    if (refreshToken == null) return false;

    try {
      final url = Uri.parse("$baseUrl/auth/login/refresh/");
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"refresh": refreshToken}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await prefs.setString("access_token", data["access"]);
        // ROTATE_REFRESH_TOKENS is on - a new refresh token is issued each
        // time, and the old one is blacklisted. Must save the new one.
        if (data["refresh"] != null) {
          await prefs.setString("refresh_token", data["refresh"]);
        }
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // ---------- AUTHORIZED REQUEST WRAPPER ----------
  // Wraps any authenticated API call. If it fails with 401 (expired token),
  // automatically refreshes and retries once. Use this instead of manually
  // fetching the token in every service function.
  static Future<http.Response> authorizedRequest(
    Future<http.Response> Function(String token) requestFn,
  ) async {
    final token = await getAccessToken();
    if (token == null) {
      throw Exception("Login required");
    }

    http.Response response = await requestFn(token);

    if (response.statusCode == 401) {
      final refreshed = await _refreshAccessToken();
      if (refreshed) {
        final newToken = await getAccessToken();
        response = await requestFn(newToken!);
      } else {
        // Refresh token itself expired/invalid (e.g. after 90 days) -
        // nothing more we can do, clear local tokens.
        await logout();
      }
    }

    return response;
  }

  // ---------- LOGOUT ----------
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove("access_token");
    await prefs.remove("refresh_token");
  }
}