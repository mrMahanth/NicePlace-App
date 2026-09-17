class PropertyMedia {
  final int id;
  final String? file;
  final String? videoUrl;
  final String mediaType; // 'image' or 'video'
  final int order;
  final bool isCover;

  PropertyMedia({
    required this.id,
    this.file,
    this.videoUrl,
    required this.mediaType,
    this.order = 0,
    this.isCover = false,
  });

  factory PropertyMedia.fromJson(Map<String, dynamic> json) {
    return PropertyMedia(
      id: json['id'],
      file: json['file'],
      videoUrl: json['video_url'],
      mediaType: json['media_type'] ?? 'image',
      order: json['order'] ?? 0,
      isCover: json['is_cover'] ?? false,
    );
  }
}


class PropertyTagInfo {
  final int id;
  final String name;
  final String badgeIcon;
  final String? badgeColor;

  PropertyTagInfo({
    required this.id,
    required this.name,
    this.badgeIcon = 'none',
    this.badgeColor,
  });

  factory PropertyTagInfo.fromJson(Map<String, dynamic> json) {
    return PropertyTagInfo(
      id: json['tag_id'] ?? 0,
      name: json['tag_name'] ?? '',
      badgeIcon: json['badge_icon'] ?? 'none',
      badgeColor: json['badge_color'],
    );
  }
}

// Generic class for dynamic attributes (BHK, Furnishing, etc.)
// New attributes added from admin panel will automatically work here.
class PropertyAttribute {
  final String name;
  final String value;
  final String unitValue;

  PropertyAttribute({
    required this.name,
    required this.value,
    required this.unitValue,
  });

  factory PropertyAttribute.fromJson(Map<String, dynamic> json) {
    return PropertyAttribute(
      name: json['attribute_name'] ?? '',
      value: json['value'] ?? '',
      unitValue: json['unit_value'] ?? '',
    );
  }
}

class Property {
  final int id;
  final String title;
  final String description;
  final String price;
  final String priceUnit;
  final String listingType;
  final String listedAs;
  final String propertyType;
  final String status;
  final String locality;
  final String city;
  final String district;
  final String state;
  final String country;
  final double? latitude;
  final double? longitude;
  final String ownerName;
  final String? ownerPhone;
  final List<PropertyMedia> media;
  final List<PropertyAttribute> attributeValues;
  final List<PropertyTagInfo> tags;

  Property({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.priceUnit,
    required this.listingType,
    required this.listedAs,
    required this.propertyType,
    required this.status,
    required this.locality,
    required this.city,
    required this.district,
    required this.state,
    required this.country,
    required this.latitude,
    required this.longitude,
    required this.ownerName,
    required this.ownerPhone,
    required this.media,
    required this.attributeValues,
    required this.tags,
  });

  factory Property.fromJson(Map<String, dynamic> json) {
    return Property(
      id: json['id'],
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      price: json['price'] ?? '0',
      priceUnit: json['price_unit'] ?? 'total',
      listingType: json['listing_type'] ?? '',
      listedAs: json['listed_as'] ?? '',
      propertyType: json['property_type'] ?? '',
      status: json['status'] ?? '',
      locality: json['locality'] ?? '',
      city: json['city'] ?? '',
      district: json['district'] ?? '',
      state: json['state'] ?? '',
      country: json['country'] ?? '',
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      ownerName: json['owner_name'] ?? '',
      ownerPhone: json['owner_phone'],
      media: (json['media'] as List<dynamic>? ?? [])
          .map((m) => PropertyMedia.fromJson(m))
          .toList(),
      attributeValues: (json['attribute_values'] as List<dynamic>? ?? [])
          .map((a) => PropertyAttribute.fromJson(a))
          .toList(),
      tags: (json['tags'] as List<dynamic>? ?? [])
          .map((t) => PropertyTagInfo.fromJson(t))
          .toList(),
    );
  }
}