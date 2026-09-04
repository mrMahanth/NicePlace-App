import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_service.dart';
import '../models/user_profile_model.dart';

class UserProfileService {
  // Get logged-in user's profile
  static Future<Map<String, dynamic>> fetchMyProfile() async {
    try {
      final response = await ApiService.authorizedRequest((token) {
        final url = Uri.parse("${ApiService.baseUrl}/auth/me/");
        return http.get(
          url,
          headers: {
            "Content-Type": "application/json",
            "Authorization": "Bearer $token",
          },
        );
      });

      if (response.statusCode == 200) {
        final profile = UserProfileModel.fromJson(jsonDecode(response.body));
        return {"success": true, "data": profile};
      } else {
        return {"success": false, "error": response.body};
      }
    } catch (e) {
      return {"success": false, "error": "Login required"};
    }
  }

  // Update profile (send only the fields being changed - all optional)
  static Future<Map<String, dynamic>> updateMyProfile(
      Map<String, dynamic> fields) async {
    try {
      final response = await ApiService.authorizedRequest((token) {
        final url = Uri.parse("${ApiService.baseUrl}/auth/me/");
        return http.patch(
          url,
          headers: {
            "Content-Type": "application/json",
            "Authorization": "Bearer $token",
          },
          body: jsonEncode(fields),
        );
      });

      if (response.statusCode == 200) {
        final profile = UserProfileModel.fromJson(jsonDecode(response.body));
        return {"success": true, "data": profile};
      } else {
        return {"success": false, "error": response.body};
      }
    } catch (e) {
      return {"success": false, "error": "Login required"};
    }
  }

  // PIN code lookup using India Post's free public API
  // Returns {city, district, state} or null if not found
  static Future<Map<String, String>?> lookupPincode(String pincode) async {
    try {
      final url = Uri.parse("https://api.postalpincode.in/pincode/$pincode");
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        if (data.isNotEmpty && data[0]['Status'] == 'Success') {
          final postOffices = data[0]['PostOffice'] as List<dynamic>;
          if (postOffices.isNotEmpty) {
            final office = postOffices[0];
            return {
              'city': office['Block'] ?? office['District'] ?? '',
              'district': office['District'] ?? '',
              'state': office['State'] ?? '',
            };
          }
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}