import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/property_model.dart';
import 'api_service.dart';

class PropertyService {
  static Future<List<Property>> fetchProperties() async {
    final url = Uri.parse("${ApiService.baseUrl}/properties/");
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final List<dynamic> jsonList = jsonDecode(response.body);
      return jsonList.map((json) => Property.fromJson(json)).toList();
    } else {
      throw Exception("Failed to load properties");
    }
  }
}