class NearbyPlaceCategoryModel {
  final int id;
  final String name;
  final String? iconUrl;

  NearbyPlaceCategoryModel({required this.id, required this.name, this.iconUrl});

  factory NearbyPlaceCategoryModel.fromJson(Map<String, dynamic> json) {
    return NearbyPlaceCategoryModel(
      id: json['id'],
      name: json['name'] ?? '',
      iconUrl: json['icon'],
    );
  }
}

class NearbyPlaceModel {
  final int id;
  final int categoryId;
  final String categoryName;
  final String? categoryIconUrl;
  final String name;
  final double? distanceValue;
  final String distanceUnit;

  NearbyPlaceModel({
    required this.id,
    required this.categoryId,
    required this.categoryName,
    this.categoryIconUrl,
    required this.name,
    this.distanceValue,
    required this.distanceUnit,
  });

  factory NearbyPlaceModel.fromJson(Map<String, dynamic> json) {
    return NearbyPlaceModel(
      id: json['id'],
      categoryId: json['category'],
      categoryName: json['category_name'] ?? '',
      categoryIconUrl: json['category_icon'],
      name: json['name'] ?? '',
      distanceValue: (json['distance_value'] as num?)?.toDouble(),
      distanceUnit: json['distance_unit'] ?? 'km',
    );
  }
}