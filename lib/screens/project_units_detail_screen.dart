import 'package:flutter/material.dart';
import '../services/project_service.dart';
import '../services/property_service.dart';
import '../utils/number_utils.dart';

class ProjectUnitsDetailScreen extends StatefulWidget {
  final int projectId;
  final String projectName;

  const ProjectUnitsDetailScreen({super.key, required this.projectId, this.projectName = ''});

  @override
  State<ProjectUnitsDetailScreen> createState() => _ProjectUnitsDetailScreenState();
}

class _ProjectUnitsDetailScreenState extends State<ProjectUnitsDetailScreen> {
  Map<String, dynamic>? _project;
  List<Map<String, dynamic>> _units = [];
  bool _isLoading = true;
  String? _loadError;

  static const Map<String, String> _unitSuffixes = {
    'per_day': '/day',
    'per_month': '/month',
    'per_year': '/year',
    'per_sqft': '/sq.ft.',
    'per_katha': '/katha',
  };

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });
    try {
      final project = await ProjectService.fetchProjectRaw(widget.projectId);
      final units = await PropertyService.fetchUnitsForProject(widget.projectId);
      setState(() {
        _project = project;
        _units = units;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _loadError = "Could not load project details. Please check your internet connection.";
        _isLoading = false;
      });
    }
  }

  String _unitPriceLabel(Map<String, dynamic> unit) {
    final listingType = unit['listing_type'] as String? ?? 'rent';
    final amount = listingType == 'rent'
        ? NumberUtils.parseFlexibleDouble(unit['rent_amount'])
        : NumberUtils.parseFlexibleDouble(unit['total_price']);
    if (amount == null) return 'Price not set';
    final unitCode = unit['price_unit'] as String? ?? '';
    final suffix = _unitSuffixes[unitCode] ?? '';
    return '₹${NumberUtils.formatPrice(amount)}$suffix';
  }

  Widget _amenityRow(Map<String, dynamic> attr) {
    final name = attr['attribute_name'] ?? '';
    final value = attr['value'] ?? '';
    final unitValue = attr['unit_value'] as String? ?? '';
    if (value.toString().isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        "$name: $value${unitValue.isNotEmpty ? ' $unitValue' : ''}",
        style: const TextStyle(fontSize: 13),
      ),
    );
  }

  Widget _commonAmenitiesSection() {
    final attrs = (_project?['attribute_values'] as List<dynamic>? ?? [])
        .where((a) => (a['value'] ?? '').toString().isNotEmpty)
        .toList();
    if (attrs.isEmpty) return const SizedBox.shrink();

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Common Amenities", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ...attrs.map((a) => _amenityRow(a as Map<String, dynamic>)),
          ],
        ),
      ),
    );
  }

  Widget _projectHeader() {
    final project = _project!;
    final name = project['name'] as String? ?? '';
    final builderName = project['builder_name'] as String? ?? '';
    final locality = project['locality'] as String? ?? '';
    final city = project['city'] as String? ?? '';
    final listingType = project['listing_type'] as String? ?? '';

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(name.isEmpty ? "(Unnamed project)" : name,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            if (builderName.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text("By $builderName", style: const TextStyle(color: Colors.black54)),
              ),
            const SizedBox(height: 6),
            if (locality.isNotEmpty || city.isNotEmpty)
              Text([locality, city].where((s) => s.isNotEmpty).join(', ')),
            const SizedBox(height: 6),
            Text(
              "Listing Type: ${listingType == 'rent' ? 'Rent' : 'Sale'}",
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _unitCard(Map<String, dynamic> unit) {
    final title = unit['title'] as String? ?? '';
    final status = unit['status'] as String? ?? '';
    final attrs = (unit['attribute_values'] as List<dynamic>? ?? [])
        .where((a) => (a['value'] ?? '').toString().isNotEmpty)
        .toList();
    final mediaCount = (unit['media'] as List<dynamic>? ?? [])
        .where((m) => m['media_type'] == 'image')
        .length;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold))),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    status.isEmpty ? '' : status[0].toUpperCase() + status.substring(1),
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(_unitPriceLabel(unit), style: const TextStyle(fontSize: 13)),
            Text("$mediaCount photo(s)", style: const TextStyle(fontSize: 12, color: Colors.black54)),
            if (attrs.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Divider(height: 1),
              const SizedBox(height: 6),
              ...attrs.map((a) => _amenityRow(a as Map<String, dynamic>)),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.projectName.isNotEmpty ? widget.projectName : "Project Details")),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _loadError != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_loadError!),
                      const SizedBox(height: 12),
                      ElevatedButton(onPressed: _loadAll, child: const Text("Try Again")),
                    ],
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(12),
                  children: [
                    _projectHeader(),
                    _commonAmenitiesSection(),
                    Text("Units (${_units.length})", style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    if (_units.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Text("No units created yet.", style: TextStyle(color: Colors.black54)),
                      )
                    else
                      ..._units.map(_unitCard),
                  ],
                ),
    );
  }
}