import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/property_model.dart';
import '../services/project_service.dart';
import '../theme/app_theme.dart';
import '../utils/number_utils.dart';
import '../widgets/property_card_list.dart';
import 'property_detail_screen.dart';

class ProjectDetailScreen extends StatefulWidget {
  final int projectId;
  final String? projectName;

  const ProjectDetailScreen({super.key, required this.projectId, this.projectName});

  @override
  State<ProjectDetailScreen> createState() => _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends State<ProjectDetailScreen> {
  Map<String, dynamic>? _project;
  bool _isLoading = true;
  String? _error;
  int _currentImageIndex = 0;

  static const Map<String, String> _unitSuffixes = {
    'per_day': '/day',
    'per_month': '/month',
    'per_year': '/year',
    'per_sqft': '/sq.ft.',
  };

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    final result = await ProjectService.fetchPublicProject(widget.projectId);
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      if (result['success'] == true) {
        _project = result['data'] as Map<String, dynamic>;
      } else {
        _error = result['error'] as String?;
      }
    });
  }

  List<String> get _imageUrls {
    final media = (_project?['media'] as List<dynamic>? ?? []);
    final images = media
        .where((m) => m['media_type'] == 'image' && m['file'] != null && (m['file'] as String).isNotEmpty)
        .toList();
    final covers = images.where((m) => m['is_cover'] == true).toList();
    final others = images.where((m) => m['is_cover'] != true).toList();
    return [...covers, ...others].map((m) => m['file'] as String).toList();
  }

  String? get _startingPriceLabel {
    final amount = NumberUtils.parseFlexibleDouble(_project?['starting_price']);
    if (amount == null) return null;
    final unit = _project?['starting_price_unit'] as String? ?? '';
    final suffix = _unitSuffixes[unit] ?? '';
    return 'Starting ₹${NumberUtils.formatPrice(amount)}$suffix';
  }

  Future<void> _openDocument(String url) async {
    final ok = await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Could not open this document.")),
      );
    }
  }

  Widget _sectionTitle(String text) => Padding(
        padding: const EdgeInsets.only(top: 20, bottom: 8),
        child: Text(text, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
      );

  Widget _buildGallery(List<String> images) {
    if (images.isEmpty) {
      return Container(
        height: 220,
        color: Colors.grey[300],
        child: const Center(child: Icon(Icons.apartment_outlined, size: 80, color: Colors.grey)),
      );
    }
    return SizedBox(
      height: 220,
      child: Stack(
        children: [
          PageView.builder(
            itemCount: images.length,
            onPageChanged: (i) => setState(() => _currentImageIndex = i),
            itemBuilder: (context, index) => Image.network(
              images[index],
              fit: BoxFit.cover,
              width: double.infinity,
              errorBuilder: (_, __, ___) => Container(
                color: Colors.grey[300],
                child: const Icon(Icons.broken_image, size: 60, color: Colors.grey),
              ),
            ),
          ),
          if (images.length > 1)
            Positioned(
              bottom: 8,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(images.length, (i) {
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: i == _currentImageIndex ? Colors.white : Colors.white54,
                    ),
                  );
                }),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildListedBy() {
    final info = _project!['listed_by_info'];
    final builderName = _project!['builder_name'] as String? ?? '';
    if (info is Map && info['verified'] == true) {
      final firm = (info['firm_name'] ?? '').toString();
      return Row(
        children: [
          Flexible(
            child: Text(
              firm.isNotEmpty ? 'By $firm' : 'Verified listing',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: 6),
          const Icon(Icons.verified, size: 18, color: AppColors.success),
        ],
      );
    }
    if (builderName.isNotEmpty) {
      return Text('By $builderName', style: const TextStyle(color: AppColors.textMuted));
    }
    return const SizedBox.shrink();
  }

  Widget _buildBody() {
    final p = _project!;
    final images = _imageUrls;
    final name = p['name'] as String? ?? '';
    final locality = p['locality'] as String? ?? '';
    final city = p['city'] as String? ?? '';
    final pincode = p['pincode'] as String? ?? '';
    final propertyType = p['property_type'] as String? ?? '';
    final listingType = p['listing_type'] as String? ?? '';
    final description = (p['description'] as String? ?? '').trim();
    final totalUnits = p['total_units'];

    final addressParts = [locality, city].where((s) => s.isNotEmpty).join(', ');
    final address = pincode.isNotEmpty ? '$addressParts - $pincode' : addressParts;

    final amenities = p['amenities'];
    final amenityNames = amenities is Map
        ? amenities.entries
            .where((e) => e.value != null && e.value != false && e.value.toString().isNotEmpty)
            .map((e) => e.key.toString())
            .toList()
        : <String>[];

    final attributes = (p['attribute_values'] as List<dynamic>? ?? [])
        .where((a) => (a['value'] ?? '').toString().isNotEmpty && a['attribute_type'] != 'file')
        .toList();
    final documents = p['documents'] as List<dynamic>? ?? [];
    final units = (p['live_units'] as List<dynamic>? ?? []).map((u) => Property.fromJson(u)).toList();
    final startingPrice = _startingPriceLabel;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildGallery(images),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                _buildListedBy(),
                if (address.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.location_on, size: 18, color: Colors.grey),
                      const SizedBox(width: 4),
                      Expanded(child: Text(address)),
                    ],
                  ),
                ],
                if (startingPrice != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    startingPrice,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primary),
                  ),
                ],
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  children: [
                    if (propertyType.isNotEmpty) Chip(label: Text(propertyType)),
                    if (listingType.isNotEmpty)
                      Chip(label: Text(listingType == 'rent' ? 'For Rent' : 'For Sale')),
                    if (totalUnits != null) Chip(label: Text('$totalUnits Units')),
                  ],
                ),
                if (description.isNotEmpty) ...[
                  _sectionTitle('About this project'),
                  Text(description, style: const TextStyle(fontSize: 15)),
                ],
                if (amenityNames.isNotEmpty) ...[
                  _sectionTitle('Amenities'),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: amenityNames.map((a) => Chip(label: Text(a))).toList(),
                  ),
                ],
                if (attributes.isNotEmpty) ...[
                  _sectionTitle('Project Details'),
                  ...attributes.map((a) {
                    final unit = (a['unit_value'] ?? '').toString();
                    final value = unit.isNotEmpty ? '${a['value']} $unit' : '${a['value']}';
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: Text('${a['attribute_name']}', style: const TextStyle(color: Colors.grey)),
                          ),
                          Expanded(flex: 3, child: Text(value)),
                        ],
                      ),
                    );
                  }),
                ],
                if (documents.isNotEmpty) ...[
                  _sectionTitle('Documents'),
                  ...documents.map((d) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: InkWell(
                          onTap: () => _openDocument('${d['file']}'),
                          child: Row(
                            children: [
                              const Icon(Icons.description_outlined, size: 18, color: AppColors.accent),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '${d['label']}',
                                  style: const TextStyle(
                                    color: AppColors.accent,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )),
                ],
                _sectionTitle(units.isEmpty ? 'Available Units' : 'Available Units (${units.length})'),
                if (units.isEmpty)
                  const Text('No live units available right now.', style: TextStyle(color: AppColors.textMuted)),
              ],
            ),
          ),
          ...units.map((unit) => PropertyCardList(
                property: unit,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => PropertyDetailScreen(property: unit)),
                ),
              )),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.projectName?.isNotEmpty == true ? widget.projectName! : 'Project')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_error!, textAlign: TextAlign.center),
                        const SizedBox(height: 12),
                        ElevatedButton(onPressed: _load, child: const Text('Try Again')),
                      ],
                    ),
                  ),
                )
              : _buildBody(),
    );
  }
}