import 'package:flutter/material.dart';
import '../models/property_model.dart';
import '../services/property_service.dart';
import '../utils/number_utils.dart';

class MyPropertiesScreen extends StatefulWidget {
  const MyPropertiesScreen({super.key});

  @override
  State<MyPropertiesScreen> createState() => _MyPropertiesScreenState();
}

class _MyPropertiesScreenState extends State<MyPropertiesScreen> {
  List<Property> _properties = [];
  bool _isLoading = true;
  String? _loadError;
  String _statusFilter = 'all';

  static const List<Map<String, String>> _filterOptions = [
    {'value': 'all', 'label': 'All'},
    {'value': 'draft', 'label': 'Draft'},
    {'value': 'under_review', 'label': 'Under Review'},
    {'value': 'live', 'label': 'Live'},
    {'value': 'sold', 'label': 'Sold'},
    {'value': 'rented', 'label': 'Rented'},
  ];

  static const Map<String, String> _unitSuffixes = {
    'per_day': '/day',
    'per_month': '/month',
    'per_year': '/year',
    'per_sqft': '/sq.ft.',
    'per_katha': '/katha',
    'total': '',
  };

  @override
  void initState() {
    super.initState();
    _loadProperties();
  }

  Future<void> _loadProperties() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });
    try {
      final properties = await PropertyService.fetchMyProperties();
      setState(() {
        _properties = properties;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _loadError = "Could not load your properties. Please check your internet connection.";
        _isLoading = false;
      });
    }
  }

  List<Property> get _filteredProperties {
    if (_statusFilter == 'all') return _properties;
    return _properties.where((p) => p.status == _statusFilter).toList();
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'draft':
        return Colors.grey;
      case 'under_review':
        return Colors.orange;
      case 'live':
        return Colors.green;
      case 'sold':
      case 'rented':
        return Colors.blue;
      case 'expired':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _statusLabel(String status) {
    if (status == 'under_review') return 'Under Review';
    return status.isEmpty ? '' : status[0].toUpperCase() + status.substring(1);
  }

  String _priceLabel(Property p) {
    double? amount = p.listingType == 'rent' ? p.rentAmount : p.totalPrice;
    amount ??= double.tryParse(p.price);
    if (amount == null || amount == 0) return 'Price not set';
    final suffix = _unitSuffixes[p.priceUnit] ?? '';
    return '₹${NumberUtils.formatPrice(amount)}$suffix';
  }

  String? _coverPhotoUrl(Property p) {
    if (p.media.isEmpty) return null;
    final cover = p.media.where((m) => m.mediaType == 'image' && m.isCover).toList();
    if (cover.isNotEmpty) return cover.first.file;
    final firstImage = p.media.where((m) => m.mediaType == 'image').toList();
    return firstImage.isNotEmpty ? firstImage.first.file : null;
  }

  Future<void> _confirmDelete(Property property) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text("Delete Listing"),
        content: Text(
          "Delete \"${property.title.isEmpty ? 'this draft' : property.title}\"? This cannot be undone.",
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text("Cancel")),
          TextButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text("Delete")),
        ],
      ),
    );
    if (confirmed != true) return;

    final result = await PropertyService.deleteProperty(property.id);
    if (!mounted) return;

    if (result["success"] == true) {
      setState(() => _properties.removeWhere((p) => p.id == property.id));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Could not delete. Please try again.")),
      );
    }
  }

  void _editComingSoon() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Editing existing listings is coming soon.")),
    );
  }

  Widget _propertyCard(Property property) {
    final coverUrl = _coverPhotoUrl(property);
    final isDraft = property.status == 'draft';
    final showRejection = isDraft && property.rejectionReason.isNotEmpty;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: coverUrl != null
                  ? Image.network(
                      coverUrl,
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 80,
                        height: 80,
                        color: Colors.grey.shade300,
                        child: const Icon(Icons.broken_image),
                      ),
                    )
                  : Container(
                      width: 80,
                      height: 80,
                      color: Colors.grey.shade300,
                      child: const Icon(Icons.home_outlined),
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    property.title.isEmpty ? "(Untitled)" : property.title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(_priceLabel(property), style: const TextStyle(fontSize: 13)),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: _statusColor(property.status).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _statusLabel(property.status),
                      style: TextStyle(
                        fontSize: 11,
                        color: _statusColor(property.status),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (showRejection) ...[
                    const SizedBox(height: 6),
                    Text(
                      "Rejected: ${property.rejectionReason}",
                      style: const TextStyle(fontSize: 12, color: Colors.red),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      TextButton(onPressed: _editComingSoon, child: const Text("Edit")),
                      if (isDraft)
                        TextButton(
                          onPressed: () => _confirmDelete(property),
                          style: TextButton.styleFrom(foregroundColor: Colors.red),
                          child: const Text("Delete"),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("My Properties")),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _loadError != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_loadError!),
                      const SizedBox(height: 12),
                      ElevatedButton(onPressed: _loadProperties, child: const Text("Try Again")),
                    ],
                  ),
                )
              : Column(
                  children: [
                    SizedBox(
                      height: 44,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        children: _filterOptions.map((opt) {
                          final selected = _statusFilter == opt['value'];
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text(opt['label']!),
                              selected: selected,
                              onSelected: (_) => setState(() => _statusFilter = opt['value']!),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    Expanded(
                      child: _filteredProperties.isEmpty
                          ? const Center(
                              child: Text("No properties found.", style: TextStyle(color: Colors.black54)))
                          : ListView(
                              padding: const EdgeInsets.all(12),
                              children: _filteredProperties.map(_propertyCard).toList(),
                            ),
                    ),
                  ],
                ),
    );
  }
}