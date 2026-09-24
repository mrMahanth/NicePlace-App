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
    required String pincode,
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
          "pincode": pincode,
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

  static Future<Map<String, dynamic>> updatePricing({
    required int propertyId,
    required String listingType,
    required String priceUnit,
    double? rentAmount,
    bool rentNegotiable = false,
    double? securityDeposit,
    bool securityDepositNegotiable = false,
    double? maintenanceAmount,
    bool maintenanceNegotiable = false,
    double? totalPrice,
    bool totalPriceNegotiable = false,
    double? ratePerUnit,
    bool ratePerUnitNegotiable = false,
    double? bookingPrice,
    bool bookingPriceNegotiable = false,
  }) async {
    final Map<String, dynamic> body = {
      "listing_type": listingType,
      "price_unit": priceUnit,
    };

    if (listingType == 'rent') {
      body["rent_amount"] = rentAmount;
      body["rent_negotiable"] = rentNegotiable;
      body["security_deposit"] = securityDeposit;
      body["security_deposit_negotiable"] = securityDepositNegotiable;
      body["maintenance_amount"] = maintenanceAmount;
      body["maintenance_negotiable"] = maintenanceNegotiable;
    } else {
      body["total_price"] = totalPrice;
      body["total_price_negotiable"] = totalPriceNegotiable;
      body["rate_per_unit"] = ratePerUnit;
      body["rate_per_unit_negotiable"] = ratePerUnitNegotiable;
      body["booking_price"] = bookingPrice;
      body["booking_price_negotiable"] = bookingPriceNegotiable;
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
      try {
        final body = jsonDecode(response.body);
        return {"success": false, "error": body["error"] ?? "Submission failed."};
      } catch (e) {
        return {"success": false, "error": "Submission failed."};
      }
    }
  }

  static Future<Map<String, dynamic>> addNearbyPlace({
    required int propertyId,
    required int categoryId,
    required String name,
    double? distanceValue,
    required String distanceUnit,
  }) async {
    final response = await ApiService.authorizedRequest((token) {
      final url = Uri.parse("${ApiService.baseUrl}/properties/$propertyId/add_nearby_place/");
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

  static Future<Map<String, dynamic>> deleteNearbyPlace({
    required int propertyId,
    required int placeId,
  }) async {
    final response = await ApiService.authorizedRequest((token) {
      final url = Uri.parse("${ApiService.baseUrl}/properties/$propertyId/delete_nearby_place/");
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

    // ---------- Project ke units fetch karna ----------
  static Future<List<Map<String, dynamic>>> fetchUnitsForProject(int projectId) async {
    final response = await ApiService.authorizedRequest((token) {
      final url = Uri.parse("${ApiService.baseUrl}/properties/my_properties/?project=$projectId");
      return http.get(url, headers: {"Authorization": "Bearer $token"});
    });

    if (response.statusCode == 200) {
      final List<dynamic> jsonList = jsonDecode(response.body);
      return jsonList.cast<Map<String, dynamic>>();
    } else {
      throw Exception("Failed to load units");
    }
  }

  // ---------- Property/Unit delete karna (soft-delete, backend handle karta hai) ----------
  static Future<Map<String, dynamic>> deleteProperty(int propertyId) async {
    final response = await ApiService.authorizedRequest((token) {
      final url = Uri.parse("${ApiService.baseUrl}/properties/$propertyId/");
      return http.delete(url, headers: {"Authorization": "Bearer $token"});
    });

    if (response.statusCode == 200 || response.statusCode == 204) {
      return {"success": true};
    } else {
      return {"success": false, "error": response.body};
    }
  }
}