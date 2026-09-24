import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_service.dart';

class ProjectService {
  // ---------- Draft Project create karna ----------
  static Future<Map<String, dynamic>> createDraftProject(int propertyTypeId) async {
    final response = await ApiService.authorizedRequest((token) {
      final url = Uri.parse("${ApiService.baseUrl}/projects/");
      return http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({"property_type_id": propertyTypeId}),
      );
    });

    if (response.statusCode == 201) {
      return {"success": true, "data": jsonDecode(response.body)};
    } else {
      return {"success": false, "error": response.body};
    }
  }

  // ---------- Project ka raw data fetch karna ----------
  static Future<Map<String, dynamic>> fetchProjectRaw(int projectId) async {
    final response = await ApiService.authorizedRequest((token) {
      final url = Uri.parse("${ApiService.baseUrl}/projects/$projectId/");
      return http.get(url, headers: {"Authorization": "Bearer $token"});
    });

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Failed to load project");
    }
  }

  // ---------- Project Details save karna ----------
  static Future<Map<String, dynamic>> updateProjectDetails({
    required int projectId,
    required String name,
    required String builderName,
    required String locality,
    required String city,
    required String district,
    required String state,
    required String country,
    required String pincode,
    double? latitude,
    double? longitude,
    int? totalUnits,
    required String listingType,
    double? startingPrice,
  }) async {
    final response = await ApiService.authorizedRequest((token) {
      final url = Uri.parse("${ApiService.baseUrl}/projects/$projectId/");
      return http.patch(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({
          "name": name,
          "builder_name": builderName,
          "locality": locality,
          "city": city,
          "district": district,
          "state": state,
          "country": country,
          "pincode": pincode,
          "latitude": latitude,
          "longitude": longitude,
          "total_units": totalUnits,
          "listing_type": listingType,
          "starting_price": startingPrice,
        }),
      );
    });

    if (response.statusCode == 200) {
      return {"success": true, "data": jsonDecode(response.body)};
    } else {
      return {"success": false, "error": response.body};
    }
  }

  // ---------- Project Details finalize karna ----------
  static Future<Map<String, dynamic>> finalizeDetails(int projectId) async {
    final response = await ApiService.authorizedRequest((token) {
      final url = Uri.parse("${ApiService.baseUrl}/projects/$projectId/finalize_details/");
      return http.post(url, headers: {"Authorization": "Bearer $token"});
    });

    if (response.statusCode == 200) {
      return {"success": true};
    } else {
      try {
        final body = jsonDecode(response.body);
        return {"success": false, "error": body["error"] ?? "Could not finalize details."};
      } catch (e) {
        return {"success": false, "error": "Could not finalize details."};
      }
    }
  }

    // ---------- Common Amenities save karna ----------
  static Future<Map<String, dynamic>> updateAmenities({
    required int projectId,
    required Map<String, String> attributes,
  }) async {
    final response = await ApiService.authorizedRequest((token) {
      final url = Uri.parse("${ApiService.baseUrl}/projects/$projectId/");
      return http.patch(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({"attributes": attributes}),
      );
    });

    if (response.statusCode == 200) {
      return {"success": true, "data": jsonDecode(response.body)};
    } else {
      return {"success": false, "error": response.body};
    }
  }

    // ---------- Document upload karna ----------
  static Future<Map<String, dynamic>> uploadDocument({
    required int projectId,
    required String label,
    required String filePath,
  }) async {
    final token = await ApiService.getAccessToken();
    if (token == null) {
      return {"success": false, "error": "Login required"};
    }

    final url = Uri.parse("${ApiService.baseUrl}/projects/$projectId/upload_document/");
    final request = http.MultipartRequest('POST', url);
    request.headers['Authorization'] = "Bearer $token";
    request.fields['label'] = label;
    request.files.add(await http.MultipartFile.fromPath('file', filePath));

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      return {"success": true, "data": jsonDecode(response.body)};
    } else {
      return {"success": false, "error": response.body};
    }
  }

    // ---------- Document delete karna ----------
  static Future<Map<String, dynamic>> deleteDocument({
    required int projectId,
    required int documentId,
  }) async {
    final response = await ApiService.authorizedRequest((token) {
      final url = Uri.parse("${ApiService.baseUrl}/projects/$projectId/delete_document/");
      return http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({"document_id": documentId}),
      );
    });

    if (response.statusCode == 200) {
      return {"success": true};
    } else {
      return {"success": false, "error": response.body};
    }
  }

    // ---------- Nearby Place add karna (project-level) ----------
  static Future<Map<String, dynamic>> addNearbyPlace({
    required int projectId,
    required int categoryId,
    required String name,
    double? distanceValue,
    required String distanceUnit,
  }) async {
    final response = await ApiService.authorizedRequest((token) {
      final url = Uri.parse("${ApiService.baseUrl}/projects/$projectId/add_nearby_place/");
      return http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({
          "category_id": categoryId,
          "name": name,
          "distance_value": distanceValue,
          "distance_unit": distanceUnit,
        }),
      );
    });

    if (response.statusCode == 200) {
      return {"success": true, "data": jsonDecode(response.body)};
    } else {
      try {
        final body = jsonDecode(response.body);
        return {"success": false, "error": body["error"] ?? "Could not add."};
      } catch (e) {
        return {"success": false, "error": "Could not add."};
      }
    }
  }

    // ---------- Nearby Place delete karna (project-level) ----------
  static Future<Map<String, dynamic>> deleteNearbyPlace({
    required int projectId,
    required int placeId,
  }) async {
    final response = await ApiService.authorizedRequest((token) {
      final url = Uri.parse("${ApiService.baseUrl}/projects/$projectId/delete_nearby_place/");
      return http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({"place_id": placeId}),
      );
    });

    if (response.statusCode == 200) {
      return {"success": true};
    } else {
      return {"success": false, "error": response.body};
    }
  }

    // ---------- Bulk units create karna ----------
  static Future<Map<String, dynamic>> bulkCreateUnits({
    required int projectId,
    required List<Map<String, dynamic>> units,
  }) async {
    final response = await ApiService.authorizedRequest((token) {
      final url = Uri.parse("${ApiService.baseUrl}/projects/$projectId/bulk_create_units/");
      return http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({"units": units}),
      );
    });

    if (response.statusCode == 200) {
      return {"success": true, "data": jsonDecode(response.body)};
    } else {
      try {
        final body = jsonDecode(response.body);
        return {"success": false, "error": body["error"] ?? "Could not create units."};
      } catch (e) {
        return {"success": false, "error": "Could not create units."};
      }
    }
  }
}