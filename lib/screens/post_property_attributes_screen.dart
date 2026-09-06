import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../models/attribute_definition_model.dart';
import '../services/property_type_service.dart';
import '../services/property_service.dart';
import 'post_property_media_screen.dart';

class PostPropertyAttributesScreen extends StatefulWidget {
  final int propertyId;

  const PostPropertyAttributesScreen({super.key, required this.propertyId});

  @override
  State<PostPropertyAttributesScreen> createState() =>
      _PostPropertyAttributesScreenState();
}

class _PostPropertyAttributesScreenState
    extends State<PostPropertyAttributesScreen> {
  bool _isLoading = true;
  String? _loadError;
  List<AttributeDefinitionModel> _attributes = [];

  // textbox/textarea/number/dropdown/radio -> String value
  // checkbox -> Set<String> selected options
  final Map<int, dynamic> _values = {};

  // file-type attributes: kya upload ho chuka hai (naam dikhane ke liye)
  final Map<int, String> _uploadedFileNames = {};
  final Set<int> _uploadingFileIds = {};

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
      final property = await PropertyService.fetchPropertyRaw(widget.propertyId);
      final propertyTypeId = property['property_type_pk'];
      final listingType = property['listing_type'] ?? 'rent';

      final allAttributes =
          await PropertyTypeService.fetchAttributeDefinitions(propertyTypeId);

      // Sirf wahi attributes dikhayein jo is listing type pe applicable hain
      final filtered = allAttributes.where((a) {
        return a.applicableTo == 'all' || a.applicableTo == listingType;
      }).toList();

      // Agar property pe pehle se koi attribute values saved hain (edit case),
      // unko form mein pre-fill kar dete hain
      final existingValues = property['attribute_values'] as List<dynamic>? ?? [];

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
        _loadError = "Could not load attributes. Please check your internet connection.";
        _isLoading = false;
      });
    }
  }

  Future<void> _pickAndUploadFile(AttributeDefinitionModel attr) async {
    final file = await FilePicker.pickFile();
    if (file == null || file.path == null) return;

    final path = file.path!;
    final fileName = file.name;

    setState(() => _uploadingFileIds.add(attr.id));

    final response = await PropertyService.uploadAttributeFile(
      propertyId: widget.propertyId,
      attributeDefinitionId: attr.id,
      filePath: path,
    );

    setState(() => _uploadingFileIds.remove(attr.id));

    if (!mounted) return;

    if (response["success"] == true) {
      setState(() => _uploadedFileNames[attr.id] = fileName);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("File upload failed. Please try again.")),
      );
    }
  }

  Future<void> _saveAndContinue() async {
    setState(() => _isSaving = true);

    // Sirf non-file attributes ko "attributes" JSON mein bhejna hai
    final Map<String, String> payload = {};
    for (final attr in _attributes) {
      if (attr.attributeType == 'file') continue;
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

    final result = await PropertyService.updateAttributes(
      propertyId: widget.propertyId,
      attributes: payload,
    );

    setState(() => _isSaving = false);

    if (!mounted) return;

    if (result["success"] == true) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PostPropertyMediaScreen(propertyId: widget.propertyId),
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

      case 'file':
        final isUploading = _uploadingFileIds.contains(attr.id);
        final uploadedName = _uploadedFileNames[attr.id];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(attr.attributeName, style: const TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(height: 4),
            OutlinedButton.icon(
              onPressed: isUploading ? null : () => _pickAndUploadFile(attr),
              icon: isUploading
                  ? const SizedBox(
                      height: 14, width: 14, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.attach_file),
              label: Text(uploadedName ?? "Choose File"),
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
      appBar: AppBar(title: const Text("Property Attributes")),
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
              : _attributes.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text("No extra attributes to fill for this property type."),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _isSaving ? null : _saveAndContinue,
                              child: const Text("Continue"),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        for (final attr in _attributes) ...[
                          _buildAttributeField(attr),
                          const SizedBox(height: 16),
                        ],
                        ElevatedButton(
                          onPressed: _isSaving ? null : _saveAndContinue,
                          style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(14)),
                          child: _isSaving
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2))
                              : const Text("Save & Continue"),
                        ),
                      ],
                    ),
    );
  }
}