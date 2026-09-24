class ProjectModel {
  final int id;
  final String name;
  final String builderName;
  final int? propertyTypeId;
  final String propertyTypeName;
  final String locality;
  final String city;
  final String pincode;
  final String country;
  final String state;
  final String district;
  final double? latitude;
  final double? longitude;
  final int? totalUnits;
  final String listingType;
  final double? startingPrice;
  final String description;
  final bool detailsComplete;
  final String approvalStatus;
  final String rejectionReason;

  ProjectModel({
    required this.id,
    required this.name,
    required this.builderName,
    this.propertyTypeId,
    required this.propertyTypeName,
    required this.locality,
    required this.city,
    required this.pincode,
    required this.country,
    required this.state,
    required this.district,
    this.latitude,
    this.longitude,
    this.totalUnits,
    required this.listingType,
    this.startingPrice,
    required this.description,
    required this.detailsComplete,
    required this.approvalStatus,
    required this.rejectionReason,
  });

  factory ProjectModel.fromJson(Map<String, dynamic> json) {
    return ProjectModel(
      id: json['id'],
      name: json['name'] ?? '',
      builderName: json['builder_name'] ?? '',
      propertyTypeId: json['property_type_pk'],
      propertyTypeName: json['property_type'] ?? '',
      locality: json['locality'] ?? '',
      city: json['city'] ?? '',
      pincode: json['pincode'] ?? '',
      country: json['country'] ?? 'India',
      state: json['state'] ?? '',
      district: json['district'] ?? '',
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      totalUnits: json['total_units'],
      listingType: json['listing_type'] ?? '',
      startingPrice: (json['starting_price'] as num?)?.toDouble(),
      description: json['description'] ?? '',
      detailsComplete: json['details_complete'] ?? false,
      approvalStatus: json['approval_status'] ?? 'draft',
      rejectionReason: json['rejection_reason'] ?? '',
    );
  }
}