class SliderModel {
  final int id;
  final String title;
  final String? imageWebUrl;
  final String? imageMobileUrl;
  final String destinationType;
  final String? externalUrl;
  final int? destinationPropertyId;
  final int? destinationProjectId;
  final int? destinationPropertyTypeId;
  final int? destinationCategoryId;
  final String? destinationUsername;
  final String? internalPageAppScreenKey;
  final String? searchLocality;
  final int? searchPropertyTypeId;
  final String? searchListingType;

  SliderModel({
    required this.id,
    required this.title,
    this.imageWebUrl,
    this.imageMobileUrl,
    required this.destinationType,
    this.externalUrl,
    this.destinationPropertyId,
    this.destinationProjectId,
    this.destinationPropertyTypeId,
    this.destinationCategoryId,
    this.destinationUsername,
    this.internalPageAppScreenKey,
    this.searchLocality,
    this.searchPropertyTypeId,
    this.searchListingType,
  });

  factory SliderModel.fromJson(Map<String, dynamic> json) {
    return SliderModel(
      id: json['id'],
      title: json['title'] ?? '',
      imageWebUrl: json['image_web'],
      imageMobileUrl: json['image_mobile'],
      destinationType: json['destination_type'] ?? 'none',
      externalUrl: json['external_url'],
      destinationPropertyId: json['destination_property'],
      destinationProjectId: json['destination_project'],
      destinationPropertyTypeId: json['destination_property_type'],
      destinationCategoryId: json['destination_category'],
      destinationUsername: json['destination_username'],
      internalPageAppScreenKey: json['internal_page_app_screen_key'],
      searchLocality: json['search_locality'],
      searchPropertyTypeId: json['search_property_type'],
      searchListingType: json['search_listing_type'],
    );
  }

  // App-specific crop if the admin uploaded one, otherwise fall back to the
  // website's image so a slide still shows something rather than nothing.
  String? get displayImageUrl {
    if (imageMobileUrl != null && imageMobileUrl!.isNotEmpty) return imageMobileUrl;
    return imageWebUrl;
  }
}