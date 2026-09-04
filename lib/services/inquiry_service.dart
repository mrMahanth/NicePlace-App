import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_service.dart';
import '../models/inquiry_model.dart';

class InquiryService {
  static Future<Map<String, dynamic>> sendInquiry({
    required int propertyId,
    required String message,
  }) async {
    try {
      final response = await ApiService.authorizedRequest((token) {
        final url = Uri.parse("${ApiService.baseUrl}/inquiries/");
        return http.post(
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

  static Future<Map<String, dynamic>> fetchInquiries() async {
    try {
      final response = await ApiService.authorizedRequest((token) {
        final url = Uri.parse("${ApiService.baseUrl}/inquiries/");
        return http.get(
          url,
          headers: {
            "Content-Type": "application/json",
            "Authorization": "Bearer $token",
          },
        );
      });

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = jsonDecode(response.body);
        final List<Inquiry> inquiries =
            jsonList.map((item) => Inquiry.fromJson(item)).toList();
        return {"success": true, "data": inquiries};
      } else {
        return {"success": false, "error": response.body};
      }
    } catch (e) {
      return {"success": false, "error": "Login required"};
    }
  }

  static Future<Map<String, dynamic>> fetchInquiryDetail(int inquiryId) async {
    try {
      final response = await ApiService.authorizedRequest((token) {
        final url = Uri.parse("${ApiService.baseUrl}/inquiries/$inquiryId/");
        return http.get(
          url,
          headers: {
            "Content-Type": "application/json",
            "Authorization": "Bearer $token",
          },
        );
      });

      if (response.statusCode == 200) {
        final inquiry = Inquiry.fromJson(jsonDecode(response.body));
        return {"success": true, "data": inquiry};
      } else {
        return {"success": false, "error": response.body};
      }
    } catch (e) {
      return {"success": false, "error": "Login required"};
    }
  }

  static Future<Map<String, dynamic>> sendMessage({
    required int inquiryId,
    required String message,
  }) async {
    try {
      final response = await ApiService.authorizedRequest((token) {
        final url = Uri.parse(
            "${ApiService.baseUrl}/inquiries/$inquiryId/send_message/");
        return http.post(
          url,
          headers: {
            "Content-Type": "application/json",
            "Authorization": "Bearer $token",
          },
          body: jsonEncode({"message": message}),
        );
      });

      if (response.statusCode == 200 || response.statusCode == 201) {
        final chatMessage = ChatMessage.fromJson(jsonDecode(response.body));
        return {"success": true, "data": chatMessage};
      } else {
        return {"success": false, "error": response.body};
      }
    } catch (e) {
      return {"success": false, "error": "Login required"};
    }
  }
}