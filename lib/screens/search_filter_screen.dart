import 'dart:async';
import 'package:flutter/material.dart';
import '../models/property_type_model.dart';
import '../services/property_type_service.dart';
import '../services/property_service.dart';
import '../theme/app_theme.dart';
import '../widgets/animated_hint_search_field.dart';
import 'locality_search_screen.dart';

/// Screen A - opened when the user taps the search bar on Home.
/// Shows property type tiles, an embedded (tap-to-open) search row, listing
/// type, price range, and a single "View X matching Properties" button at
/// the bottom with a live-updating count.
class SearchFilterScreen extends StatefulWidget {
  final String? initialSearch;
  final String? initialCity;
  final int? initialPropertyTypeId;
  final String? initialListingType;
  final double? initialMinPrice;
  final double? initialMaxPrice;

  const SearchFilterScreen({
    super.key,
    this.initialSearch,
    this.initialCity,
    this.initialPropertyTypeId,
    this.initialListingType,
    this.initialMinPrice,
    this.initialMaxPrice,
  });

  @override
  State<SearchFilterScreen> createState() => _SearchFilterScreenState();
}

class _SearchFilterScreenState extends State<SearchFilterScreen> {
  late final TextEditingController _searchDisplayController;
  late TextEditingController _minPriceController;
  late TextEditingController _maxPriceController;

  String _searchText = '';
  int? _selectedPropertyTypeId;
  String? _selectedListingType;

  List<PropertyTypeModel> _propertyTypes = [];
  bool _isLoadingTypes = true;

  int? _matchingCount;
  bool _countLoading = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _searchText = widget.initialSearch ?? widget.initialCity ?? '';
    _searchDisplayController = TextEditingController(text: _searchText);
    _minPriceController =
        TextEditingController(text: widget.initialMinPrice?.toStringAsFixed(0) ?? '');
    _maxPriceController =
        TextEditingController(text: widget.initialMaxPrice?.toStringAsFixed(0) ?? '');
    _selectedPropertyTypeId = widget.initialPropertyTypeId;
    _selectedListingType = widget.initialListingType;

    _loadPropertyTypes();
    _updateCount();

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
    _debounce?.cancel();
    _updateCount();
  }

  Future<void> _updateCount() async {
    setState(() => _countLoading = true);
    try {
      // Search text and every filter field are sent together, so the count
      // always reflects the combination - not filters alone, and not search
      // alone. This is what keeps the count accurate per your point 4.
      final results = await PropertyService.fetchProperties(
        search: _searchText.trim().isEmpty ? null : _searchText.trim(),
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

  Future<void> _openLocalitySearch() async {
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (context) => LocalitySearchScreen(
          initialText: _searchText,
          propertyTypeId: _selectedPropertyTypeId,
          listingType: _selectedListingType,
          minPrice: double.tryParse(_minPriceController.text.trim()),
          maxPrice: double.tryParse(_maxPriceController.text.trim()),
        ),
      ),
    );
    if (result != null) {
      setState(() {
        _searchText = result;
        _searchDisplayController.text = result;
      });
      _updateCount();
    }
  }

  void _resetFilters() {
    setState(() {
      _searchText = '';
      _searchDisplayController.clear();
      _minPriceController.clear();
      _maxPriceController.clear();
      _selectedPropertyTypeId = null;
      _selectedListingType = null;
    });
    _updateCount();
  }

  void _applyAndReturn() {
    Navigator.pop(context, {
      'search': _searchText.trim(),
      'propertyTypeId': _selectedPropertyTypeId,
      'listingType': _selectedListingType,
      'minPrice': double.tryParse(_minPriceController.text.trim()),
      'maxPrice': double.tryParse(_maxPriceController.text.trim()),
    });
  }

  int get _activeFilterCount {
    int count = 0;
    if (_selectedPropertyTypeId != null) count++;
    if (_selectedListingType != null) count++;
    if (double.tryParse(_minPriceController.text.trim()) != null) count++;
    if (double.tryParse(_maxPriceController.text.trim()) != null) count++;
    if (_searchText.trim().isNotEmpty) count++;
    return count;
  }

  // Simple name-based icon guess for property type tiles, since the backend
  // model doesn't currently send its own icon. Replace/extend this if you
  // add an icon field to AttributeDefinition/PropertyType later.
  IconData _iconForPropertyType(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('flat') || lower.contains('apartment')) return Icons.apartment;
    if (lower.contains('plot') || lower.contains('land')) return Icons.landscape;
    if (lower.contains('banquet') || lower.contains('hall')) return Icons.celebration;
    if (lower.contains('office')) return Icons.business;
    if (lower.contains('shop') || lower.contains('commercial')) return Icons.storefront;
    if (lower.contains('hostel') || lower.contains('room')) return Icons.bed;
    return Icons.home_work;
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchDisplayController.dispose();
    _minPriceController.dispose();
    _maxPriceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Filters ($_activeFilterCount selected)'),
        actions: [
          TextButton(
            onPressed: _resetFilters,
            child: const Text('Reset'),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Row 1 - property type tiles
                    const Text("Property Type", style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    _isLoadingTypes
                        ? const Padding(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            child: Center(child: CircularProgressIndicator()),
                          )
                        : SizedBox(
                            height: 84,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: _propertyTypes.length,
                              separatorBuilder: (_, __) => const SizedBox(width: 10),
                              itemBuilder: (context, index) {
                                final type = _propertyTypes[index];
                                final selected = _selectedPropertyTypeId == type.id;
                                return GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _selectedPropertyTypeId = selected ? null : type.id;
                                    });
                                    _onDiscreteFieldChanged();
                                  },
                                  child: Container(
                                    width: 76,
                                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                                    decoration: BoxDecoration(
                                      color: selected ? AppColors.primary.withValues(alpha: 0.1) : Colors.white,
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(
                                        color: selected ? AppColors.primary : AppColors.cardBorder,
                                        width: selected ? 1.5 : 1,
                                      ),
                                    ),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          _iconForPropertyType(type.name),
                                          color: selected ? AppColors.primary : AppColors.textMuted,
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          type.name,
                                          textAlign: TextAlign.center,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: selected ? AppColors.primary : AppColors.textPrimary,
                                            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                    const SizedBox(height: 16),

                    // Row 2 - the search box itself. Wrapped in AbsorbPointer
                    // so tapping it never opens a keyboard here - it always
                    // navigates to the dedicated search/locality screen instead.
                    GestureDetector(
                      onTap: _openLocalitySearch,
                      child: AbsorbPointer(
                        child: AnimatedHintSearchField(
                          controller: _searchDisplayController,
                          hints: const ['Search locality, project, or keyword...'],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Row 3 - listing type
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
                    const SizedBox(height: 16),

                    // Row 4 - price range
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
                    // TODO: property-type-specific filters (e.g. BHK, Furnishing)
                    // go here once we build that - deferred per your point 3.
                  ],
                ),
              ),
            ),
            // Bottom - single button, doubles as the live count display
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _applyAndReturn,
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
            ),
          ],
        ),
      ),
    );
  }
}