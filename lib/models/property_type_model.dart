class PropertyTypeModel {
  final int id;
  final String name;
  final String slug;
  final int? categoryId;
  final String? categoryName;
  final bool isBookable;
  final String? iconUrl;

  PropertyTypeModel({
    required this.id,
    required this.name,
    this.slug = '',
    this.categoryId,
    this.categoryName,
    this.isBookable = false,
    this.iconUrl,
  });

  factory PropertyTypeModel.fromJson(Map<String, dynamic> json) {
    return PropertyTypeModel(
      id: json['id'],
      name: json['name'] ?? '',
      slug: json['slug'] ?? '',
      categoryId: json['category'],
      categoryName: json['category_name'],
      isBookable: json['is_bookable'] ?? false,
      iconUrl: json['icon'],
    );
  }
}