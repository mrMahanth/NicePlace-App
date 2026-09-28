import 'package:flutter/material.dart';
import '../models/unit_draft_model.dart';
import '../models/attribute_definition_model.dart';
import '../services/project_service.dart';
import '../services/property_type_service.dart';
import '../utils/number_utils.dart';
import 'post_project_unit_amenities_screen.dart';

class PostProjectUnitEditScreen extends StatefulWidget {
  final int projectId;
  final int propertyTypeId;
  final UnitDraft initialDraft;
  final List<AttributeDefinitionModel> attributeDefinitions;
  final String initialListingType;
  final int existingUnitsCount;
  final int draftUnitsCount;
  final Map<int, String> commonAttributeValues;

  const PostProjectUnitEditScreen({
    super.key,
    required this.projectId,
    required this.propertyTypeId,
    required this.initialDraft,
    required this.attributeDefinitions,
    required this.initialListingType,
    required this.existingUnitsCount,
    required this.draftUnitsCount,
    this.commonAttributeValues = const {},
  });

  @override
  State<PostProjectUnitEditScreen> createState() => _PostProjectUnitEditScreenState();
}

class _PostProjectUnitEditScreenState extends State<PostProjectUnitEditScreen> {
  late UnitDraft _draft;
  late List<AttributeDefinitionModel> _attributeDefinitions;

  final TextEditingController _unitNumberController = TextEditingController();
  final TextEditingController _rentAmountController = TextEditingController();
  final TextEditingController _securityDepositController = TextEditingController();
  final TextEditingController _maintenanceController = TextEditingController();
  final TextEditingController _totalPriceController = TextEditingController();
  final TextEditingController _ratePerUnitController = TextEditingController();
  final TextEditingController _bookingPriceController = TextEditingController();

  static const List<String> _statusOptions = ['draft', 'sold', 'rented'];

  static const List<Map<String, String>> _rentUnitOptions = [
    {'value': 'per_day', 'label': 'Per Day'},
    {'value': 'per_month', 'label': 'Per Month'},
    {'value': 'per_year', 'label': 'Per Year'},
  ];

  // "Total Price" hata diya - wo unit nahi hai, ye dropdown ab sirf
  // Rate Per Unit field ke saath dikhega, so sirf actual units hi list mein hain.
  static const List<Map<String, String>> _saleUnitOptions = [
    {'value': 'per_sqft', 'label': 'Per Sq.Ft.'},
    {'value': 'per_katha', 'label': 'Per Katha'},
  ];

  // NAYA: is unit ke apne amount ke saath ka price-unit (Rent Amount / Rate Per Unit ke saath)
  late String _priceUnit;

   bool _isChangingType = false;
  // NAYA: Dropdown ke internal-state ko force-reset karne ke liye - jab bhi
  // Cancel ho, isse increment karke dropdown ko purani value par sahi se sync karte hain.
  int _listingTypeDropdownResetKey = 0;

