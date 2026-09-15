import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_service.dart';
import '../models/user_profile_model.dart';
import 'dart:io';

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

  // ---------- USERNAME AVAILABILITY ----------
  // Returns true if available, false if taken, null if the check itself
  // failed (network error) - callers should treat null as "couldn't
  // verify" rather than "taken", and let save-time validation be the
  // final word.
  static Future<bool?> checkUsernameAvailable(String username) async {
    try {
      final response = await ApiService.authorizedRequest((token) {
        final url = Uri.parse(
            "${ApiService.baseUrl}/auth/username-available/?username=${Uri.encodeQueryComponent(username)}");
        return http.get(
          url,
          headers: {
            "Content-Type": "application/json",
            "Authorization": "Bearer $token",
          },
        );
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['available'] == true;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // ---------- SET USERNAME + PASSWORD ----------
  // One-time optional action: lets an OTP-only user pick a permanent
  // username and password so they can also log in that way later
  // (username or their mobile number, both with the same password).
  static Future<Map<String, dynamic>> setUsername({
    required String username,
    required String password,
    required String password2,
  }) async {
    try {
      final response = await ApiService.authorizedRequest((token) {
        final url = Uri.parse("${ApiService.baseUrl}/auth/set-username/");
        return http.post(
          url,
          headers: {
            "Content-Type": "application/json",
            "Authorization": "Bearer $token",
          },
          body: jsonEncode({
            "username": username,
            "password": password,
            "password2": password2,
          }),
        );
      });

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {"success": true, "data": jsonDecode(response.body)};
      } else {
        return {"success": false, "error": response.body};
      }
    } catch (e) {
      return {"success": false, "error": "Login required"};
    }
  }

  // ---------- CHANGE PASSWORD (OTP-gated) ----------
  // username: same as before (unchanged) or a new value if the user chose
  // "Change User Name" too - both cases require the same OTP verification.
  static Future<Map<String, dynamic>> changePasswordWithOtp({
    required String username,
    required String password,
    required String password2,
    required String otpCode,
  }) async {
    try {
      final response = await ApiService.authorizedRequest((token) {
        final url = Uri.parse("${ApiService.baseUrl}/auth/change-password-otp/");
        return http.post(
          url,
          headers: {
            "Content-Type": "application/json",
            "Authorization": "Bearer $token",
          },
          body: jsonEncode({
            "username": username,
            "password": password,
            "password2": password2,
            "otp_code": otpCode,
          }),
        );
      });

      if (response.statusCode == 200) {
        return {"success": true, "data": jsonDecode(response.body)};
      } else {
        String errorMsg = "Could not change password.";
        try {
          final body = jsonDecode(response.body);
          if (body is Map && body["error"] != null) errorMsg = body["error"].toString();
        } catch (e) {
          // keep default errorMsg
        }
        return {"success": false, "error": errorMsg};
      }
    } catch (e) {
      return {"success": false, "error": "Login required"};
    }
  }

  // ---------- UPLOAD PROFILE PHOTO ----------
  static Future<Map<String, dynamic>> uploadProfilePhoto(File photoFile) async {
    try {
      final token = await ApiService.getAccessToken();
      if (token == null) return {"success": false, "error": "Login required"};

      final url = Uri.parse("${ApiService.baseUrl}/auth/me/photo/");
      final request = http.MultipartRequest('POST', url);
      request.headers['Authorization'] = 'Bearer $token';
      request.files.add(await http.MultipartFile.fromPath('photo', photoFile.path));

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        return {"success": true, "data": jsonDecode(response.body)};
      } else {
        return {"success": false, "error": "Could not upload photo."};
      }
    } catch (e) {
      return {"success": false, "error": "Could not upload photo."};
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