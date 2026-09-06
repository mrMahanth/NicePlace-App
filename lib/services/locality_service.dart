import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_service.dart';

class LocalityService {
  // Public endpoint (AllowAny on the backend) - no auth token needed.
  static Future<List<String>> fetchLocalitiesWithProperties({
    String? city,
    String? query,
  }) async {
    final params = <String, String>{};
    if (city != null) params['city'] = city;
    if (query != null && query.trim().isNotEmpty) params['q'] = query.trim();

    final uri = Uri.parse('${ApiService.baseUrl}/properties/localities/')
        .replace(queryParameters: params.isEmpty ? null : params);

    final response = await http.get(uri);
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((e) => e.toString()).toList();
    }
    throw Exception('Could not load localities');
  }
}