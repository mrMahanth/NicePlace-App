import 'package:flutter/material.dart';
import '../models/attribute_definition_model.dart';

class PostProjectUnitAmenitiesScreen extends StatefulWidget {
  final List<AttributeDefinitionModel> attributeDefinitions;
  final Map<int, dynamic> initialValues;
  final Map<int, String> commonAttributeValues;

  const PostProjectUnitAmenitiesScreen({
    super.key,
    required this.attributeDefinitions,
    required this.initialValues,
    required this.commonAttributeValues,
  });

  @override
  State<PostProjectUnitAmenitiesScreen> createState() =>
      _PostProjectUnitAmenitiesScreenState();
}

class _PostProjectUnitAmenitiesScreenState
    extends State<PostProjectUnitAmenitiesScreen> {
  late Map<int, dynamic> _values;

  @override
  void initState() {
    super.initState();
    _values = Map<int, dynamic>.from(widget.initialValues);
  }

  Widget _commonAttributeNote(AttributeDefinitionModel attr) {
    final commonValue = widget.commonAttributeValues[attr.id]!;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey.shade400),
      ),
      child: Row(
        children: [
          const Icon(Icons.lock_outline, size: 16, color: Colors.black45),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              "${attr.attributeName}: $commonValue  •  Already selected as common amenities",
              style: const TextStyle(fontSize: 12, color: Colors.black54),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttributeField(AttributeDefinitionModel attr) {
    if (widget.commonAttributeValues.containsKey(attr.id)) {
      return _commonAttributeNote(attr);
    }

    switch (attr.attributeType) {
      case 'textbox':
        return TextFormField(
          initialValue: _values[attr.id] ?? '',
          decoration: InputDecoration(labelText: attr.attributeName, border: const OutlineInputBorder()),
          onChanged: (val) => _values[attr.id] = val,
        );
      case 'textarea':
        return TextFormField(
          initialValue: _values[attr.id] ?? '',
          maxLines: 3,
          decoration: InputDecoration(labelText: attr.attributeName, border: const OutlineInputBorder()),
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
          decoration: InputDecoration(labelText: attr.attributeName, border: const OutlineInputBorder()),
          items: attr.options.map((o) => DropdownMenuItem(value: o, child: Text(o))).toList(),
          onChanged: (val) => setState(() => _values[attr.id] = val),
        );
      case 'radio':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(attr.attributeName, style: const TextStyle(fontWeight: FontWeight.w500)),
            ...attr.options.map((opt) => RadioListTile<String>(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text(opt),
                  value: opt,
                  groupValue: _values[attr.id] as String?,
                  onChanged: (val) => setState(() => _values[attr.id] = val),
                )),
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
                      checked ? updated.add(opt) : updated.remove(opt);
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
      appBar: AppBar(title: const Text("Unit Amenities")),
      body: widget.attributeDefinitions.isEmpty
          ? const Center(child: Text("No amenities available for this property type."))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                for (final attr in widget.attributeDefinitions) ...[
                  _buildAttributeField(attr),
                  const SizedBox(height: 14),
                ],
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, _values),
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(14)),
                  child: const Text("Done"),
                ),
              ],
            ),
    );
  }
}