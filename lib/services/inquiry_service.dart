import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_service.dart';
import '../models/inquiry_model.dart';

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

  // NAYA FUNCTION 1: Saari inquiries ki list laana
  static Future<Map<String, dynamic>> fetchInquiries() async {
    final token = await ApiService.getAccessToken();

    if (token == null) {
      return {"success": false, "error": "Login required"};
    }

    final url = Uri.parse("${ApiService.baseUrl}/inquiries/");

    final response = await http.get(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> jsonList = jsonDecode(response.body);
      final List<Inquiry> inquiries =
          jsonList.map((item) => Inquiry.fromJson(item)).toList();
      return {"success": true, "data": inquiries};
    } else {
      return {"success": false, "error": response.body};
    }
  }

  // NAYA FUNCTION 2: Ek specific inquiry ki detail (with messages) laana
  static Future<Map<String, dynamic>> fetchInquiryDetail(int inquiryId) async {
    final token = await ApiService.getAccessToken();

    if (token == null) {
      return {"success": false, "error": "Login required"};
    }

    final url = Uri.parse("${ApiService.baseUrl}/inquiries/$inquiryId/");

    final response = await http.get(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
    );

    if (response.statusCode == 200) {
      final inquiry = Inquiry.fromJson(jsonDecode(response.body));
      return {"success": true, "data": inquiry};
    } else {
      return {"success": false, "error": response.body};
    }
  }

  // NAYA FUNCTION 3: Kisi inquiry mein reply/message bhejna
  static Future<Map<String, dynamic>> sendMessage({
    required int inquiryId,
    required String message,
  }) async {
    final token = await ApiService.getAccessToken();

    if (token == null) {
      return {"success": false, "error": "Login required"};
    }

    final url =
        Uri.parse("${ApiService.baseUrl}/inquiries/$inquiryId/send_message/");

    final response = await http.post(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode({"message": message}),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final chatMessage = ChatMessage.fromJson(jsonDecode(response.body));
      return {"success": true, "data": chatMessage};
    } else {
      return {"success": false, "error": response.body};
    }
  }
}