  @override
  void initState() {
    super.initState();
    _draft = widget.initialDraft.duplicate();
    _draft.unitNumber = widget.initialDraft.unitNumber;
    _draft.status = widget.initialDraft.status;
    _draft.listingType = widget.initialListingType;
    _draft.priceUnit = widget.initialDraft.priceUnit;
    _attributeDefinitions = widget.attributeDefinitions;

    _unitNumberController.text = _draft.unitNumber;
    _rentAmountController.text = NumberUtils.formatPrice(_draft.rentAmount);
    _securityDepositController.text = NumberUtils.formatPrice(_draft.securityDeposit);
    _maintenanceController.text = NumberUtils.formatPrice(_draft.maintenanceAmount);
    _totalPriceController.text = NumberUtils.formatPrice(_draft.totalPrice);
    _ratePerUnitController.text = NumberUtils.formatPrice(_draft.ratePerUnit);
    _bookingPriceController.text = NumberUtils.formatPrice(_draft.bookingPrice);

    _priceUnit = _draft.priceUnit;

    // NAYA: Safety check - agar current priceUnit is listing-type ke valid options
    // mein hi nahi hai (jaise naye Sale-project ke naye unit par UnitDraft ka default
    // 'per_month' reh gaya, jo Sale ke dropdown options mein hota hi nahi), to
    // dropdown assertion-crash se bachne ke liye pehle hi sahi default laga dete hain.
    if (_draft.listingType == 'sale') {
      final validSaleUnits = _saleUnitOptions.map((o) => o['value']).toSet();
      if (!validSaleUnits.contains(_priceUnit)) _priceUnit = 'per_sqft';
    } else {
      final validRentUnits = _rentUnitOptions.map((o) => o['value']).toSet();
      if (!validRentUnits.contains(_priceUnit)) _priceUnit = 'per_month';
    }

    // Bilkul naye (khali) unit ke liye - property-type ke hisaab se smart default lagate hain,
    // duplicate/existing-unit ke liye jo priceUnit already set hai wahi rehne dete hain.
    if (_draft.unitNumber.isEmpty && _draft.listingType == 'rent') {
      _loadSmartDefaultPriceUnit();
    }
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
          attributeDefinitions: _attributeDefinitions,
          initialValues: _draft.attributeValues,
          commonAttributeValues: widget.commonAttributeValues,
        ),
      ),
    );
    if (result != null) {
      setState(() => _draft.attributeValues = result);
    }
  }

  // NAYA: Checkbox-type attribute ab partially-common ho sakti hai (sirf kuch options
  // common-locked, baaki user khud select kar sakta hai) - isliye poori attribute ko
  // "common hai isliye ignore karo" nahi keh sakte. Sirf woh options nikaalte hain
  // jo common-selection se extra hain.
  Set<String> _commonOptionsFor(int attrId) {
    final raw = widget.commonAttributeValues[attrId];
    if (raw == null || raw.trim().isEmpty) return <String>{};
    return raw.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toSet();
  }

  bool _isCheckboxAttribute(int attrId) {
    final match = _attributeDefinitions.where((a) => a.id == attrId).toList();
    return match.isNotEmpty && match.first.attributeType == 'checkbox';
  }

  int get _setAttributeCount {
    return _draft.attributeValues.entries.where((e) {
      final v = e.value;
      if (v == null) return false;

      if (v is Set<String>) {
        if (v.isEmpty) return false;
        if (_isCheckboxAttribute(e.key)) {
          // Sirf common-se-extra options count hote hain
          final extra = v.difference(_commonOptionsFor(e.key));
          return extra.isNotEmpty;
        }
        return v.isNotEmpty;
      }

      // Non-checkbox attribute jo poori tarah common-locked hai, uska
      // koi editable value yahan se aata hi nahi - safety ke liye exclude karte hain.
      if (widget.commonAttributeValues.containsKey(e.key)) return false;
      return v.toString().trim().isNotEmpty;
    }).length;
  }

  // Basic Details screen ki tarah hi property-type ke hisaab se smart default price-unit nikalte hain
  Future<String> _computeDefaultRentUnit() async {
    try {
      final types = await PropertyTypeService.fetchPropertyTypes();
      final matching = types.where((t) => t.id == widget.propertyTypeId).toList();
      if (matching.isEmpty) return 'per_month';
      final isBookable = matching.first.isBookable;
      final typeName = matching.first.name.toLowerCase();
      if (isBookable) return 'per_day';
      if (typeName.contains('plot')) return 'per_year';
      return 'per_month';
    } catch (e) {
      return 'per_month';
    }
  }

  Future<void> _loadSmartDefaultPriceUnit() async {
    final computed = await _computeDefaultRentUnit();
    if (mounted) setState(() => _priceUnit = computed);
  }

  Future<void> _reloadAttributeDefinitions(String newType) async {
    try {
      final allAttrs = await PropertyTypeService.fetchAttributeDefinitions(widget.propertyTypeId);
      final filtered = allAttrs.where((a) {
        final applicable = a.applicableTo == 'all' || a.applicableTo == newType;
        return applicable && a.attributeType != 'file';
      }).toList();
      if (mounted) setState(() => _attributeDefinitions = filtered);
    } catch (e) {
      // best-effort; purani list hi reh jayegi agar yeh fail ho
    }
  }

  Future<void> _handleListingTypeChangeRequest(String newType) async {
    if (widget.existingUnitsCount > 0) {
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text("Cannot Change Listing Type"),
          content: const Text("Delete existing units before changing listing type."),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text("OK")),
          ],
        ),
      );
      return;
    }

    final currentLabel = _draft.listingType == 'rent' ? 'Rent' : 'Sale';
    final newLabel = newType == 'rent' ? 'Rent' : 'Sale';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text("Change Listing Type"),
        content: Text(
          widget.draftUnitsCount > 0
              ? "You have set listing type \"$currentLabel\" in Basic Details.\n\n"
                  "This will also clear the ${widget.draftUnitsCount} new unit(s) already added in Bulk Units screen."
              : "You have set listing type \"$currentLabel\" in Basic Details.",
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text("Cancel")),
          ElevatedButton(onPressed: () => Navigator.pop(dialogContext, true), child: Text("Change to $newLabel")),
        ],
      ),
    );
    if (confirmed != true) {
      // Dropdown ka internal state Flutter ke andar hi "naya type" store kar chuka
      // hai tap hote hi - sirf setState() se yeh sync nahi hota, isliye key badal kar
      // poora dropdown widget hi dobara banate hain, purani value ke saath.
      if (mounted) setState(() => _listingTypeDropdownResetKey++);
      return;
    }

    final priceController = TextEditingController();
    String selectedUnit = newType == 'rent' ? await _computeDefaultRentUnit() : 'per_sqft';
    if (!mounted) return;

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              title: const Text("Starting Price"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: priceController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: newType == 'rent'
                          ? "Starting Rent From (optional)"
                          : "Starting Price From (optional)",
                      suffixText: newType == 'sale' ? "/Sq.Ft." : null,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  if (newType == 'rent') ...[
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: selectedUnit,
                      decoration: const InputDecoration(labelText: "Unit", border: OutlineInputBorder()),
                      items: _rentUnitOptions
                          .map((opt) => DropdownMenuItem(value: opt['value'], child: Text(opt['label']!)))
                          .toList(),
                      onChanged: (v) => setDialogState(() => selectedUnit = v ?? selectedUnit),
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text("Cancel")),
                ElevatedButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text("Save")),
              ],
            );
          },
        );
      },
    );
    if (saved != true) {
      // Yahan bhi wahi fix - key badal kar dropdown ko poori tarah rebuild karte hain.
      if (mounted) setState(() => _listingTypeDropdownResetKey++);
      return;
    }

    setState(() => _isChangingType = true);

    final result = await ProjectService.updateListingTypeAndPrice(
      projectId: widget.projectId,
      listingType: newType,
      startingPrice: double.tryParse(priceController.text.trim()),
      startingPriceUnit: newType == 'rent' ? selectedUnit : 'per_sqft',
    );

    if (result["success"] != true) {
      setState(() => _isChangingType = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Could not change listing type. Please try again.")),
      );
      return;
    }

    setState(() {
      _draft.applyListingTypeChange(newType);
      _rentAmountController.text = '';
      _securityDepositController.text = '';
      _maintenanceController.text = '';
      _totalPriceController.text = '';
      _ratePerUnitController.text = '';
      _bookingPriceController.text = '';
      // Starting-Price popup mein jo unit chuna gaya, wahi is unit ke apne price-unit ka default bhi ban jaata hai
      _priceUnit = newType == 'rent' ? selectedUnit : 'per_sqft';
    });

    await _reloadAttributeDefinitions(newType);

    if (!mounted) return;
    setState(() => _isChangingType = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Listing type changed to $newLabel.")),
    );
  }

  void _onSave() {
    if (_unitNumberController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Unit Number is required.")));
      return;
    }

    _draft.unitNumber = _unitNumberController.text.trim();
    _draft.priceUnit = _priceUnit;

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
      if (_isCheckboxAttribute(attrId)) {
        // Checkbox attribute partially-common ho sakti hai - sirf common options hatao,
        // user ke khud-chune extra options (jaise WiFi) ko save hone dena hai.
        final current = _draft.attributeValues[attrId];
        if (current is Set<String>) {
          final remaining = current.difference(_commonOptionsFor(attrId));
          if (remaining.isEmpty) {
            _draft.attributeValues.remove(attrId);
          } else {
            _draft.attributeValues[attrId] = remaining;
          }
        } else {
          _draft.attributeValues.remove(attrId);
        }
      } else {
        _draft.attributeValues.remove(attrId);
      }
    }

    Navigator.pop(context, _draft);
  }

  // Amount field, jisme optionally uske saath ek chhota "unit" dropdown bhi ho sakta hai
  // (sirf Rent Amount aur Rate Per Unit rows ke liye), aur hamesha Negotiable checkbox.
  Widget _amountRow(
    String label,
    TextEditingController controller,
    bool negotiableValue,
    ValueChanged<bool> onNegotiableChanged, {
    bool required = false,
    List<Map<String, String>>? unitOptions,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: 3,
            child: TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: required ? "$label *" : "$label (optional)",
                border: const OutlineInputBorder(),
              ),
            ),
          ),
          if (unitOptions != null) ...[
            const SizedBox(width: 6),
            Expanded(
              flex: 2,
              child: DropdownButtonFormField<String>(
                value: _priceUnit,
                isExpanded: true,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                ),
                items: unitOptions
                    .map((opt) => DropdownMenuItem(
                          value: opt['value'],
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(opt['label']!),
                          ),
                        ))
                    .toList(),
                // selectedItemBuilder: (context) => unitOptions.map((opt) {
                //   return Align(
                //     alignment: Alignment.centerLeft,
                //     child: Text(
                //       opt['label']!,
                //       style: const TextStyle(fontSize: 11),
                //       overflow: TextOverflow.ellipsis,
                //       maxLines: 1,
                //     ),
                //   );
                // }).toList(),
                onChanged: (value) {
                  if (value != null) setState(() => _priceUnit = value);
                },
              ),
            ),
          ],
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
                child: DropdownButtonFormField<String>(
                  key: ValueKey(_listingTypeDropdownResetKey),
                  value: _draft.listingType,
                  decoration: const InputDecoration(labelText: "Listing Type", border: OutlineInputBorder()),
                  items: const [
                    DropdownMenuItem(value: 'rent', child: Text('Rent')),
                    DropdownMenuItem(value: 'sale', child: Text('Sale')),
                  ],
                  onChanged: _isChangingType
                      ? null
                      : (value) {
                          if (value == null || value == _draft.listingType) return;
                          _handleListingTypeChangeRequest(value);
                        },
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
          Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 16),
            child: Text(
              _isChangingType
                  ? "Updating listing type..."
                  : "Changing this updates the listing type for the whole project (Basic Details).",
              style: const TextStyle(fontSize: 11, color: Colors.black54),
            ),
          ),

          if (_draft.listingType == 'rent') ...[
            _amountRow("Rent Amount", _rentAmountController, _draft.rentNegotiable,
                (v) => setState(() => _draft.rentNegotiable = v),
                required: true, unitOptions: _rentUnitOptions),
            _amountRow("Security Deposit", _securityDepositController, _draft.securityDepositNegotiable,
                (v) => setState(() => _draft.securityDepositNegotiable = v)),
            _amountRow("Maintenance", _maintenanceController, _draft.maintenanceNegotiable,
                (v) => setState(() => _draft.maintenanceNegotiable = v)),
          ] else ...[
            _amountRow("Total Price", _totalPriceController, _draft.totalPriceNegotiable,
                (v) => setState(() => _draft.totalPriceNegotiable = v), required: true),
            _amountRow("Rate Per Unit", _ratePerUnitController, _draft.ratePerUnitNegotiable,
                (v) => setState(() => _draft.ratePerUnitNegotiable = v), unitOptions: _saleUnitOptions),
            _amountRow("Booking Price", _bookingPriceController, _draft.bookingPriceNegotiable,
                (v) => setState(() => _draft.bookingPriceNegotiable = v)),
          ],

          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _attributeDefinitions.isEmpty ? null : _openAmenities,
            icon: const Icon(Icons.checklist),
            label: Text(
              _attributeDefinitions.isEmpty
                  ? "No amenities available"
                  : _setAttributeCount > 0
                      ? "Unit Amenities ($_setAttributeCount set)"
                      : "Unit Amenities",
            ),
          ),

          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _isChangingType ? null : _onSave,
            style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(14)),
            child: const Text("Save Unit"),
          ),
        ],
      ),
    );
  }
}