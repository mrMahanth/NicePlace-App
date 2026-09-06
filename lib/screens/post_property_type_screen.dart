import 'package:flutter/material.dart';
import '../models/property_type_model.dart';
import '../models/property_category_model.dart';
import '../services/property_type_service.dart';
import '../services/property_service.dart';
import 'post_property_basic_details_screen.dart';

class PostPropertyTypeScreen extends StatefulWidget {
  const PostPropertyTypeScreen({super.key});

  @override
  State<PostPropertyTypeScreen> createState() => _PostPropertyTypeScreenState();
}

class _PostPropertyTypeScreenState extends State<PostPropertyTypeScreen> {
  List<PropertyCategoryModel> _categories = [];
  List<PropertyTypeModel> _types = [];
  bool _isLoading = true;
  String? _loadError;

  bool _isCreatingDraft = false;

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
      final categories = await PropertyTypeService.fetchPropertyCategories();
      final types = await PropertyTypeService.fetchPropertyTypes();
      setState(() {
        _categories = categories;
        _types = types;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _loadError = "Could not load property types. Please check your internet connection.";
        _isLoading = false;
      });
    }
  }

  List<PropertyTypeModel> _typesForCategory(int categoryId) {
    return _types.where((t) => t.categoryId == categoryId).toList();
  }

  Color _colorFromHex(String hex) {
    try {
      String cleaned = hex.replaceAll('#', '');
      if (cleaned.length == 6) cleaned = 'FF$cleaned';
      return Color(int.parse(cleaned, radix: 16));
    } catch (e) {
      return Colors.green;
    }
  }

  // ---------- NAYA: tap karte hi Individual/Project choice popup ----------
  Future<void> _showListingChoiceDialog(PropertyTypeModel type) async {
    final choice = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text("How do you want to list this?"),
        content: Text("Selected type: ${type.name}"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, 'project'),
            child: const Text("Part of a Project"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, 'individual'),
            child: const Text("Individual Property"),
          ),
        ],
      ),
    );

    if (!mounted) return;

    if (choice == 'individual') {
      _onTypeSelected(type);
    } else if (choice == 'project') {
      _showComingSoonDialog();
    }
    // choice == null (Cancel ya dialog ke bahar tap) -> kuch nahi karte
  }

  Future<void> _showComingSoonDialog() async {
    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text("Coming Soon"),
        content: const Text(
          "Posting a property as part of a Project will be available soon.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text("Back"),
          ),
        ],
      ),
    );
  }

  Future<void> _onTypeSelected(PropertyTypeModel type) async {
    if (_isCreatingDraft) return;

    setState(() => _isCreatingDraft = true);

    try {
      final result = await PropertyService.createDraftProperty(type.id);

      if (!mounted) return;

      if (result["success"] == true) {
        final propertyId = result["data"]["id"];
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PostPropertyBasicDetailsScreen(propertyId: propertyId),
          ),
        );
      } else {
        debugPrint("createDraftProperty failed: ${result["error"]}");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Could not start property listing. Please try again.")),
        );
      }
    } catch (e) {
      debugPrint("createDraftProperty exception: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Something went wrong: $e")),
        );
      }
    } finally {
      if (mounted) setState(() => _isCreatingDraft = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Select Property Type")),
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
              : Stack(
                  children: [
                    ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: _categories.length,
                      itemBuilder: (context, index) {
                        final category = _categories[index];
                        final typesInCategory = _typesForCategory(category.id);
                        if (typesInCategory.isEmpty) return const SizedBox.shrink();

                        final categoryColor = _colorFromHex(category.color);

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: double.infinity,
                              margin: const EdgeInsets.only(top: 16, bottom: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: categoryColor.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(8),
                                border: Border(left: BorderSide(color: categoryColor, width: 4)),
                              ),
                              child: Text(
                                category.name,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: categoryColor,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                                childAspectRatio: 0.85,
                                crossAxisSpacing: 8,
                                mainAxisSpacing: 8,
                              ),
                              itemCount: typesInCategory.length,
                              itemBuilder: (context, i) {
                                final type = typesInCategory[i];
                                return InkWell(
                                  onTap: () => _showListingChoiceDialog(type),
                                  borderRadius: BorderRadius.circular(10),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Colors.grey.shade300),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    padding: const EdgeInsets.all(8),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        type.iconUrl != null && type.iconUrl!.isNotEmpty
                                            ? Image.network(
                                                type.iconUrl!,
                                                height: 40,
                                                width: 40,
                                                errorBuilder: (_, __, ___) =>
                                                    const Icon(Icons.home_work_outlined, size: 40),
                                              )
                                            : const Icon(Icons.home_work_outlined, size: 40),
                                        const SizedBox(height: 6),
                                        Text(
                                          type.name,
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        );
                      },
                    ),
                    if (_isCreatingDraft)
                      Container(
                        color: Colors.black26,
                        child: const Center(child: CircularProgressIndicator()),
                      ),
                  ],
                ),
    );
  }
}