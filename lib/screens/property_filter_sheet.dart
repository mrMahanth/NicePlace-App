import 'package:flutter/material.dart';
import '../models/property_type_model.dart';
import '../services/property_type_service.dart';

// Ye widget ek Map return karta hai jisme saare selected filters hote hain
class PropertyFilterSheet extends StatefulWidget {
  final String? initialCity;
  final int? initialPropertyTypeId;
  final String? initialListingType;
  final double? initialMinPrice;
  final double? initialMaxPrice;

  const PropertyFilterSheet({
    super.key,
    this.initialCity,
    this.initialPropertyTypeId,
    this.initialListingType,
    this.initialMinPrice,
    this.initialMaxPrice,
  });

  @override
  State<PropertyFilterSheet> createState() => _PropertyFilterSheetState();
}

class _PropertyFilterSheetState extends State<PropertyFilterSheet> {
  late TextEditingController _cityController;
  late TextEditingController _minPriceController;
  late TextEditingController _maxPriceController;

  int? _selectedPropertyTypeId;
  String? _selectedListingType; // null = Any, 'rent', 'sale'

  List<PropertyTypeModel> _propertyTypes = [];
  bool _isLoadingTypes = true;

  @override
  void initState() {
    super.initState();
    _cityController = TextEditingController(text: widget.initialCity ?? '');
    _minPriceController = TextEditingController(
        text: widget.initialMinPrice?.toStringAsFixed(0) ?? '');
    _maxPriceController = TextEditingController(
        text: widget.initialMaxPrice?.toStringAsFixed(0) ?? '');
    _selectedPropertyTypeId = widget.initialPropertyTypeId;
    _selectedListingType = widget.initialListingType;
    _loadPropertyTypes();
  }

  Future<void> _loadPropertyTypes() async {
    try {
      final types = await PropertyTypeService.fetchPropertyTypes();
      setState(() {
        _propertyTypes = types;
        _isLoadingTypes = false;
      });
    } catch (e) {
      setState(() => _isLoadingTypes = false);
    }
  }

  @override
  void dispose() {
    _cityController.dispose();
    _minPriceController.dispose();
    _maxPriceController.dispose();
    super.dispose();
  }

  void _applyFilters() {
    Navigator.pop(context, {
      'city': _cityController.text.trim(),
      'propertyTypeId': _selectedPropertyTypeId,
      'listingType': _selectedListingType,
      'minPrice': double.tryParse(_minPriceController.text.trim()),
      'maxPrice': double.tryParse(_maxPriceController.text.trim()),
    });
  }

  void _clearFilters() {
    Navigator.pop(context, {
      'city': '',
      'propertyTypeId': null,
      'listingType': null,
      'minPrice': null,
      'maxPrice': null,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      // Keyboard khulne par sheet upar ho jaye
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Filter Properties",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ---------- CITY ----------
            TextField(
              controller: _cityController,
              decoration: const InputDecoration(
                labelText: "City",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // ---------- PROPERTY TYPE ----------
            _isLoadingTypes
                ? const Center(child: CircularProgressIndicator())
                : DropdownButtonFormField<int?>(
                    value: _selectedPropertyTypeId,
                    decoration: const InputDecoration(
                      labelText: "Property Type",
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      const DropdownMenuItem<int?>(
                        value: null,
                        child: Text("Any"),
                      ),
                      ..._propertyTypes.map((type) => DropdownMenuItem<int?>(
                            value: type.id,
                            child: Text(type.name),
                          )),
                    ],
                    onChanged: (value) {
                      setState(() => _selectedPropertyTypeId = value);
                    },
                  ),
            const SizedBox(height: 16),

            // ---------- LISTING TYPE ----------
            const Text("Listing Type",
                style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                ChoiceChip(
                  label: const Text("Any"),
                  selected: _selectedListingType == null,
                  onSelected: (_) => setState(() => _selectedListingType = null),
                ),
                ChoiceChip(
                  label: const Text("For Rent"),
                  selected: _selectedListingType == 'rent',
                  onSelected: (_) => setState(() => _selectedListingType = 'rent'),
                ),
                ChoiceChip(
                  label: const Text("For Sale"),
                  selected: _selectedListingType == 'sale',
                  onSelected: (_) => setState(() => _selectedListingType = 'sale'),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ---------- PRICE RANGE ----------
            const Text("Price Range", style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _minPriceController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: "Min Price",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _maxPriceController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: "Max Price",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // ---------- BUTTONS ----------
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _clearFilters,
                    child: const Text("Clear All"),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _applyFilters,
                    child: const Text("Apply Filters"),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}