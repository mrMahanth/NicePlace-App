import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'api_service.dart';
import '../models/tag_model.dart';

class TagService {
  // ==================== USER SIDE ====================

  // Browse tags you could apply for
  static Future<Map<String, dynamic>> fetchAvailableTags() async {
    try {
      final response = await ApiService.authorizedRequest((token) {
        final url = Uri.parse("${ApiService.baseUrl}/auth/tags/public-list/");
        return http.get(url, headers: {"Authorization": "Bearer $token"});
      });

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = jsonDecode(response.body);
        return {"success": true, "data": jsonList.map((t) => Tag.fromJson(t)).toList()};
      }
      return {"success": false, "error": response.body};
    } catch (e) {
      return {"success": false, "error": "Login required"};
    }
  }

  // Full detail of one tag (benefits, terms, requirements) before applying
  static Future<Map<String, dynamic>> fetchTagPublicDetail(int tagId) async {
    try {
      final response = await ApiService.authorizedRequest((token) {
        final url = Uri.parse("${ApiService.baseUrl}/auth/tags/$tagId/public/");
        return http.get(url, headers: {"Authorization": "Bearer $token"});
      });

      if (response.statusCode == 200) {
        return {"success": true, "data": Tag.fromJson(jsonDecode(response.body))};
      }
      return {"success": false, "error": response.body};
    } catch (e) {
      return {"success": false, "error": "Login required"};
    }
  }

  // Submit a tag application. `answers` maps requirement ID -> either a
  // String (text answer) or a File (for file-upload requirements).
  static Future<Map<String, dynamic>> submitTagRequest({
    required int tagId,
    int? targetPropertyId,
    required Map<int, dynamic> answers,
  }) async {
    try {
      final response = await ApiService.authorizedRequest((token) async {
        final url = Uri.parse("${ApiService.baseUrl}/auth/tag-requests/");
        final request = http.MultipartRequest('POST', url);
        request.headers['Authorization'] = 'Bearer $token';
        request.fields['tag'] = tagId.toString();
        if (targetPropertyId != null) {
          request.fields['target_property'] = targetPropertyId.toString();
        }

        for (final entry in answers.entries) {
          final reqId = entry.key;
          final value = entry.value;
          if (value is File) {
            request.files.add(await http.MultipartFile.fromPath('file_$reqId', value.path));
          } else if (value != null && value.toString().trim().isNotEmpty) {
            request.fields['text_$reqId'] = value.toString().trim();
          }
        }

        final streamed = await request.send();
        return http.Response.fromStream(streamed);
      });

      if (response.statusCode == 201) {
        return {"success": true, "data": TagRequest.fromJson(jsonDecode(response.body))};
      }
      final body = jsonDecode(response.body);
      return {"success": false, "error": body["error"] ?? "Could not submit request."};
    } catch (e) {
      return {"success": false, "error": "Login required"};
    }
  }

  // View my own submitted requests + their status
  static Future<Map<String, dynamic>> fetchMyTagRequests() async {
    try {
      final response = await ApiService.authorizedRequest((token) {
        final url = Uri.parse("${ApiService.baseUrl}/auth/tag-requests/mine/");
        return http.get(url, headers: {"Authorization": "Bearer $token"});
      });

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = jsonDecode(response.body);
        return {"success": true, "data": jsonList.map((r) => TagRequest.fromJson(r)).toList()};
      }
      return {"success": false, "error": response.body};
    } catch (e) {
      return {"success": false, "error": "Login required"};
    }
  }

  // ==================== ADMIN SIDE: TAGS ====================

  static Future<Map<String, dynamic>> fetchAllTags() async {
    try {
      final response = await ApiService.authorizedRequest((token) {
        final url = Uri.parse("${ApiService.baseUrl}/auth/tags/");
        return http.get(url, headers: {"Authorization": "Bearer $token"});
      });

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = jsonDecode(response.body);
        return {"success": true, "data": jsonList.map((t) => Tag.fromJson(t)).toList()};
      }
      return {"success": false, "error": response.body};
    } catch (e) {
      return {"success": false, "error": "Login required"};
    }
  }

  static Future<Map<String, dynamic>> createTag(Map<String, dynamic> data) async {
    try {
      final response = await ApiService.authorizedRequest((token) {
        final url = Uri.parse("${ApiService.baseUrl}/auth/tags/");
        return http.post(
          url,
          headers: {"Content-Type": "application/json", "Authorization": "Bearer $token"},
          body: jsonEncode(data),
        );
      });

      if (response.statusCode == 201) {
        return {"success": true, "data": Tag.fromJson(jsonDecode(response.body))};
      }
      return {"success": false, "error": response.body};
    } catch (e) {
      return {"success": false, "error": "Login required"};
    }
  }

  static Future<Map<String, dynamic>> updateTag(int tagId, Map<String, dynamic> data) async {
    try {
      final response = await ApiService.authorizedRequest((token) {
        final url = Uri.parse("${ApiService.baseUrl}/auth/tags/$tagId/");
        return http.patch(
          url,
          headers: {"Content-Type": "application/json", "Authorization": "Bearer $token"},
          body: jsonEncode(data),
        );
      });

      if (response.statusCode == 200) {
        return {"success": true, "data": Tag.fromJson(jsonDecode(response.body))};
      }
      return {"success": false, "error": response.body};
    } catch (e) {
      return {"success": false, "error": "Login required"};
    }
  }

  static Future<bool> deleteTag(int tagId) async {
    try {
      final response = await ApiService.authorizedRequest((token) {
        final url = Uri.parse("${ApiService.baseUrl}/auth/tags/$tagId/");
        return http.delete(url, headers: {"Authorization": "Bearer $token"});
      });
      return response.statusCode == 204;
    } catch (e) {
      return false;
    }
  }

  // ==================== ADMIN SIDE: TAG REQUIREMENTS ====================

  static Future<Map<String, dynamic>> fetchTagRequirements(int tagId) async {
    try {
      final response = await ApiService.authorizedRequest((token) {
        final url = Uri.parse("${ApiService.baseUrl}/auth/tags/$tagId/requirements/");
        return http.get(url, headers: {"Authorization": "Bearer $token"});
      });

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = jsonDecode(response.body);
        return {"success": true, "data": jsonList.map((r) => TagRequirement.fromJson(r)).toList()};
      }
      return {"success": false, "error": response.body};
    } catch (e) {
      return {"success": false, "error": "Login required"};
    }
  }

  static Future<Map<String, dynamic>> createTagRequirement(
      int tagId, Map<String, dynamic> data) async {
    try {
      final response = await ApiService.authorizedRequest((token) {
        final url = Uri.parse("${ApiService.baseUrl}/auth/tags/$tagId/requirements/");
        return http.post(
          url,
          headers: {"Content-Type": "application/json", "Authorization": "Bearer $token"},
          body: jsonEncode(data),
        );
      });

      if (response.statusCode == 201) {
        return {"success": true, "data": TagRequirement.fromJson(jsonDecode(response.body))};
      }
      return {"success": false, "error": response.body};
    } catch (e) {
      return {"success": false, "error": "Login required"};
    }
  }

  static Future<bool> deleteTagRequirement(int requirementId) async {
    try {
      final response = await ApiService.authorizedRequest((token) {
        final url = Uri.parse("${ApiService.baseUrl}/auth/tag-requirements/$requirementId/");
        return http.delete(url, headers: {"Authorization": "Bearer $token"});
      });
      return response.statusCode == 204;
    } catch (e) {
      return false;
    }
  }

  // ==================== ADMIN SIDE: SLOT LIMITS ====================

  static Future<Map<String, dynamic>> fetchTagSlotLimits(int tagId) async {
    try {
      final response = await ApiService.authorizedRequest((token) {
        final url = Uri.parse("${ApiService.baseUrl}/auth/tags/$tagId/slot-limits/");
        return http.get(url, headers: {"Authorization": "Bearer $token"});
      });

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = jsonDecode(response.body);
        return {"success": true, "data": jsonList.map((s) => TagSlotLimit.fromJson(s)).toList()};
      }
      return {"success": false, "error": response.body};
    } catch (e) {
      return {"success": false, "error": "Login required"};
    }
  }

  static Future<Map<String, dynamic>> createTagSlotLimit(
      int tagId, Map<String, dynamic> data) async {
    try {
      final response = await ApiService.authorizedRequest((token) {
        final url = Uri.parse("${ApiService.baseUrl}/auth/tags/$tagId/slot-limits/");
        return http.post(
          url,
          headers: {"Content-Type": "application/json", "Authorization": "Bearer $token"},
          body: jsonEncode(data),
        );
      });

      if (response.statusCode == 201) {
        return {"success": true, "data": TagSlotLimit.fromJson(jsonDecode(response.body))};
      }
      return {"success": false, "error": response.body};
    } catch (e) {
      return {"success": false, "error": "Login required"};
    }
  }

  static Future<bool> deleteTagSlotLimit(int slotLimitId) async {
    try {
      final response = await ApiService.authorizedRequest((token) {
        final url = Uri.parse("${ApiService.baseUrl}/auth/tag-slot-limits/$slotLimitId/");
        return http.delete(url, headers: {"Authorization": "Bearer $token"});
      });
      return response.statusCode == 204;
    } catch (e) {
      return false;
    }
  }

  // ==================== ADMIN SIDE: TAG REQUESTS (REVIEW) ====================

  // statusFilter can be 'pending', 'approved', 'rejected', or null for all
  static Future<Map<String, dynamic>> fetchAllTagRequests({String? statusFilter}) async {
    try {
      final response = await ApiService.authorizedRequest((token) {
        var url = "${ApiService.baseUrl}/auth/tag-requests/all/";
        if (statusFilter != null) url += "?status=$statusFilter";
        return http.get(Uri.parse(url), headers: {"Authorization": "Bearer $token"});
      });

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = jsonDecode(response.body);
        return {"success": true, "data": jsonList.map((r) => TagRequest.fromJson(r)).toList()};
      }
      return {"success": false, "error": response.body};
    } catch (e) {
      return {"success": false, "error": "Login required"};
    }
  }

  static Future<Map<String, dynamic>> reviewTagRequest({
    required int requestId,
    required String status, // 'approved' or 'rejected'
    String rejectionReason = '',
  }) async {
    try {
      final response = await ApiService.authorizedRequest((token) {
        final url = Uri.parse("${ApiService.baseUrl}/auth/tag-requests/$requestId/review/");
        return http.patch(
          url,
          headers: {"Content-Type": "application/json", "Authorization": "Bearer $token"},
          body: jsonEncode({"status": status, "rejection_reason": rejectionReason}),
        );
      });

      if (response.statusCode == 200) {
        return {"success": true, "data": TagRequest.fromJson(jsonDecode(response.body))};
      }
      return {"success": false, "error": response.body};
    } catch (e) {
      return {"success": false, "error": "Login required"};
    }
  }

  // ==================== ADMIN SIDE: USERS & DIRECT ASSIGNMENT ====================

  // Superuser only - lists all users
  static Future<Map<String, dynamic>> fetchAllUsers() async {
    try {
      final response = await ApiService.authorizedRequest((token) {
        final url = Uri.parse("${ApiService.baseUrl}/auth/users/");
        return http.get(url, headers: {"Authorization": "Bearer $token"});
      });

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = jsonDecode(response.body);
        return {"success": true, "data": jsonList.map((u) => AppUser.fromJson(u)).toList()};
      }
      return {"success": false, "error": response.body};
    } catch (e) {
      return {"success": false, "error": "Login required"};
    }
  }

  static Future<Map<String, dynamic>> assignUserTag({
    required int userId,
    required int tagId,
  }) async {
    try {
      final response = await ApiService.authorizedRequest((token) {
        final url = Uri.parse("${ApiService.baseUrl}/auth/users/$userId/tags/");
        return http.post(
          url,
          headers: {"Content-Type": "application/json", "Authorization": "Bearer $token"},
          body: jsonEncode({"tag": tagId}),
        );
      });

      if (response.statusCode == 201) {
        return {"success": true, "data": jsonDecode(response.body)};
      }
      final body = jsonDecode(response.body);
      return {"success": false, "error": body["error"] ?? "Could not assign tag."};
    } catch (e) {
      return {"success": false, "error": "Login required"};
    }
  }

  static Future<Map<String, dynamic>> inviteUserTag({
    required int userId,
    required int tagId,
    String message = '',
  }) async {
    try {
      final response = await ApiService.authorizedRequest((token) {
        final url = Uri.parse("${ApiService.baseUrl}/auth/users/$userId/invite-tag/");
        return http.post(
          url,
          headers: {"Content-Type": "application/json", "Authorization": "Bearer $token"},
          body: jsonEncode({"tag": tagId, "message": message}),
        );
      });

      if (response.statusCode == 201) {
        return {"success": true, "data": jsonDecode(response.body)};
      }
      final body = jsonDecode(response.body);
      return {"success": false, "error": body["error"] ?? "Could not send invite."};
    } catch (e) {
      return {"success": false, "error": "Login required"};
    }
  }

  static Future<bool> removeUserTag(int userTagId) async {
    try {
      final response = await ApiService.authorizedRequest((token) {
        final url = Uri.parse("${ApiService.baseUrl}/auth/user-tags/$userTagId/");
        return http.delete(url, headers: {"Authorization": "Bearer $token"});
      });
      return response.statusCode == 204;
    } catch (e) {
      return false;
    }
  }
}