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

  // NAYA: checkbox-type attribute ke liye — poori attribute lock nahi hoti,
  // sirf woh options lock hote hain jo common amenities me already select kiye gaye the.
  Set<String> _commonOptionsFor(AttributeDefinitionModel attr) {
    final raw = widget.commonAttributeValues[attr.id];
    if (raw == null || raw.trim().isEmpty) return <String>{};
    return raw.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toSet();
  }

  Widget _buildAttributeField(AttributeDefinitionModel attr) {
    // Checkbox-type ke liye poori-attribute-lock nahi karte — usko alag (partial-lock) logic milta hai neeche.
    if (attr.attributeType != 'checkbox' && widget.commonAttributeValues.containsKey(attr.id)) {
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
        final commonOptions = _commonOptionsFor(attr);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(attr.attributeName, style: const TextStyle(fontWeight: FontWeight.w500)),
            if (commonOptions.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 2, bottom: 6),
                child: Text(
                  "${commonOptions.join(', ')} already selected as common amenities",
                  style: const TextStyle(fontSize: 11, color: Colors.black54),
                ),
              ),
            Wrap(
              spacing: 8,
              children: attr.options.map((opt) {
                final isCommon = commonOptions.contains(opt);
                final isSelected = isCommon || selected.contains(opt);
                return FilterChip(
                  label: Text(opt),
                  selected: isSelected,
                  onSelected: isCommon
                      ? null // locked - already covered by common amenities
                      : (checked) {
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