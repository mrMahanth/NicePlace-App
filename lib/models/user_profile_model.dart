class UserTagInfo {
  final int id;
  final String name;
  final String description;
  final String badgeIcon;
  final String? badgeColor;

  UserTagInfo({
    required this.id,
    required this.name,
    required this.description,
    this.badgeIcon = 'none',
    this.badgeColor,
  });

  factory UserTagInfo.fromJson(Map<String, dynamic> json) {
    return UserTagInfo(
      id: json['id'],
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      badgeIcon: json['badge_icon'] ?? 'none',
      badgeColor: json['badge_color'],
    );
  }
}

class DisplayedTag {
  final int id;
  final String name;
  final String badgeIcon;
  final String? badgeColor;

  DisplayedTag({required this.id, required this.name, required this.badgeIcon, this.badgeColor});

  factory DisplayedTag.fromJson(Map<String, dynamic> json) {
    return DisplayedTag(
      id: json['id'],
      name: json['name'] ?? '',
      badgeIcon: json['badge_icon'] ?? 'none',
      badgeColor: json['badge_color'],
    );
  }
}

class UserProfileModel {
  final String? profilePhoto;
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
  final DisplayedTag? displayedTag;

  UserProfileModel({
    this.profilePhoto,
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
    this.displayedTag,
  });

  // Convenience getter - true if this user can manage tags (superuser or has the specific permission)
  bool get canManageTags =>
      isSuperuser || permissions.contains('can_manage_marketing_tags');

  factory UserProfileModel.fromJson(Map<String, dynamic> json) {
    return UserProfileModel(
      profilePhoto: json['profile_photo'],
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
      displayedTag: json['displayed_tag'] != null
          ? DisplayedTag.fromJson(json['displayed_tag'])
          : null,
    );
  }
}