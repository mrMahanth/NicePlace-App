import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_service.dart';

class WaitlistService {
  /// Registers the logged-in user's interest in a not-yet-launched city.
  /// Returns false if the user isn't logged in or the request fails.
  static Future<bool> notifyMeForCity(String cityName) async {
    try {
      final response = await ApiService.authorizedRequest((token) {
        return http.post(
          Uri.parse('${ApiService.baseUrl}/waitlist/'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode({'city_name': cityName}),
        );
      });
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      return false; // e.g. "Login required" thrown by authorizedRequest
    }
  }
}