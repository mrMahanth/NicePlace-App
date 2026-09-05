import 'dart:async';
import 'package:flutter/material.dart';
import '../models/property_type_model.dart';
import '../services/property_type_service.dart';
import '../services/property_service.dart';
import '../theme/app_theme.dart';

/// The filter panel that appears attached directly below the search box,
/// instead of a separate modal bottom sheet. Shows a live "View X matching
/// Properties" count that updates as the user adjusts filters.
class InlineFilterPanel extends StatefulWidget {
  final String? initialCity;
  final int? initialPropertyTypeId;
  final String? initialListingType;
  final double? initialMinPrice;
  final double? initialMaxPrice;
  final void Function(Map<String, dynamic> filters) onApply;
  final VoidCallback onClose;

  const InlineFilterPanel({
    super.key,
    this.initialCity,
    this.initialPropertyTypeId,
    this.initialListingType,
    this.initialMinPrice,
    this.initialMaxPrice,
    required this.onApply,
    required this.onClose,
  });

  @override
  State<InlineFilterPanel> createState() => _InlineFilterPanelState();
}

class _InlineFilterPanelState extends State<InlineFilterPanel> {
  late TextEditingController _cityController;
  late TextEditingController _minPriceController;
  late TextEditingController _maxPriceController;

  int? _selectedPropertyTypeId;
  String? _selectedListingType; // null = Any, 'rent', 'sale'

  List<PropertyTypeModel> _propertyTypes = [];
  bool _isLoadingTypes = true;

  int? _matchingCount;
  bool _countLoading = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _cityController = TextEditingController(text: widget.initialCity ?? '');
    _minPriceController =
        TextEditingController(text: widget.initialMinPrice?.toStringAsFixed(0) ?? '');
    _maxPriceController =
        TextEditingController(text: widget.initialMaxPrice?.toStringAsFixed(0) ?? '');
    _selectedPropertyTypeId = widget.initialPropertyTypeId;
    _selectedListingType = widget.initialListingType;
    _loadPropertyTypes();
    _updateCount();

    // Text fields (city/price) get debounced - waits until the user pauses
    // typing for 400ms before calling the API, so we don't fire a request
    // on every single keystroke.
    _cityController.addListener(_onTextFieldChanged);
    _minPriceController.addListener(_onTextFieldChanged);
    _maxPriceController.addListener(_onTextFieldChanged);
  }

  Future<void> _loadPropertyTypes() async {
    try {
      final types = await PropertyTypeService.fetchPropertyTypes();
      if (!mounted) return;
      setState(() {
        _propertyTypes = types;
        _isLoadingTypes = false;
      });
    } catch (e) {
      if (mounted) setState(() => _isLoadingTypes = false);
    }
  }

  void _onTextFieldChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), _updateCount);
  }

  void _onDiscreteFieldChanged() {
    // Dropdown/chip taps are discrete, not continuous typing - update right away.
    _debounce?.cancel();
    _updateCount();
  }

  Future<void> _updateCount() async {
    setState(() => _countLoading = true);
    try {
      final results = await PropertyService.fetchProperties(
        city: _cityController.text.trim().isEmpty ? null : _cityController.text.trim(),
        propertyTypeId: _selectedPropertyTypeId,
        listingType: _selectedListingType,
        minPrice: double.tryParse(_minPriceController.text.trim()),
        maxPrice: double.tryParse(_maxPriceController.text.trim()),
      );
      if (!mounted) return;
      setState(() {
        _matchingCount = results.length;
        _countLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _matchingCount = null;
        _countLoading = false;
      });
    }
  }

  void _clearFilters() {
    setState(() {
      _cityController.clear();
      _minPriceController.clear();
      _maxPriceController.clear();
      _selectedPropertyTypeId = null;
      _selectedListingType = null;
    });
    _updateCount();
  }

  void _applyFilters() {
    widget.onApply({
      'city': _cityController.text.trim(),
      'propertyTypeId': _selectedPropertyTypeId,
      'listingType': _selectedListingType,
      'minPrice': double.tryParse(_minPriceController.text.trim()),
      'maxPrice': double.tryParse(_maxPriceController.text.trim()),
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _cityController.dispose();
    _minPriceController.dispose();
    _maxPriceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(bottom: BorderSide(color: AppColors.cardBorder)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Filter Properties",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: widget.onClose,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 12),

          TextField(
            controller: _cityController,
            decoration: const InputDecoration(
              labelText: "City",
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
          const SizedBox(height: 12),

          _isLoadingTypes
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Center(child: CircularProgressIndicator()),
                )
              : DropdownButtonFormField<int?>(
                  value: _selectedPropertyTypeId,
                  decoration: const InputDecoration(
                    labelText: "Property Type",
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  items: [
                    const DropdownMenuItem<int?>(value: null, child: Text("Any")),
                    ..._propertyTypes.map(
                      (type) => DropdownMenuItem<int?>(value: type.id, child: Text(type.name)),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() => _selectedPropertyTypeId = value);
                    _onDiscreteFieldChanged();
                  },
                ),
          const SizedBox(height: 12),

          const Text("Listing Type", style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              ChoiceChip(
                label: const Text("Any"),
                selected: _selectedListingType == null,
                onSelected: (_) {
                  setState(() => _selectedListingType = null);
                  _onDiscreteFieldChanged();
                },
              ),
              ChoiceChip(
                label: const Text("For Rent"),
                selected: _selectedListingType == 'rent',
                onSelected: (_) {
                  setState(() => _selectedListingType = 'rent');
                  _onDiscreteFieldChanged();
                },
              ),
              ChoiceChip(
                label: const Text("For Sale"),
                selected: _selectedListingType == 'sale',
                onSelected: (_) {
                  setState(() => _selectedListingType = 'sale');
                  _onDiscreteFieldChanged();
                },
              ),
            ],
          ),
          const SizedBox(height: 12),

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
                    isDense: true,
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
                    isDense: true,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

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
                flex: 2,
                child: ElevatedButton(
                  onPressed: _applyFilters,
                  child: _countLoading
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Text(
                          _matchingCount != null
                              ? "View $_matchingCount matching Properties"
                              : "View matching Properties",
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}