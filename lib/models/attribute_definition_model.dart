class AttributeDefinitionModel {
  final int id;
  final int propertyTypeId;
  final String attributeName;
  final String attributeType; // textbox, textarea, number, dropdown, radio, checkbox, file
  final List<String> options;
  final String unitLabel;
  final String applicableTo; // all, rent, sale
  final String? iconUrl;

  AttributeDefinitionModel({
    required this.id,
    required this.propertyTypeId,
    required this.attributeName,
    required this.attributeType,
    required this.options,
    required this.unitLabel,
    required this.applicableTo,
    this.iconUrl,
  });

  factory AttributeDefinitionModel.fromJson(Map<String, dynamic> json) {
    final rawOptions = (json['options'] ?? '') as String;
    return AttributeDefinitionModel(
      id: json['id'],
      propertyTypeId: json['property_type'],
      attributeName: json['attribute_name'] ?? '',
      attributeType: json['attribute_type'] ?? 'textbox',
      options: rawOptions.isEmpty
          ? []
          : rawOptions.split(',').map((o) => o.trim()).where((o) => o.isNotEmpty).toList(),
      unitLabel: json['unit_label'] ?? '',
      applicableTo: json['applicable_to'] ?? 'all',
      iconUrl: json['icon'],
    );
  }
}