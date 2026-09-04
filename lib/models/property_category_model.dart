class PropertyCategoryModel {
  final int id;
  final String name;
  final String slug;
  final String description;
  final String color;

  PropertyCategoryModel({
    required this.id,
    required this.name,
    required this.slug,
    required this.description,
    required this.color,
  });

  factory PropertyCategoryModel.fromJson(Map<String, dynamic> json) {
    return PropertyCategoryModel(
      id: json['id'],
      name: json['name'] ?? '',
      slug: json['slug'] ?? '',
      description: json['description'] ?? '',
      color: json['color'] ?? '#2e7d32',
    );
  }
}