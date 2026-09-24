import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/property_type_model.dart';
import '../models/property_category_model.dart';
import '../models/attribute_definition_model.dart';
import '../models/nearby_place_model.dart';
import 'api_service.dart';

class PropertyTypeService {
  static Future<List<PropertyTypeModel>> fetchPropertyTypes() async {
    final url = Uri.parse("${ApiService.baseUrl}/property-types/");
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final List<dynamic> jsonList = jsonDecode(response.body);
      return jsonList.map((json) => PropertyTypeModel.fromJson(json)).toList();
    } else {
      throw Exception("Failed to load property types");
    }
  }

  static Future<List<PropertyCategoryModel>> fetchPropertyCategories() async {
    final url = Uri.parse("${ApiService.baseUrl}/property-categories/");
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final List<dynamic> jsonList = jsonDecode(response.body);
      return jsonList.map((json) => PropertyCategoryModel.fromJson(json)).toList();
    } else {
      throw Exception("Failed to load property categories");
    }
  }

  static Future<List<AttributeDefinitionModel>> fetchAttributeDefinitions(
      int propertyTypeId) async {
    final url = Uri.parse(
        "${ApiService.baseUrl}/attribute-definitions/?property_type=$propertyTypeId");
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final List<dynamic> jsonList = jsonDecode(response.body);
      return jsonList.map((json) => AttributeDefinitionModel.fromJson(json)).toList();
    } else {
      throw Exception("Failed to load attributes");
    }
  }

  // ---------- NAYA: Nearby Place categories fetch karna (admin-defined) ----------
  static Future<List<NearbyPlaceCategoryModel>> fetchNearbyPlaceCategories() async {
    final url = Uri.parse("${ApiService.baseUrl}/nearby-place-categories/");
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final List<dynamic> jsonList = jsonDecode(response.body);
      return jsonList.map((json) => NearbyPlaceCategoryModel.fromJson(json)).toList();
    } else {
      throw Exception("Failed to load nearby place categories");
    }
  }
}