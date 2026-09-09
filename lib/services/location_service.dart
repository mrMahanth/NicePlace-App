import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';

class LocationResult {
  final double latitude;
  final double longitude;
  final String displayAddress;
  final String locality;
  final String city;
  final String district;
  final String state;
  final String country;
  final String pincode;

  LocationResult({
    required this.latitude,
    required this.longitude,
    required this.displayAddress,
    required this.locality,
    required this.city,
    required this.district,
    required this.state,
    required this.country,
    this.pincode = '',
  });
}

class PincodeLookupResult {
  final String city;
  final String district;
  final String state;
  final String country;

  PincodeLookupResult({
    required this.city,
    required this.district,
    required this.state,
    required this.country,
  });
}

class LocationService {
  static const String _userAgent = "NicePlaceApp/1.0";

  static Future<Position> getCurrentPosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception("Location services are turned off. Please enable GPS.");
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception("Location permission was not granted.");
      }
    }
    if (permission == LocationPermission.deniedForever) {
      throw Exception("Location permission is disabled. Please enable it in phone settings.");
    }

    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  static Future<LocationResult> reverseGeocode(double lat, double lon) async {
    final url = Uri.parse(
      "https://nominatim.openstreetmap.org/reverse?format=json&lat=$lat&lon=$lon&addressdetails=1",
    );

    final response = await http.get(url, headers: {"User-Agent": _userAgent});

    if (response.statusCode != 200) {
      throw Exception("Could not fetch address.");
    }

    final data = jsonDecode(response.body);
    final address = data['address'] ?? {};

    return LocationResult(
      latitude: lat,
      longitude: lon,
      displayAddress: data['display_name'] ?? '',
      locality: address['suburb'] ?? address['neighbourhood'] ?? address['road'] ?? '',
      city: address['city'] ?? address['town'] ?? address['village'] ?? 'Patna',
      district: address['state_district'] ?? address['county'] ?? '',
      state: address['state'] ?? '',
      country: address['country'] ?? 'India',
      pincode: address['postcode'] ?? '',
    );
  }

  static Future<List<LocationResult>> searchAddress(String query) async {
    if (query.trim().isEmpty) return [];

    final url = Uri.parse(
      "https://nominatim.openstreetmap.org/search?format=json&q=${Uri.encodeComponent(query)}&addressdetails=1&limit=6",
    );

    final response = await http.get(url, headers: {"User-Agent": _userAgent});

    if (response.statusCode != 200) {
      throw Exception("Search failed.");
    }

    final List<dynamic> results = jsonDecode(response.body);

    return results.map((item) {
      final address = item['address'] ?? {};
      return LocationResult(
        latitude: double.parse(item['lat']),
        longitude: double.parse(item['lon']),
        displayAddress: item['display_name'] ?? '',
        locality: address['suburb'] ?? address['neighbourhood'] ?? address['road'] ?? '',
        city: address['city'] ?? address['town'] ?? address['village'] ?? 'Patna',
        district: address['state_district'] ?? address['county'] ?? '',
        state: address['state'] ?? '',
        country: address['country'] ?? 'India',
        pincode: address['postcode'] ?? '',
      );
    }).toList();
  }

  static Future<PincodeLookupResult> lookupPincode(String pincode) async {
    final url = Uri.parse("https://api.postalpincode.in/pincode/$pincode");
    final response = await http.get(url);

    if (response.statusCode != 200) {
      throw Exception("Pincode lookup failed.");
    }

    final List<dynamic> data = jsonDecode(response.body);
    if (data.isEmpty || data[0]['Status'] != 'Success') {
      throw Exception("This Pincode was not found. Please fill the fields manually.");
    }

    final List<dynamic> postOffices = data[0]['PostOffice'] ?? [];
    if (postOffices.isEmpty) {
      throw Exception("No details found for this Pincode.");
    }

    final po = postOffices[0];
    return PincodeLookupResult(
      city: po['District'] ?? '',
      district: po['District'] ?? '',
      state: po['State'] ?? '',
      country: po['Country'] ?? 'India',
    );
  }
}