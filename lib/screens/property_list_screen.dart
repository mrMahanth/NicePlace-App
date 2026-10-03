import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/property_model.dart';
import '../services/property_service.dart';
import '../theme/app_theme.dart';
import 'property_detail_screen.dart';

class PropertyListScreen extends StatefulWidget {
  final String title;
  final int? propertyTypeId;
  final bool featured;
  final String? ordering;
  final double? nearLat;
  final double? nearLng;

  const PropertyListScreen({
    super.key,
    required this.title,
    this.propertyTypeId,
    this.featured = false,
    this.ordering,
    this.nearLat,
    this.nearLng,
  });

  @override
  State<PropertyListScreen> createState() => _PropertyListScreenState();
}

class _PropertyListScreenState extends State<PropertyListScreen> {
  late Future<List<Property>> _propertiesFuture;

  @override
  void initState() {
    super.initState();
    _propertiesFuture = PropertyService.fetchProperties(
      propertyTypeId: widget.propertyTypeId,
      featured: widget.featured,
      ordering: widget.ordering,
      nearLat: widget.nearLat,
      nearLng: widget.nearLng,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: FutureBuilder<List<Property>>(
        future: _propertiesFuture,
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
            padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 8),
            itemCount: properties.length,
            itemBuilder: (context, index) {
              final property = properties[index];
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: AppColors.cardBorder),
                ),
                child: InkWell(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => PropertyDetailScreen(property: property)),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    leading: property.media.any((m) => m.mediaType == 'image')
                        ? CachedNetworkImage(
                            imageUrl: property.media.firstWhere((m) => m.mediaType == 'image').file!,
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                          )
                        : const Icon(Icons.home, size: 40),
                    title: Text(property.title),
                    subtitle: Text(
                      "${property.locality}, ${property.city}",
                      style: const TextStyle(color: AppColors.textMuted),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}