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
  // Rent fields
  final TextEditingController _rentAmountController = TextEditingController();
  final TextEditingController _securityDepositController = TextEditingController();
  final TextEditingController _maintenanceController = TextEditingController();

  // Sale fields
  final TextEditingController _totalPriceController = TextEditingController();
  final TextEditingController _ratePerUnitController = TextEditingController();
  final TextEditingController _bookingPriceController = TextEditingController();

  String _listingType = 'rent';
  String _priceUnit = 'per_month';
  bool _isSaving = false;

  final Map<String, List<Map<String, String>>> _priceUnitOptions = {
    'rent': [
      {'value': 'per_day', 'label': 'Per Day'},
      {'value': 'per_month', 'label': 'Per Month'},
      {'value': 'per_year', 'label': 'Per Year'},
    ],
    'sale': [
      {'value': 'total', 'label': 'Total Price'},
      {'value': 'per_sqft', 'label': 'Per Sq.Ft.'},
      {'value': 'per_katha', 'label': 'Per Katha'},
    ],
  };

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
      _priceUnit = _priceUnitOptions[_listingType]!.first['value']!;
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
      securityDeposit: securityDeposit,
      maintenanceAmount: maintenanceAmount,
      totalPrice: totalPrice,
      ratePerUnit: ratePerUnit,
      bookingPrice: bookingPrice,
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

  Widget _amountField(String label, TextEditingController controller, {bool required = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(
          labelText: required ? "$label *" : "$label (optional)",
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUnitOptions = _priceUnitOptions[_listingType]!;

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
            _amountField("Rent Amount", _rentAmountController, required: true),
            _amountField("Security Deposit", _securityDepositController),
            _amountField("Maintenance", _maintenanceController),
          ] else ...[
            _amountField("Total Price", _totalPriceController, required: true),
            _amountField("Rate Per Unit", _ratePerUnitController),
            _amountField("Booking Price", _bookingPriceController),
          ],

          const Text("Price Unit", style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            value: _priceUnit,
            decoration: const InputDecoration(border: OutlineInputBorder()),
            items: currentUnitOptions
                .map((opt) => DropdownMenuItem(
                      value: opt['value'],
                      child: Text(opt['label']!),
                    ))
                .toList(),
            onChanged: (value) {
              if (value != null) setState(() => _priceUnit = value);
            },
          ),

          const SizedBox(height: 32),
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