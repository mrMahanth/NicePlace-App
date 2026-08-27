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
  // ---------- LOGOUT ----------
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove("access_token");
    await prefs.remove("refresh_token");
  }
}