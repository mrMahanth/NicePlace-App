class TagRequirement {
  final int id;
  final int tag;
  final String label;
  final String requirementType; // textbox, textarea, number, dropdown, radio, checkbox, file
  final String options;
  final bool isRequired;
  final int order;

  TagRequirement({
    required this.id,
    required this.tag,
    required this.label,
    required this.requirementType,
    required this.options,
    required this.isRequired,
    required this.order,
  });

  List<String> get optionsList =>
      options.split(',').map((o) => o.trim()).where((o) => o.isNotEmpty).toList();

  bool get requiresFile => requirementType == 'file';

  factory TagRequirement.fromJson(Map<String, dynamic> json) {
    return TagRequirement(
      id: json['id'],
      tag: json['tag'],
      label: json['label'] ?? '',
      requirementType: json['requirement_type'] ?? 'textbox',
      options: json['options'] ?? '',
      isRequired: json['is_required'] ?? true,
      order: json['order'] ?? 0,
    );
  }
}

class TagSlotLimit {
  final int id;
  final int tag;
  final int propertyType;
  final String propertyTypeName;
  final bool isProject;
  final int maxSlots;
  final int slotsUsed;
  final int slotsRemaining;

  TagSlotLimit({
    required this.id,
    required this.tag,
    required this.propertyType,
    required this.propertyTypeName,
    required this.isProject,
    required this.maxSlots,
    required this.slotsUsed,
    required this.slotsRemaining,
  });

  factory TagSlotLimit.fromJson(Map<String, dynamic> json) {
    return TagSlotLimit(
      id: json['id'],
      tag: json['tag'],
      propertyType: json['property_type'],
      propertyTypeName: json['property_type_name'] ?? '',
      isProject: json['is_project'] ?? false,
      maxSlots: json['max_slots'] ?? 0,
      slotsUsed: json['slots_used'] ?? 0,
      slotsRemaining: json['slots_remaining'] ?? 0,
    );
  }
}

class Tag {
  final int id;
  final String name;
  final String appliesTo; // user or property
  final String description;
  final String benefits;
  final String termsConditions;
  final String specialEffect;
  final String autoTrigger;
  final List<TagRequirement> requirements;
  final List<TagSlotLimit> slotLimits;

  Tag({
    required this.id,
    required this.name,
    required this.appliesTo,
    required this.description,
    required this.benefits,
    required this.termsConditions,
    required this.specialEffect,
    required this.autoTrigger,
    required this.requirements,
    required this.slotLimits,
  });

  factory Tag.fromJson(Map<String, dynamic> json) {
    return Tag(
      id: json['id'],
      name: json['name'] ?? '',
      appliesTo: json['applies_to'] ?? 'user',
      description: json['description'] ?? '',
      benefits: json['benefits'] ?? '',
      termsConditions: json['terms_conditions'] ?? '',
      specialEffect: json['special_effect'] ?? 'none',
      autoTrigger: json['auto_trigger'] ?? 'none',
      requirements: (json['requirements'] as List<dynamic>? ?? [])
          .map((r) => TagRequirement.fromJson(r))
          .toList(),
      slotLimits: (json['slot_limits'] as List<dynamic>? ?? [])
          .map((s) => TagSlotLimit.fromJson(s))
          .toList(),
    );
  }
}

class TagRequestAnswer {
  final int id;
  final int requirement;
  final String requirementLabel;
  final String textValue;
  final String? file;

  TagRequestAnswer({
    required this.id,
    required this.requirement,
    required this.requirementLabel,
    required this.textValue,
    required this.file,
  });

  factory TagRequestAnswer.fromJson(Map<String, dynamic> json) {
    return TagRequestAnswer(
      id: json['id'],
      requirement: json['requirement'],
      requirementLabel: json['requirement_label'] ?? '',
      textValue: json['text_value'] ?? '',
      file: json['file'],
    );
  }
}

class TagRequest {
  final int id;
  final int tag;
  final String tagName;
  final int applicant;
  final String applicantUsername;
  final int? targetProperty;
  final String propertyTitle;
  final String status; // pending, approved, rejected
  final String rejectionReason;
  final String requestedAt;
  final String? reviewedAt;
  final List<TagRequestAnswer> answers;

  TagRequest({
    required this.id,
    required this.tag,
    required this.tagName,
    required this.applicant,
    required this.applicantUsername,
    required this.targetProperty,
    required this.propertyTitle,
    required this.status,
    required this.rejectionReason,
    required this.requestedAt,
    required this.reviewedAt,
    required this.answers,
  });

  factory TagRequest.fromJson(Map<String, dynamic> json) {
    return TagRequest(
      id: json['id'],
      tag: json['tag'],
      tagName: json['tag_name'] ?? '',
      applicant: json['applicant'],
      applicantUsername: json['applicant_username'] ?? '',
      targetProperty: json['target_property'],
      propertyTitle: json['property_title'] ?? '',
      status: json['status'] ?? 'pending',
      rejectionReason: json['rejection_reason'] ?? '',
      requestedAt: json['requested_at'] ?? '',
      reviewedAt: json['reviewed_at'],
      answers: (json['answers'] as List<dynamic>? ?? [])
          .map((a) => TagRequestAnswer.fromJson(a))
          .toList(),
    );
  }
}

class AppUser {
  final int id;
  final String username;
  final String email;
  final bool isStaff;
  final bool isSuperuser;
  final String phone;
  final bool isVerified;
  final bool isAgent;
  final List<UserTagInfoSimple> tags;

  AppUser({
    required this.id,
    required this.username,
    required this.email,
    required this.isStaff,
    required this.isSuperuser,
    required this.phone,
    required this.isVerified,
    required this.isAgent,
    required this.tags,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'],
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      isStaff: json['is_staff'] ?? false,
      isSuperuser: json['is_superuser'] ?? false,
      phone: json['phone'] ?? '',
      isVerified: json['is_verified'] ?? false,
      isAgent: json['is_agent'] ?? false,
      tags: (json['tags'] as List<dynamic>? ?? [])
          .map((t) => UserTagInfoSimple.fromJson(t))
          .toList(),
    );
  }
}

class UserTagInfoSimple {
  final int id;
  final Tag tag;
  final String assignedAt;

  UserTagInfoSimple({required this.id, required this.tag, required this.assignedAt});

  factory UserTagInfoSimple.fromJson(Map<String, dynamic> json) {
    return UserTagInfoSimple(
      id: json['id'],
      tag: Tag.fromJson(json['tag']),
      assignedAt: json['assigned_at'] ?? '',
    );
  }
}