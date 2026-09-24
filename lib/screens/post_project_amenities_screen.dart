import 'package:flutter/material.dart';
import '../models/attribute_definition_model.dart';
import '../services/property_type_service.dart';
import '../services/project_service.dart';
import 'post_project_documents_screen.dart';

class PostProjectAmenitiesScreen extends StatefulWidget {
  final int projectId;

  const PostProjectAmenitiesScreen({super.key, required this.projectId});

  @override
  State<PostProjectAmenitiesScreen> createState() =>
      _PostProjectAmenitiesScreenState();
}

class _PostProjectAmenitiesScreenState extends State<PostProjectAmenitiesScreen> {
  bool _isLoading = true;
  String? _loadError;
  List<AttributeDefinitionModel> _attributes = [];

  final Map<int, dynamic> _values = {};
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });
    try {
      final project = await ProjectService.fetchProjectRaw(widget.projectId);
      final propertyTypeId = project['property_type_pk'];
      final listingType = project['listing_type'] ?? 'rent';

      final allAttributes =
          await PropertyTypeService.fetchAttributeDefinitions(propertyTypeId);

      // File-type attributes yahan support nahi hain (sirf per-unit level pe) -
      // aur listing_type ke hisaab se applicable filter bhi karte hain.
      final filtered = allAttributes.where((a) {
        final applicable = a.applicableTo == 'all' || a.applicableTo == listingType;
        return applicable && a.attributeType != 'file';
      }).toList();

      final existingValues = project['attribute_values'] as List<dynamic>? ?? [];

      setState(() {
        _attributes = filtered;
        for (final attr in filtered) {
          final existing = existingValues.firstWhere(
            (v) => v['attribute_definition'] == attr.id,
            orElse: () => null,
          );
          if (existing != null && existing['value'] != null && existing['value'] != '') {
            if (attr.attributeType == 'checkbox') {
              _values[attr.id] =
                  (existing['value'] as String).split(',').map((e) => e.trim()).toSet();
            } else {
              _values[attr.id] = existing['value'];
            }
          }
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _loadError = "Could not load amenities. Please check your internet connection.";
        _isLoading = false;
      });
    }
  }

  Future<void> _saveAndContinue() async {
    setState(() => _isSaving = true);

    final Map<String, String> payload = {};
    for (final attr in _attributes) {
      final value = _values[attr.id];
      if (value == null) continue;

      if (attr.attributeType == 'checkbox') {
        final selectedSet = value as Set<String>;
        if (selectedSet.isEmpty) continue;
        payload[attr.id.toString()] = selectedSet.join(', ');
      } else {
        final stringValue = value.toString().trim();
        if (stringValue.isEmpty) continue;
        payload[attr.id.toString()] = stringValue;
      }
    }

    final result = await ProjectService.updateAmenities(
      projectId: widget.projectId,
      attributes: payload,
    );

    setState(() => _isSaving = false);

    if (!mounted) return;

    if (result["success"] == true) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PostProjectDocumentsScreen(projectId: widget.projectId),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Could not save. Please try again.")),
      );
    }
  }

  Widget _buildAttributeField(AttributeDefinitionModel attr) {
    switch (attr.attributeType) {
      case 'textbox':
        return TextFormField(
          initialValue: _values[attr.id] ?? '',
          decoration: InputDecoration(
            labelText: attr.attributeName,
            border: const OutlineInputBorder(),
          ),
          onChanged: (val) => _values[attr.id] = val,
        );

      case 'textarea':
        return TextFormField(
          initialValue: _values[attr.id] ?? '',
          maxLines: 3,
          decoration: InputDecoration(
            labelText: attr.attributeName,
            border: const OutlineInputBorder(),
          ),
          onChanged: (val) => _values[attr.id] = val,
        );

      case 'number':
        return TextFormField(
          initialValue: _values[attr.id] ?? '',
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: attr.attributeName,
            suffixText: attr.unitLabel.isNotEmpty ? attr.unitLabel : null,
            border: const OutlineInputBorder(),
          ),
          onChanged: (val) => _values[attr.id] = val,
        );

      case 'dropdown':
        return DropdownButtonFormField<String>(
          value: (_values[attr.id] as String?)?.isNotEmpty == true ? _values[attr.id] : null,
          decoration: InputDecoration(
            labelText: attr.attributeName,
            border: const OutlineInputBorder(),
          ),
          items: attr.options
              .map((opt) => DropdownMenuItem(value: opt, child: Text(opt)))
              .toList(),
          onChanged: (val) => setState(() => _values[attr.id] = val),
        );

      case 'radio':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(attr.attributeName, style: const TextStyle(fontWeight: FontWeight.w500)),
            ...attr.options.map((opt) {
              return RadioListTile<String>(
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: Text(opt),
                value: opt,
                groupValue: _values[attr.id] as String?,
                onChanged: (val) => setState(() => _values[attr.id] = val),
              );
            }),
          ],
        );

      case 'checkbox':
        final selected = (_values[attr.id] as Set<String>?) ?? <String>{};
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(attr.attributeName, style: const TextStyle(fontWeight: FontWeight.w500)),
            Wrap(
              spacing: 8,
              children: attr.options.map((opt) {
                final isSelected = selected.contains(opt);
                return FilterChip(
                  label: Text(opt),
                  selected: isSelected,
                  onSelected: (checked) {
                    setState(() {
                      final updated = Set<String>.from(selected);
                      if (checked) {
                        updated.add(opt);
                      } else {
                        updated.remove(opt);
                      }
                      _values[attr.id] = updated;
                    });
                  },
                );
              }).toList(),
            ),
          ],
        );

      default:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Common Amenities")),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _loadError != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_loadError!),
                      const SizedBox(height: 12),
                      ElevatedButton(onPressed: _loadData, child: const Text("Try Again")),
                    ],
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    const Text(
                      "Fill in anything that applies to ALL units in this project. "
                      "Each unit can still fill in whatever is left blank here individually.",
                      style: TextStyle(fontSize: 12, color: Colors.black54),
                    ),
                    const SizedBox(height: 16),
                    if (_attributes.isEmpty)
                      const Text("No common attributes available for this property type.")
                    else
                      for (final attr in _attributes) ...[
                        _buildAttributeField(attr),
                        const SizedBox(height: 16),
                      ],
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: _isSaving ? null : _saveAndContinue,
                      style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(14)),
                      child: _isSaving
                          ? const SizedBox(
                              height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Text("Save & Continue"),
                    ),
                  ],
                ),
    );
  }
}