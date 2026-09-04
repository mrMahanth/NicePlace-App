class UserProfileModel {
  final String username;
  final String firstName;
  final String lastName;
  final String email;
  final String phone;
  final bool isVerified;
  final String addressLine;
  final String pincode;
  final String locality;
  final String city;
  final String district;
  final String state;
  final String country;

  UserProfileModel({
    required this.username,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
    required this.isVerified,
    required this.addressLine,
    required this.pincode,
    required this.locality,
    required this.city,
    required this.district,
    required this.state,
    required this.country,
  });

  factory UserProfileModel.fromJson(Map<String, dynamic> json) {
    return UserProfileModel(
      username: json['username'] ?? '',
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      isVerified: json['is_verified'] ?? false,
      addressLine: json['address_line'] ?? '',
      pincode: json['pincode'] ?? '',
      locality: json['locality'] ?? '',
      city: json['city'] ?? '',
      district: json['district'] ?? '',
      state: json['state'] ?? '',
      country: json['country'] ?? '',
    );
  }
}