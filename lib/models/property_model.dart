import 'nearby_place_model.dart';

// Backend DecimalFields JSON mein string ("5000.00") ya number, dono form mein aa sakte hain.
double? _parseDouble(dynamic v) {
  if (v == null) return null;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString());
}

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
  final int id;
  final String name;
  final String attributeType; // textbox, textarea, number, dropdown, radio, checkbox, file
  final String value;
  final String unitValue;
  final String unitLabel;
  final String? file;
  final bool showOnCard;

  PropertyAttribute({
    this.id = 0,
    required this.name,
    required this.value,
    required this.unitValue,
    this.attributeType = 'textbox',
    this.unitLabel = '',
    this.file,
    this.showOnCard = false,
  });

  factory PropertyAttribute.fromJson(Map<String, dynamic> json) {
    return PropertyAttribute(
      id: json['id'] ?? 0,
      name: json['attribute_name'] ?? '',
      attributeType: json['attribute_type'] ?? 'textbox',
      value: json['value'] ?? '',
      unitValue: json['unit_value'] ?? '',
      unitLabel: json['unit_label'] ?? '',
      file: json['file'],
      showOnCard: json['show_on_card'] ?? false,
    );
  }
}

class Property {
  final int id;
  final String title;
  final String description;
  final String price; // legacy field, purani properties mein sirf yahi bhara hota hai
  final String priceUnit;
  final String listingType;
  final String listedAs;
  final String propertyType;
  final String status;
  final String rejectionReason;
  final String locality;
  final String city;
  final String pincode;
  final String district;
  final String state;
  final String country;
  final double? latitude;
  final double? longitude;

  // Owner
  final String ownerName; // backend ka username (phone ho sakta hai) - screen par mat dikhana
  final int? ownerId;
  final String ownerDisplayName; // public display ke liye safe naam
  final String? ownerPhone;

  // Project / booking
  final int? projectId;
  final String? projectName;
  final bool isBookable;

  // Rent pricing
  final double? rentAmount;
  final double? securityDeposit;
  final double? maintenanceAmount;
  final bool rentNegotiable;
  final bool securityDepositNegotiable;
  final bool maintenanceNegotiable;

  // Sale pricing
  final double? ratePerUnit;
  final double? totalPrice;
  final double? bookingPrice;
  final bool ratePerUnitNegotiable;
  final bool totalPriceNegotiable;
  final bool bookingPriceNegotiable;

  final List<PropertyMedia> media;
  final List<PropertyAttribute> attributeValues;
  final List<PropertyTagInfo> tags;
  final List<NearbyPlaceModel> nearbyPlaces;

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
    this.rejectionReason = '',
    required this.locality,
    required this.city,
    this.pincode = '',
    required this.district,
    required this.state,
    required this.country,
    required this.latitude,
    required this.longitude,
    required this.ownerName,
    this.ownerId,
    this.ownerDisplayName = '',
    required this.ownerPhone,
    this.projectId,
    this.projectName,
    this.isBookable = false,
    this.rentAmount,
    this.securityDeposit,
    this.maintenanceAmount,
    this.rentNegotiable = false,
    this.securityDepositNegotiable = false,
    this.maintenanceNegotiable = false,
    this.ratePerUnit,
    this.totalPrice,
    this.bookingPrice,
    this.ratePerUnitNegotiable = false,
    this.totalPriceNegotiable = false,
    this.bookingPriceNegotiable = false,
    required this.media,
    required this.attributeValues,
    required this.tags,
    this.nearbyPlaces = const [],
  });

  factory Property.fromJson(Map<String, dynamic> json) {
    return Property(
      id: json['id'],
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      price: json['price']?.toString() ?? '0',
      priceUnit: json['price_unit'] ?? 'total',
      listingType: json['listing_type'] ?? '',
      listedAs: json['listed_as'] ?? '',
      propertyType: json['property_type'] ?? '',
      status: json['status'] ?? '',
      rejectionReason: json['rejection_reason'] ?? '',
      locality: json['locality'] ?? '',
      city: json['city'] ?? '',
      pincode: json['pincode'] ?? '',
      district: json['district'] ?? '',
      state: json['state'] ?? '',
      country: json['country'] ?? '',
      latitude: _parseDouble(json['latitude']),
      longitude: _parseDouble(json['longitude']),
      ownerName: json['owner_name'] ?? '',
      ownerId: json['owner_id'],
      ownerDisplayName: json['owner_display_name'] ?? '',
      ownerPhone: json['owner_phone'],
      projectId: json['project'],
      projectName: json['project_name'],
      isBookable: json['is_bookable'] ?? false,
      rentAmount: _parseDouble(json['rent_amount']),
      securityDeposit: _parseDouble(json['security_deposit']),
      maintenanceAmount: _parseDouble(json['maintenance_amount']),
      rentNegotiable: json['rent_negotiable'] ?? false,
      securityDepositNegotiable: json['security_deposit_negotiable'] ?? false,
      maintenanceNegotiable: json['maintenance_negotiable'] ?? false,
      ratePerUnit: _parseDouble(json['rate_per_unit']),
      totalPrice: _parseDouble(json['total_price']),
      bookingPrice: _parseDouble(json['booking_price']),
      ratePerUnitNegotiable: json['rate_per_unit_negotiable'] ?? false,
      totalPriceNegotiable: json['total_price_negotiable'] ?? false,
      bookingPriceNegotiable: json['booking_price_negotiable'] ?? false,
      media: (json['media'] as List<dynamic>? ?? [])
          .map((m) => PropertyMedia.fromJson(m))
          .toList(),
      attributeValues: (json['attribute_values'] as List<dynamic>? ?? [])
          .map((a) => PropertyAttribute.fromJson(a))
          .toList(),
      tags: (json['tags'] as List<dynamic>? ?? [])
          .map((t) => PropertyTagInfo.fromJson(t))
          .toList(),
      nearbyPlaces: (json['nearby_places'] as List<dynamic>? ?? [])
          .map((n) => NearbyPlaceModel.fromJson(n))
          .toList(),
    );
  }
}