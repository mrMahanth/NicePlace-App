import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/property_type_model.dart';
import '../models/property_category_model.dart';
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

  // Categories - property types ko color-coded groups mein dikhane ke liye
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
}