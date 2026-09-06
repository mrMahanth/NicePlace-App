import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_service.dart';

class WaitlistService {
  // Requires login - uses the authorizedRequest wrapper so an expired
  // access token is refreshed and retried automatically, same as every
  // other authenticated call in the app.
  static Future<bool> joinWaitlist(String cityName) async {
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
  }
}