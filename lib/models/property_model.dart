class PropertyMedia {
  final int id;
  final String file;
  final String mediaType;

  PropertyMedia({required this.id, required this.file, required this.mediaType});

  factory PropertyMedia.fromJson(Map<String, dynamic> json) {
    return PropertyMedia(
      id: json['id'],
      file: json['file'] ?? '',
      mediaType: json['media_type'] ?? '',
    );
  }
}

class Property {
  final int id;
  final String title;
  final String description;
  final String price;
  final String listingType;
  final String propertyType;
  final String locality;
  final String city;
  final String ownerName;
  final List<PropertyMedia> media;

  Property({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.listingType,
    required this.propertyType,
    required this.locality,
    required this.city,
    required this.ownerName,
    required this.media,
  });

  factory Property.fromJson(Map<String, dynamic> json) {
    return Property(
      id: json['id'],
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      price: json['price'] ?? '0',
      listingType: json['listing_type'] ?? '',
      propertyType: json['property_type'] ?? '',
      locality: json['locality'] ?? '',
      city: json['city'] ?? '',
      ownerName: json['owner_name'] ?? '',
      media: (json['media'] as List<dynamic>? ?? [])
          .map((m) => PropertyMedia.fromJson(m))
          .toList(),
    );
  }
}