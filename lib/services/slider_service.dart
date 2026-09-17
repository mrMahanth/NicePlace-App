import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/slider_model.dart';
import '../models/property_model.dart';
import 'api_service.dart';

class SliderService {
  // Public endpoint (AllowAny) - matches what the website homepage also calls.
  static Future<List<SliderModel>> fetchActiveSliders() async {
    final uri = Uri.parse('${ApiService.baseUrl}/sliders/active/');
    final response = await http.get(uri);
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((e) => SliderModel.fromJson(e)).toList();
    }
    throw Exception('Could not load sliders');
  }

  // A slider only carries the destination property's ID, not its full
  // details - this fetches the real Property object before navigating to
  // PropertyDetailScreen.
  // NOTE: assumes Property.fromJson exists on your model, matching how
  // PropertyService presumably parses list results elsewhere. If your
  // property_model.dart doesn't have this constructor, let me know and
  // I'll adjust this to match your actual model.
  static Future<Property> fetchPropertyById(int id) async {
    final uri = Uri.parse('${ApiService.baseUrl}/properties/$id/');
    final response = await http.get(uri);
    if (response.statusCode == 200) {
      return Property.fromJson(jsonDecode(response.body));
    }
    throw Exception('Could not load property');
  }
}