import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class LocationResult {
  final String city;
  final String locality;

  LocationResult({required this.city, required this.locality});
}

class LocationHelper {
  /// Gets the device's current GPS position, then reverse-geocodes it into
  /// a city + locality name. Handles permission requests along the way.
  /// Throws a String error message if location can't be determined, so the
  /// calling screen can show a friendly fallback instead of crashing.
  static Future<LocationResult> getCurrentCityAndLocality() async {
    // 1. Check if location services (GPS) are turned on at all.
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw 'Location services are turned off. Please enable GPS.';
    }

    // 2. Check current permission status.
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      // Ask the user for permission.
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw 'Location permission was denied.';
      }
    }
    if (permission == LocationPermission.deniedForever) {
      throw 'Location permission is permanently denied. Please enable it from app settings.';
    }

    // 3. Get the actual GPS coordinates.
    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.medium),
    );

    // 4. Convert coordinates into a readable city/locality name.
    // geocoding 5.0.0+ moved from a top-level function to an instance method.
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

    return LocationResult(city: city, locality: locality);
  }
}