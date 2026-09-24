import 'package:flutter/material.dart';
import '../models/nearby_place_model.dart';
import '../services/property_type_service.dart';
import '../services/property_service.dart';
import 'post_property_description_screen.dart';

class PostPropertyNearbyPlacesScreen extends StatefulWidget {
  final int propertyId;

  const PostPropertyNearbyPlacesScreen({super.key, required this.propertyId});

  @override
  State<PostPropertyNearbyPlacesScreen> createState() =>
      _PostPropertyNearbyPlacesScreenState();
}

class _PostPropertyNearbyPlacesScreenState
    extends State<PostPropertyNearbyPlacesScreen> {
  List<NearbyPlaceCategoryModel> _categories = [];
  List<NearbyPlaceModel> _addedPlaces = [];

  bool _isLoading = true;
  String? _loadError;
  bool _isSubmittingDialog = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });
    try {
      final categories = await PropertyTypeService.fetchNearbyPlaceCategories();
      final property = await PropertyService.fetchPropertyRaw(widget.propertyId);
      final places = (property['nearby_places'] as List<dynamic>? ?? [])
          .map((p) => NearbyPlaceModel.fromJson(p))
          .toList();

      setState(() {
        _categories = categories;
        _addedPlaces = places;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _loadError = "Could not load nearby places. Please check your internet connection.";
        _isLoading = false;
      });
    }
  }

  Future<void> _showAddDialog(NearbyPlaceCategoryModel category) async {
    final nameController = TextEditingController();
    final distanceController = TextEditingController();
    String distanceUnit = 'km';

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              title: Text("Add ${category.name}"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: "${category.name} Name",
                      hintText: "e.g. AIIMS Patna",
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: distanceController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(
                            labelText: "Distance (optional)",
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      DropdownButton<String>(
                        value: distanceUnit,
                        items: const [
                          DropdownMenuItem(value: 'km', child: Text('km')),
                          DropdownMenuItem(value: 'm', child: Text('m')),
                        ],
                        onChanged: (value) {
                          if (value != null) setDialogState(() => distanceUnit = value);
                        },
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final name = nameController.text.trim();
                    if (name.isEmpty) return;

                    setDialogState(() => _isSubmittingDialog = true);

                    final distanceValue = double.tryParse(distanceController.text.trim());
                    final result = await PropertyService.addNearbyPlace(
                      propertyId: widget.propertyId,
                      categoryId: category.id,
                      name: name,
                      distanceValue: distanceValue,
                      distanceUnit: distanceUnit,
                    );

                    setDialogState(() => _isSubmittingDialog = false);

                    if (dialogContext.mounted) {
                      Navigator.pop(dialogContext, result["success"] == true);
                    }
                  },
                  child: _isSubmittingDialog
                      ? const SizedBox(
                          height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text("Add"),
                ),
              ],
            );
          },
        );
      },
    );

    if (saved == true) {
      await _loadData();
    }
  }

  Future<void> _deletePlace(NearbyPlaceModel place) async {
    final result = await PropertyService.deleteNearbyPlace(
      propertyId: widget.propertyId,
      placeId: place.id,
    );

    if (!mounted) return;

    if (result["success"] == true) {
      setState(() => _addedPlaces.removeWhere((p) => p.id == place.id));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Could not delete. Please try again.")),
      );
    }
  }

  void _continue() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PostPropertyDescriptionScreen(propertyId: widget.propertyId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Nearby Places")),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _loadError != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_loadError!),
                      const SizedBox(height: 12),
                      ElevatedButton(onPressed: _loadData, child: const Text("Try Again")),
                    ],
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    const Text(
                      "Add nearby colleges, hospitals, stations, etc. This step is optional.",
                      style: TextStyle(fontSize: 12, color: Colors.black54),
                    ),
                    const SizedBox(height: 16),

                    if (_categories.isEmpty)
                      const Text("No nearby-place categories set up yet.")
                    else
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _categories.map((category) {
                          return InkWell(
                            onTap: () => _showAddDialog(category),
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade400),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (category.iconUrl != null && category.iconUrl!.isNotEmpty)
                                    Image.network(
                                      category.iconUrl!,
                                      width: 20,
                                      height: 20,
                                      errorBuilder: (_, __, ___) =>
                                          const Icon(Icons.place_outlined, size: 20),
                                    )
                                  else
                                    const Icon(Icons.place_outlined, size: 20),
                                  const SizedBox(width: 6),
                                  Text(category.name),
                                  const SizedBox(width: 4),
                                  const Icon(Icons.add, size: 16),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),

                    const SizedBox(height: 24),

                    if (_addedPlaces.isNotEmpty) ...[
                      const Text("Added:", style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      ..._addedPlaces.map((place) {
                        return Card(
                          child: ListTile(
                            leading: place.categoryIconUrl != null && place.categoryIconUrl!.isNotEmpty
                                ? Image.network(
                                    place.categoryIconUrl!,
                                    width: 28,
                                    height: 28,
                                    errorBuilder: (_, __, ___) => const Icon(Icons.place_outlined),
                                  )
                                : const Icon(Icons.place_outlined),
                            title: Text(place.name),
                            subtitle: Text(
                              place.distanceValue != null
                                  ? "${place.categoryName} • ${place.distanceValue} ${place.distanceUnit}"
                                  : place.categoryName,
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.red),
                              onPressed: () => _deletePlace(place),
                            ),
                          ),
                        );
                      }),
                      const SizedBox(height: 16),
                    ],

                    ElevatedButton(
                      onPressed: _continue,
                      style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(14)),
                      child: const Text("Save & Continue"),
                    ),
                  ],
                ),
    );
  }
}