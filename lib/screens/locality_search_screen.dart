import 'dart:async';
import 'package:flutter/material.dart';
import '../models/property_model.dart';
import '../services/property_service.dart';
import '../theme/app_theme.dart';
import '../widgets/animated_hint_search_field.dart';
import 'property_detail_screen.dart';

/// Screen B - opened when the user taps the (inactive) search row inside
/// the Filters screen. Opens with the keyboard already active. Shows
/// locality tiles (tapping one ADDS it to the search text, it does not
/// close the screen) and a live property results list below, driven by
/// the current search text combined with whatever filters were already
/// selected on the Filters screen. Tapping the filter icon (or pressing
/// back) returns to the Filters screen, carrying the current search text.
///
/// TODO: the locality list below is a placeholder. Once the backend has an
/// endpoint returning distinct localities with active properties (discussed
/// earlier - still pending), replace _placeholderLocalities with a real
/// fetch from that endpoint.
class LocalitySearchScreen extends StatefulWidget {
  final String? initialText;
  final int? propertyTypeId;
  final String? listingType;
  final double? minPrice;
  final double? maxPrice;

  const LocalitySearchScreen({
    super.key,
    this.initialText,
    this.propertyTypeId,
    this.listingType,
    this.minPrice,
    this.maxPrice,
  });

  @override
  State<LocalitySearchScreen> createState() => _LocalitySearchScreenState();
}

class _LocalitySearchScreenState extends State<LocalitySearchScreen> {
  late final TextEditingController _controller;
  Timer? _debounce;

  static const List<String> _placeholderLocalities = [
    'Boring Road',
    'Kankarbagh',
    'Danapur',
    'Patna City',
    'Rajendra Nagar',
    'Bailey Road',
    'Anishabad',
    'Fraser Road',
    'Gandhi Maidan',
  ];

  Future<List<Property>>? _resultsFuture;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialText ?? '');
    _controller.addListener(_onTextChanged);
    _runSearch();
  }

  void _onTextChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), _runSearch);
  }

  void _runSearch() {
    setState(() {
      _resultsFuture = PropertyService.fetchProperties(
        search: _controller.text.trim().isEmpty ? null : _controller.text.trim(),
        propertyTypeId: widget.propertyTypeId,
        listingType: widget.listingType,
        minPrice: widget.minPrice,
        maxPrice: widget.maxPrice,
      );
    });
  }

  // Tapping a locality tile ADDS it to the search text instead of closing
  // the screen, so the user can keep typing or add more localities.
  void _appendLocality(String locality) {
    final current = _controller.text.trim();
    final updated = current.isEmpty ? locality : '$current, $locality';
    _controller.text = updated;
    _controller.selection = TextSelection.fromPosition(
      TextPosition(offset: _controller.text.length),
    );
    _runSearch();
  }

  // Returns to the Filters screen, carrying the current search text along.
  void _returnToFilters() {
    Navigator.pop(context, _controller.text.trim());
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (didPop) return;
        Navigator.of(context).pop(_controller.text.trim());
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          titleSpacing: 8,
          title: AnimatedHintSearchField(
            controller: _controller,
            hints: const ['Find Flats...', 'Find Plots...', 'Search a locality...'],
            autofocus: true,
            onFilterTap: _returnToFilters,
          ),
        ),
        body: Column(
          children: [
            // Row 1 - locality tiles (tap to add to the search text)
            SizedBox(
              height: 56,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                scrollDirection: Axis.horizontal,
                itemCount: _placeholderLocalities.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final locality = _placeholderLocalities[index];
                  return ActionChip(
                    avatar: const Icon(Icons.location_on_outlined, size: 16),
                    label: Text(locality),
                    backgroundColor: Colors.white,
                    side: const BorderSide(color: AppColors.cardBorder),
                    onPressed: () => _appendLocality(locality),
                  );
                },
              ),
            ),
            const Divider(height: 1),
            // Live results, based on the current search text + filters
            // already chosen on the Filters screen.
            Expanded(
              child: FutureBuilder<List<Property>>(
                future: _resultsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text("Error: ${snapshot.error}"));
                  }
                  final properties = snapshot.data ?? [];
                  if (properties.isEmpty) {
                    return const Center(child: Text("No properties found."));
                  }
                  return ListView.builder(
                    itemCount: properties.length,
                    itemBuilder: (context, index) {
                      final property = properties[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        child: ListTile(
                          leading: property.media.any((m) => m.mediaType == 'image')
                              ? Image.network(
                                  property.media.firstWhere((m) => m.mediaType == 'image').file!,
                                  width: 56,
                                  height: 56,
                                  fit: BoxFit.cover,
                                )
                              : const Icon(Icons.home, size: 36),
                          title: Text(property.title),
                          subtitle: Text("${property.locality}, ${property.city}\n₹${property.price}"),
                          isThreeLine: true,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => PropertyDetailScreen(property: property),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}