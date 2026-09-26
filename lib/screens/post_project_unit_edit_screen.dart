import 'package:flutter/material.dart';
import '../models/unit_draft_model.dart';
import '../models/attribute_definition_model.dart';

class PostProjectUnitEditScreen extends StatefulWidget {
  final UnitDraft initialDraft;
  final List<AttributeDefinitionModel> attributeDefinitions;
  final String fixedListingType;
  // attrId -> already-set common amenity value (display text), agar koi ho
  final Map<int, String> commonAttributeValues;

  const PostProjectUnitEditScreen({
    super.key,
    required this.initialDraft,
    required this.attributeDefinitions,
    required this.fixedListingType,
    this.commonAttributeValues = const {},
  });

  @override
  State<PostProjectUnitEditScreen> createState() => _PostProjectUnitEditScreenState();
}

class _PostProjectUnitEditScreenState extends State<PostProjectUnitEditScreen> {
  late UnitDraft _draft;

  final TextEditingController _unitNumberController = TextEditingController();
  final TextEditingController _rentAmountController = TextEditingController();
  final TextEditingController _securityDepositController = TextEditingController();
  final TextEditingController _maintenanceController = TextEditingController();
  final TextEditingController _totalPriceController = TextEditingController();
  final TextEditingController _ratePerUnitController = TextEditingController();
  final TextEditingController _bookingPriceController = TextEditingController();

  static const List<String> _statusOptions = ['draft', 'sold', 'rented'];

  @override
  void initState() {
    super.initState();
    _draft = widget.initialDraft.duplicate();
    _draft.unitNumber = widget.initialDraft.unitNumber;
    _draft.status = widget.initialDraft.status;
    _draft.listingType = widget.fixedListingType; // hamesha project ke hisaab se fixed

    _unitNumberController.text = _draft.unitNumber;
    _rentAmountController.text = _draft.rentAmount?.toString() ?? '';
    _securityDepositController.text = _draft.securityDeposit?.toString() ?? '';
    _maintenanceController.text = _draft.maintenanceAmount?.toString() ?? '';
    _totalPriceController.text = _draft.totalPrice?.toString() ?? '';
    _ratePerUnitController.text = _draft.ratePerUnit?.toString() ?? '';
    _bookingPriceController.text = _draft.bookingPrice?.toString() ?? '';
  }

  @override
  void dispose() {
    _unitNumberController.dispose();
    _rentAmountController.dispose();
    _securityDepositController.dispose();
    _maintenanceController.dispose();
    _totalPriceController.dispose();
    _ratePerUnitController.dispose();
    _bookingPriceController.dispose();
    super.dispose();
  }

  double? _parseOrNull(String text) {
    final t = text.trim();
    if (t.isEmpty) return null;
    return double.tryParse(t);
  }

