import 'package:flutter/material.dart';
import '../models/unit_draft_model.dart';
import '../models/attribute_definition_model.dart';
import 'post_project_unit_amenities_screen.dart';

class PostProjectUnitEditScreen extends StatefulWidget {
  final UnitDraft initialDraft;
  final List<AttributeDefinitionModel> attributeDefinitions;
  final String fixedListingType;
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
    _draft.listingType = widget.fixedListingType;

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

  Future<void> _openAmenities() async {
    final result = await Navigator.push<Map<int, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (_) => PostProjectUnitAmenitiesScreen(
          attributeDefinitions: widget.attributeDefinitions,
          initialValues: _draft.attributeValues,
          commonAttributeValues: widget.commonAttributeValues,
        ),
      ),
    );
    if (result != null) {
      setState(() => _draft.attributeValues = result);
    }
  }

  int get _setAttributeCount {
    // Common-amenity wale attributes count mein nahi jodte (wo yahan se set hi nahi hote)
    return _draft.attributeValues.entries.where((e) {
      if (widget.commonAttributeValues.containsKey(e.key)) return false;
      final v = e.value;
      if (v == null) return false;
      if (v is Set<String>) return v.isNotEmpty;
      return v.toString().trim().isNotEmpty;
    }).length;
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

          const SizedBox(height: 8),
          // ---------- NAYA: Attributes ab button ke peeche hain ----------
          OutlinedButton.icon(
            onPressed: widget.attributeDefinitions.isEmpty ? null : _openAmenities,
            icon: const Icon(Icons.checklist),
            label: Text(
              widget.attributeDefinitions.isEmpty
                  ? "No amenities available"
                  : _setAttributeCount > 0
                      ? "Unit Amenities ($_setAttributeCount set)"
                      : "Unit Amenities",
            ),
          ),

          const SizedBox(height: 24),
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