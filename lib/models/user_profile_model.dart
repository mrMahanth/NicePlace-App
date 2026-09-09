class UserTagInfo {
  final int id;
  final String name;
  final String description;

  UserTagInfo({required this.id, required this.name, required this.description});

  factory UserTagInfo.fromJson(Map<String, dynamic> json) {
    return UserTagInfo(
      id: json['id'],
      name: json['name'] ?? '',
      description: json['description'] ?? '',
    );
  }
}

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

  // Admin/permission info
  final bool isStaff;
  final bool isSuperuser;
  final List<String> permissions;
  final List<UserTagInfo> tags;

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
    required this.isStaff,
    required this.isSuperuser,
    required this.permissions,
    required this.tags,
  });

  // Convenience getter - true if this user can manage tags (superuser or has the specific permission)
  bool get canManageTags =>
      isSuperuser || permissions.contains('can_manage_marketing_tags');

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
      isStaff: json['is_staff'] ?? false,
      isSuperuser: json['is_superuser'] ?? false,
      permissions: (json['permissions'] as List<dynamic>? ?? [])
          .map((p) => p.toString())
          .toList(),
      tags: (json['tags'] as List<dynamic>? ?? [])
          .map((t) => UserTagInfo.fromJson(t))
          .toList(),
    );
  }
}