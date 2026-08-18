import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_service.dart';

class InquiryService {
  static Future<Map<String, dynamic>> sendInquiry({
    required int propertyId,
    required String message,
  }) async {
    final token = await ApiService.getAccessToken();

    if (token == null) {
      return {"success": false, "error": "Login required"};
    }

    final url = Uri.parse("${ApiService.baseUrl}/inquiries/");

    final response = await http.post(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode({
        "property_id": propertyId,
        "initial_message": message,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return {"success": true, "data": jsonDecode(response.body)};
    } else {
      return {"success": false, "error": response.body};
    }
  }
}