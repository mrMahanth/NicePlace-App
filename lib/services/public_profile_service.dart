import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_service.dart';

class PublicProfileService {
  // Backend: GET /auth/public-profile/<username>/  (login zaroori hai)
  static Future<Map<String, dynamic>> fetchPublicProfile(String username) async {
    try {
      final response = await ApiService.authorizedRequest((token) {
        final url = Uri.parse("${ApiService.baseUrl}/auth/public-profile/${Uri.encodeComponent(username)}/");
        return http.get(url, headers: {"Authorization": "Bearer $token"});
      });

      if (response.statusCode == 200) {
        return {"success": true, "data": jsonDecode(response.body)};
      } else if (response.statusCode == 404) {
        return {"success": false, "error": "This profile doesn't exist or isn't available to view."};
      } else {
        return {"success": false, "error": "Could not load profile. Please try again."};
      }
    } catch (e) {
      return {"success": false, "error": "Network problem. Please check your internet and try again."};
    }
  }
}