  void _onSave() {
    if (_unitNumberController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Unit Number is required.")));
      return;
    }

    _draft.unitNumber = _unitNumberController.text.trim();

    if (_draft.listingType == 'rent') {
      final rent = _parseOrNull(_rentAmountController.text);
      if (rent == null || rent <= 0) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text("Please enter a valid Rent Amount.")));
        return;
      }
      _draft.rentAmount = rent;
      _draft.securityDeposit = _parseOrNull(_securityDepositController.text);
      _draft.maintenanceAmount = _parseOrNull(_maintenanceController.text);
    } else {
      final total = _parseOrNull(_totalPriceController.text);
      if (total == null || total <= 0) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text("Please enter a valid Total Price.")));
        return;
      }
      _draft.totalPrice = total;
      _draft.ratePerUnit = _parseOrNull(_ratePerUnitController.text);
      _draft.bookingPrice = _parseOrNull(_bookingPriceController.text);
    }

    // Common-amenity wale attributes kabhi is form se save nahi hote (project se hi aate hain)
    for (final attrId in widget.commonAttributeValues.keys) {
      _draft.attributeValues.remove(attrId);
    }

    Navigator.pop(context, _draft);
  }

  Widget _amountRow(
    String label,
    TextEditingController controller,
    bool negotiableValue,
    ValueChanged<bool> onNegotiableChanged, {
    bool required = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: required ? "$label *" : "$label (optional)",
                border: const OutlineInputBorder(),
              ),
            ),
          ),
          const SizedBox(width: 6),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Checkbox(value: negotiableValue, onChanged: (v) => onNegotiableChanged(v ?? false)),
              const Text("Negotiable", style: TextStyle(fontSize: 9)),
            ],
          ),
        ],
      ),
    );
  }

  // Attribute jo already Common Amenities mein set hai - disabled dikhega
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
          initialValue: _draft.attributeValues[attr.id] ?? '',
          decoration: InputDecoration(labelText: attr.attributeName, border: const OutlineInputBorder()),
          onChanged: (val) => _draft.attributeValues[attr.id] = val,
        );
      case 'textarea':
        return TextFormField(
          initialValue: _draft.attributeValues[attr.id] ?? '',
          maxLines: 3,
          decoration: InputDecoration(labelText: attr.attributeName, border: const OutlineInputBorder()),
          onChanged: (val) => _draft.attributeValues[attr.id] = val,
        );
      case 'number':
        return TextFormField(
          initialValue: _draft.attributeValues[attr.id] ?? '',
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: attr.attributeName,
            suffixText: attr.unitLabel.isNotEmpty ? attr.unitLabel : null,
            border: const OutlineInputBorder(),
          ),
          onChanged: (val) => _draft.attributeValues[attr.id] = val,
        );
      case 'dropdown':
        return DropdownButtonFormField<String>(
          value: (_draft.attributeValues[attr.id] as String?)?.isNotEmpty == true
              ? _draft.attributeValues[attr.id]
              : null,
          decoration: InputDecoration(labelText: attr.attributeName, border: const OutlineInputBorder()),
          items: attr.options.map((o) => DropdownMenuItem(value: o, child: Text(o))).toList(),
          onChanged: (val) => setState(() => _draft.attributeValues[attr.id] = val),
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
                  groupValue: _draft.attributeValues[attr.id] as String?,
                  onChanged: (val) => setState(() => _draft.attributeValues[attr.id] = val),
                )),
          ],
        );
      case 'checkbox':
        final selected = (_draft.attributeValues[attr.id] as Set<String>?) ?? <String>{};
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
                      _draft.attributeValues[attr.id] = updated;
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
      appBar: AppBar(title: const Text("Unit Details")),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _unitNumberController,
            decoration: const InputDecoration(
              labelText: "Unit Number *",
              hintText: "e.g. A-101",
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade400),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    children: [
                      Text(
                        _draft.listingType == 'rent' ? "Rent" : "Sale",
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(width: 6),
                      const Icon(Icons.lock_outline, size: 14, color: Colors.black45),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _draft.status,
                  decoration: const InputDecoration(labelText: "Status", border: OutlineInputBorder()),
                  items: _statusOptions
                      .map((s) => DropdownMenuItem(value: s, child: Text(s[0].toUpperCase() + s.substring(1))))
                      .toList(),
                  onChanged: (v) => setState(() => _draft.status = v ?? 'draft'),
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.only(top: 4, bottom: 16),
            child: Text(
              "Listing type is set for the whole project. Use \"Change\" on the Bulk Units screen to update it.",
              style: TextStyle(fontSize: 11, color: Colors.black54),
            ),
          ),

          if (_draft.listingType == 'rent') ...[
            _amountRow("Rent Amount", _rentAmountController, _draft.rentNegotiable,
                (v) => setState(() => _draft.rentNegotiable = v), required: true),
            _amountRow("Security Deposit", _securityDepositController, _draft.securityDepositNegotiable,
                (v) => setState(() => _draft.securityDepositNegotiable = v)),
            _amountRow("Maintenance", _maintenanceController, _draft.maintenanceNegotiable,
                (v) => setState(() => _draft.maintenanceNegotiable = v)),
          ] else ...[
            _amountRow("Total Price", _totalPriceController, _draft.totalPriceNegotiable,
                (v) => setState(() => _draft.totalPriceNegotiable = v), required: true),
            _amountRow("Rate Per Unit", _ratePerUnitController, _draft.ratePerUnitNegotiable,
                (v) => setState(() => _draft.ratePerUnitNegotiable = v)),
            _amountRow("Booking Price", _bookingPriceController, _draft.bookingPriceNegotiable,
                (v) => setState(() => _draft.bookingPriceNegotiable = v)),
          ],

          if (widget.attributeDefinitions.isNotEmpty) ...[
            const SizedBox(height: 8),
            const Text("Attributes", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            for (final attr in widget.attributeDefinitions) ...[
              _buildAttributeField(attr),
              const SizedBox(height: 14),
            ],
          ],

          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: _onSave,
            style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(14)),
            child: const Text("Save Unit"),
          ),
        ],
      ),
    );
  }
}