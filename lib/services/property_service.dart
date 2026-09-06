import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/property_model.dart';
import 'api_service.dart';

class PropertyService {
  static Future<List<Property>> fetchProperties({
    String? city,
    int? propertyTypeId,
    String? listingType,
    double? minPrice,
    double? maxPrice,
    String? search,
  }) async {
    final queryParams = <String, String>{};
    if (city != null && city.isNotEmpty) queryParams['city'] = city;
    if (propertyTypeId != null) queryParams['property_type'] = propertyTypeId.toString();
    if (listingType != null && listingType.isNotEmpty) queryParams['listing_type'] = listingType;
    if (minPrice != null) queryParams['min_price'] = minPrice.toString();
    if (maxPrice != null) queryParams['max_price'] = maxPrice.toString();
    if (search != null && search.isNotEmpty) queryParams['search'] = search;

    final url = Uri.parse("${ApiService.baseUrl}/properties/")
        .replace(queryParameters: queryParams.isEmpty ? null : queryParams);

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final List<dynamic> jsonList = jsonDecode(response.body);
      return jsonList.map((json) => Property.fromJson(json)).toList();
    } else {
      throw Exception("Failed to load properties");
    }
  }

  static Future<Map<String, dynamic>> createDraftProperty(int propertyTypeId) async {
    final response = await ApiService.authorizedRequest((token) {
      final url = Uri.parse("${ApiService.baseUrl}/properties/");
      return http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({
          "property_type_id": propertyTypeId,
        }),
      );
    });

    if (response.statusCode == 201) {
      return {"success": true, "data": jsonDecode(response.body)};
    } else {
      return {"success": false, "error": response.body};
    }
  }

  static Future<Map<String, dynamic>> updateBasicDetails({
    required int propertyId,
    required String title,
    required String locality,
    required String city,
    required String district,
    required String state,
    required String country,
    double? latitude,
    double? longitude,
  }) async {
    final response = await ApiService.authorizedRequest((token) {
      final url = Uri.parse("${ApiService.baseUrl}/properties/$propertyId/");
      return http.patch(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({
          "title": title,
          "locality": locality,
          "city": city,
          "district": district,
          "state": state,
          "country": country,
          "latitude": latitude,
          "longitude": longitude,
        }),
      );
    });

    if (response.statusCode == 200) {
      return {"success": true, "data": jsonDecode(response.body)};
    } else {
      return {"success": false, "error": response.body};
    }
  }

  // ---------- UPDATED: Ab 3-tier pricing (Price Group) support karta hai ----------
  static Future<Map<String, dynamic>> updatePricing({
    required int propertyId,
    required String listingType, // 'rent' or 'sale'
    required String priceUnit,
    // Rent fields
    double? rentAmount,
    double? securityDeposit,
    double? maintenanceAmount,
    // Sale fields
    double? totalPrice,
    double? ratePerUnit,
    double? bookingPrice,
  }) async {
    final Map<String, dynamic> body = {
      "listing_type": listingType,
      "price_unit": priceUnit,
    };

    if (listingType == 'rent') {
      body["rent_amount"] = rentAmount;
      body["security_deposit"] = securityDeposit;
      body["maintenance_amount"] = maintenanceAmount;
    } else {
      body["total_price"] = totalPrice;
      body["rate_per_unit"] = ratePerUnit;
      body["booking_price"] = bookingPrice;
    }

    final response = await ApiService.authorizedRequest((token) {
      final url = Uri.parse("${ApiService.baseUrl}/properties/$propertyId/");
      return http.patch(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode(body),
      );
    });

    if (response.statusCode == 200) {
      return {"success": true, "data": jsonDecode(response.body)};
    } else {
      return {"success": false, "error": response.body};
    }
  }

  static Future<Map<String, dynamic>> fetchPropertyRaw(int propertyId) async {
    final url = Uri.parse("${ApiService.baseUrl}/properties/$propertyId/");
    final response = await http.get(url);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Failed to load property");
    }
  }

  static Future<Map<String, dynamic>> updateAttributes({
    required int propertyId,
    required Map<String, String> attributes,
  }) async {
    final response = await ApiService.authorizedRequest((token) {
      final url = Uri.parse("${ApiService.baseUrl}/properties/$propertyId/");
      return http.patch(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({
          "attributes": attributes,
        }),
      );
    });

    if (response.statusCode == 200) {
      return {"success": true, "data": jsonDecode(response.body)};
    } else {
      return {"success": false, "error": response.body};
    }
  }

  static Future<Map<String, dynamic>> uploadAttributeFile({
    required int propertyId,
    required int attributeDefinitionId,
    required String filePath,
  }) async {
    final token = await ApiService.getAccessToken();
    if (token == null) {
      return {"success": false, "error": "Login required"};
    }

    final url = Uri.parse("${ApiService.baseUrl}/properties/$propertyId/upload_attribute_file/");
    final request = http.MultipartRequest('POST', url);
    request.headers['Authorization'] = "Bearer $token";
    request.fields['attribute_definition_id'] = attributeDefinitionId.toString();
    request.files.add(await http.MultipartFile.fromPath('file', filePath));

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      return {"success": true, "data": jsonDecode(response.body)};
    } else {
      return {"success": false, "error": response.body};
    }
  }

  static Future<Map<String, dynamic>> uploadImage({
    required int propertyId,
    required String filePath,
  }) async {
    final token = await ApiService.getAccessToken();
    if (token == null) {
      return {"success": false, "error": "Login required"};
    }

    final url = Uri.parse("${ApiService.baseUrl}/properties/$propertyId/upload_image/");
    final request = http.MultipartRequest('POST', url);
    request.headers['Authorization'] = "Bearer $token";
    request.files.add(await http.MultipartFile.fromPath('file', filePath));

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      return {"success": true, "data": jsonDecode(response.body)};
    } else {
      return {"success": false, "error": response.body};
    }
  }

  static Future<Map<String, dynamic>> deleteImage({
    required int propertyId,
    required int mediaId,
  }) async {
    final response = await ApiService.authorizedRequest((token) {
      final url = Uri.parse("${ApiService.baseUrl}/properties/$propertyId/delete_image/");
      return http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({"media_id": mediaId}),
      );
    });

    if (response.statusCode == 200) {
      return {"success": true};
    } else {
      return {"success": false, "error": response.body};
    }
  }

  static Future<Map<String, dynamic>> reorderImages({
    required int propertyId,
    required List<int> mediaIds,
  }) async {
    final response = await ApiService.authorizedRequest((token) {
      final url = Uri.parse("${ApiService.baseUrl}/properties/$propertyId/reorder_images/");
      return http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({"media_ids": mediaIds}),
      );
    });

    if (response.statusCode == 200) {
      return {"success": true};
    } else {
      return {"success": false, "error": response.body};
    }
  }

  // ---------- NAYA: Cover photo set karna ----------
  static Future<Map<String, dynamic>> setCoverImage({
    required int propertyId,
    required int mediaId,
  }) async {
    final response = await ApiService.authorizedRequest((token) {
      final url = Uri.parse("${ApiService.baseUrl}/properties/$propertyId/set_cover_image/");
      return http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({"media_id": mediaId}),
      );
    });

    if (response.statusCode == 200) {
      return {"success": true};
    } else {
      return {"success": false, "error": response.body};
    }
  }

  // ---------- NAYA: YouTube video link add karna ----------
  static Future<Map<String, dynamic>> addVideo({
    required int propertyId,
    required String videoUrl,
  }) async {
    final response = await ApiService.authorizedRequest((token) {
      final url = Uri.parse("${ApiService.baseUrl}/properties/$propertyId/add_video/");
      return http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({"video_url": videoUrl}),
      );
    });

    if (response.statusCode == 200) {
      return {"success": true, "data": jsonDecode(response.body)};
    } else {
      try {
        final body = jsonDecode(response.body);
        return {"success": false, "error": body["error"] ?? "Could not add video."};
      } catch (e) {
        return {"success": false, "error": "Could not add video."};
      }
    }
  }

  // ---------- NAYA: Description save karna ----------
  static Future<Map<String, dynamic>> updateDescription({
    required int propertyId,
    required String description,
  }) async {
    final response = await ApiService.authorizedRequest((token) {
      final url = Uri.parse("${ApiService.baseUrl}/properties/$propertyId/");
      return http.patch(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({"description": description}),
      );
    });

    if (response.statusCode == 200) {
      return {"success": true, "data": jsonDecode(response.body)};
    } else {
      return {"success": false, "error": response.body};
    }
  }

  // ---------- NAYA: Final Submit for Review ----------
  static Future<Map<String, dynamic>> submitForReview(int propertyId) async {
    final response = await ApiService.authorizedRequest((token) {
      final url = Uri.parse("${ApiService.baseUrl}/properties/$propertyId/submit_for_review/");
      return http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );
    });

    if (response.statusCode == 200) {
      return {"success": true, "data": jsonDecode(response.body)};
    } else {
      // Backend "error" field mein missing fields ki wajah batata hai
      try {
        final body = jsonDecode(response.body);
        return {"success": false, "error": body["error"] ?? "Submission failed."};
      } catch (e) {
        return {"success": false, "error": "Submission failed."};
      }
    }
  }
}