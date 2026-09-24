import 'package:flutter/material.dart';
import '../services/property_service.dart';
import 'post_property_attributes_screen.dart';

class PostPropertyPricingScreen extends StatefulWidget {
  final int propertyId;

  const PostPropertyPricingScreen({super.key, required this.propertyId});

  @override
  State<PostPropertyPricingScreen> createState() => _PostPropertyPricingScreenState();
}

class _PostPropertyPricingScreenState extends State<PostPropertyPricingScreen> {
  final TextEditingController _rentAmountController = TextEditingController();
  final TextEditingController _securityDepositController = TextEditingController();
  final TextEditingController _maintenanceController = TextEditingController();

  final TextEditingController _totalPriceController = TextEditingController();
  final TextEditingController _ratePerUnitController = TextEditingController();
  final TextEditingController _bookingPriceController = TextEditingController();

  bool _rentNegotiable = false;
  bool _securityDepositNegotiable = false;
  bool _maintenanceNegotiable = false;
  bool _totalPriceNegotiable = false;
  bool _ratePerUnitNegotiable = false;
  bool _bookingPriceNegotiable = false;

  String _listingType = 'rent';
  String _priceUnit = 'per_month';
  bool _isSaving = false;
  bool _isLoadingPropertyInfo = true;

  String _defaultRentUnit = 'per_month';
  static const String _saleUnitDefault = 'per_sqft';

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

  @override
  void initState() {
    super.initState();
    _loadPropertyInfoAndSetDefaults();
  }

  Future<void> _loadPropertyInfoAndSetDefaults() async {
    try {
      final property = await PropertyService.fetchPropertyRaw(widget.propertyId);
      final isBookable = property['is_bookable'] == true;
      final propertyTypeName = (property['property_type'] ?? '').toString().toLowerCase();

      String computedDefault;
      if (isBookable) {
        // Date-wise booking properties (e.g. Banquet Halls)
        computedDefault = 'per_day';
      } else if (propertyTypeName.contains('plot')) {
        // Plots on lease/rent
        computedDefault = 'per_year';
      } else {
        computedDefault = 'per_month';
      }

      if (mounted) {
        setState(() {
          _defaultRentUnit = computedDefault;
          if (_listingType == 'rent') _priceUnit = computedDefault;
          _isLoadingPropertyInfo = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingPropertyInfo = false);
    }
  }

  @override
  void dispose() {
    _rentAmountController.dispose();
    _securityDepositController.dispose();
    _maintenanceController.dispose();
    _totalPriceController.dispose();
    _ratePerUnitController.dispose();
    _bookingPriceController.dispose();
    super.dispose();
  }

  void _onListingTypeChanged(String? value) {
    if (value == null) return;
    setState(() {
      _listingType = value;
      _priceUnit = value == 'rent' ? _defaultRentUnit : _saleUnitDefault;
    });
  }

  double? _parseOrNull(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return null;
    return double.tryParse(trimmed);
  }

  Future<void> _saveAndContinue() async {
    double? rentAmount, securityDeposit, maintenanceAmount;
    double? totalPrice, ratePerUnit, bookingPrice;

    if (_listingType == 'rent') {
      final rentText = _rentAmountController.text.trim();
      if (rentText.isEmpty) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text("Rent Amount is required.")));
        return;
      }
      rentAmount = double.tryParse(rentText);
      if (rentAmount == null || rentAmount <= 0) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text("Please enter a valid Rent Amount.")));
        return;
      }
      securityDeposit = _parseOrNull(_securityDepositController.text);
      maintenanceAmount = _parseOrNull(_maintenanceController.text);
    } else {
      final totalText = _totalPriceController.text.trim();
      if (totalText.isEmpty) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text("Total Price is required.")));
        return;
      }
      totalPrice = double.tryParse(totalText);
      if (totalPrice == null || totalPrice <= 0) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text("Please enter a valid Total Price.")));
        return;
      }
      ratePerUnit = _parseOrNull(_ratePerUnitController.text);
      bookingPrice = _parseOrNull(_bookingPriceController.text);
    }

    setState(() => _isSaving = true);

    final result = await PropertyService.updatePricing(
      propertyId: widget.propertyId,
      listingType: _listingType,
      priceUnit: _priceUnit,
      rentAmount: rentAmount,
      rentNegotiable: _rentNegotiable,
      securityDeposit: securityDeposit,
      securityDepositNegotiable: _securityDepositNegotiable,
      maintenanceAmount: maintenanceAmount,
      maintenanceNegotiable: _maintenanceNegotiable,
      totalPrice: totalPrice,
      totalPriceNegotiable: _totalPriceNegotiable,
      ratePerUnit: ratePerUnit,
      ratePerUnitNegotiable: _ratePerUnitNegotiable,
      bookingPrice: bookingPrice,
      bookingPriceNegotiable: _bookingPriceNegotiable,
    );

    setState(() => _isSaving = false);

    if (!mounted) return;

    if (result["success"] == true) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PostPropertyAttributesScreen(propertyId: widget.propertyId),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Could not save. Please try again.")),
      );
    }
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
                          child: Text(opt['label']!, style: const TextStyle(fontSize: 12)),
                        ))
                    .toList(),
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
              Checkbox(
                value: negotiableValue,
                onChanged: (val) => onNegotiableChanged(val ?? false),
              ),
              const Text("Negotiable", style: TextStyle(fontSize: 9)),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingPropertyInfo) {
      return Scaffold(
        appBar: AppBar(title: const Text("Pricing")),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Pricing")),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text("Listing Type", style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            value: _listingType,
            decoration: const InputDecoration(border: OutlineInputBorder()),
            items: const [
              DropdownMenuItem(value: 'rent', child: Text('Rent')),
              DropdownMenuItem(value: 'sale', child: Text('Sale')),
            ],
            onChanged: _onListingTypeChanged,
          ),
          const SizedBox(height: 16),

          if (_listingType == 'rent') ...[
            _amountRow(
              "Rent Amount", _rentAmountController, _rentNegotiable,
              (val) => setState(() => _rentNegotiable = val),
              required: true,
              unitOptions: _rentUnitOptions,
            ),
            _amountRow(
              "Security Deposit", _securityDepositController, _securityDepositNegotiable,
              (val) => setState(() => _securityDepositNegotiable = val),
            ),
            _amountRow(
              "Maintenance", _maintenanceController, _maintenanceNegotiable,
              (val) => setState(() => _maintenanceNegotiable = val),
            ),
          ] else ...[
            _amountRow(
              "Total Price", _totalPriceController, _totalPriceNegotiable,
              (val) => setState(() => _totalPriceNegotiable = val),
              required: true,
            ),
            _amountRow(
              "Rate Per Unit", _ratePerUnitController, _ratePerUnitNegotiable,
              (val) => setState(() => _ratePerUnitNegotiable = val),
              unitOptions: _saleUnitOptions,
            ),
            _amountRow(
              "Booking Price", _bookingPriceController, _bookingPriceNegotiable,
              (val) => setState(() => _bookingPriceNegotiable = val),
            ),
          ],

          const SizedBox(height: 20),
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