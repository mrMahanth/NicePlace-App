import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_service.dart';
import '../models/notification_model.dart';

class NotificationService {
  static Future<Map<String, dynamic>> fetchNotifications() async {
    try {
      final response = await ApiService.authorizedRequest((token) {
        final url = Uri.parse("${ApiService.baseUrl}/notifications/");
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
        final List<AppNotification> notifications =
            jsonList.map((item) => AppNotification.fromJson(item)).toList();
        return {"success": true, "data": notifications};
      } else {
        return {"success": false, "error": response.body};
      }
    } catch (e) {
      return {"success": false, "error": "Login required"};
    }
  }

  static Future<int> fetchUnreadCount() async {
    try {
      final response = await ApiService.authorizedRequest((token) {
        final url =
            Uri.parse("${ApiService.baseUrl}/notifications/unread_count/");
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
        return data['unread_count'] ?? 0;
      }
      return 0;
    } catch (e) {
      return 0;
    }
  }

  static Future<bool> markAsRead(int notificationId) async {
    try {
      final response = await ApiService.authorizedRequest((token) {
        final url = Uri.parse(
            "${ApiService.baseUrl}/notifications/$notificationId/mark_read/");
        return http.post(
          url,
          headers: {
            "Content-Type": "application/json",
            "Authorization": "Bearer $token",
          },
        );
      });

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}