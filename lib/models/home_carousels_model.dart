import 'property_model.dart';

class PropertyTypeCarousel {
  final int propertyTypeId;
  final String propertyTypeName;
  final List<Property> properties;

  PropertyTypeCarousel({
    required this.propertyTypeId,
    required this.propertyTypeName,
    required this.properties,
  });

  factory PropertyTypeCarousel.fromJson(Map<String, dynamic> json) {
    return PropertyTypeCarousel(
      propertyTypeId: json['property_type_id'],
      propertyTypeName: json['property_type_name'] ?? '',
      properties: (json['properties'] as List<dynamic>? ?? [])
          .map((p) => Property.fromJson(p))
          .toList(),
    );
  }
}

class HomeCarouselsResponse {
  final List<Property> featured;
  final List<Property> nearYou;
  final List<Property> recentlyAdded;
  final List<PropertyTypeCarousel> byType;

  HomeCarouselsResponse({
    required this.featured,
    required this.nearYou,
    required this.recentlyAdded,
    required this.byType,
  });

  factory HomeCarouselsResponse.fromJson(Map<String, dynamic> json) {
    return HomeCarouselsResponse(
      featured: (json['featured'] as List<dynamic>? ?? [])
          .map((p) => Property.fromJson(p))
          .toList(),
      nearYou: (json['near_you'] as List<dynamic>? ?? [])
          .map((p) => Property.fromJson(p))
          .toList(),
      recentlyAdded: (json['recently_added'] as List<dynamic>? ?? [])
          .map((p) => Property.fromJson(p))
          .toList(),
      byType: (json['by_type'] as List<dynamic>? ?? [])
          .map((t) => PropertyTypeCarousel.fromJson(t))
          .toList(),
    );
  }
}