import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class LocationResult {
  final String city;
  final String locality;
  final double latitude;
  final double longitude;

  LocationResult({
    required this.city,
    required this.locality,
    required this.latitude,
    required this.longitude,
  });
}

class LocationHelper {
  static Future<LocationResult> getCurrentCityAndLocality() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw 'Location services are turned off. Please enable GPS.';
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw 'Location permission was denied.';
      }
    }
    if (permission == LocationPermission.deniedForever) {
      throw 'Location permission is permanently denied. Please enable it from app settings.';
    }

    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.medium),
    );

    final geocoding = Geocoding();
    final placemarks = await geocoding.placemarkFromCoordinates(
      position.latitude,
      position.longitude,
    );
    if (placemarks.isEmpty) {
      throw 'Could not determine your address from GPS.';
    }
    final place = placemarks.first;

    final city = place.locality ?? place.subAdministrativeArea ?? 'Unknown city';
    final locality = place.subLocality ?? place.street ?? '';

    return LocationResult(
      city: city,
      locality: locality,
      latitude: position.latitude,   // === added ===
      longitude: position.longitude, // === added ===
    );
  }
}