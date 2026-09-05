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
    // Query parameters build karte hain - sirf jo values di gayi hain unhi ko bhejenge
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

  // ---------- NAYA FUNCTION: Draft Property create karna ----------
  // "Individual" flow ka Step 1 - user Property Type choose karte hi
  // ye backend pe ek khaali draft Property bana deta hai. Baaki steps
  // isi property ke id ko PATCH karte rahenge.
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
}