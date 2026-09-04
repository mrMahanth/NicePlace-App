import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/property_model.dart';
import '../services/inquiry_service.dart';
import '../utils/auth_guard.dart';

class PropertyDetailScreen extends StatefulWidget {
  final Property property;

  const PropertyDetailScreen({super.key, required this.property});

  @override
  State<PropertyDetailScreen> createState() => _PropertyDetailScreenState();
}

class _PropertyDetailScreenState extends State<PropertyDetailScreen> {
  final _messageController =
      TextEditingController(text: "Hi, I am interested in this property.");
  bool _isSending = false;

  Future<void> _showContactDialog() async {
    final loggedIn = await AuthGuard.ensureLoggedIn(context);
    if (!loggedIn || !mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Contact Owner"),
        content: TextField(
          controller: _messageController,
          maxLines: 3,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            labelText: "Message",
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: _isSending ? null : _sendInquiry,
            child: _isSending
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text("Send"),
          ),
        ],
      ),
    );
  }

  Future<void> _sendInquiry() async {
    setState(() => _isSending = true);

    final result = await InquiryService.sendInquiry(
      propertyId: widget.property.id,
      message: _messageController.text.trim(),
    );

    setState(() => _isSending = false);

    if (mounted) Navigator.pop(context); // close dialog

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result["success"] == true
                ? "Inquiry sent successfully!"
                : "Failed to send inquiry. Please check if you are logged in.",
          ),
        ),
      );
    }
  }

  Future<void> _openDirections(double lat, double lng) async {
    final url = Uri.parse(
      "https://www.google.com/maps/dir/?api=1&destination=$lat,$lng",
    );
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Could not open Maps app.")),
        );
      }
    }
  }

  String _formatPrice(String price, String priceUnit) {
    final unitLabels = {
      'total': '',
      'per_day': '/day',
      'per_month': '/month',
      'per_year': '/year',
      'per_sqft': '/sq.ft.',
      'per_katha': '/katha',
    };
    final suffix = unitLabels[priceUnit] ?? '';
    return "₹$price$suffix";
  }

  String _buildAddress(Property p) {
    final parts = [p.locality, p.city, p.district, p.state, p.country]
        .where((part) => part.trim().isNotEmpty)
        .toList();
    return parts.join(", ");
  }

  @override
  Widget build(BuildContext context) {
    final property = widget.property;
    final hasLocation = property.latitude != null && property.longitude != null;

    return Scaffold(
      appBar: AppBar(title: Text(property.title)),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ---------- IMAGE GALLERY ----------
            if (property.media.isNotEmpty)
              SizedBox(
                height: 220,
                child: PageView.builder(
                  itemCount: property.media.length,
                  itemBuilder: (context, index) {
                    return Image.network(
                      property.media[index].file,
                      fit: BoxFit.cover,
                      width: double.infinity,
                    );
                  },
                ),
              )
            else
              Container(
                height: 220,
                color: Colors.grey[300],
                child: const Icon(Icons.home, size: 80, color: Colors.grey),
              ),

            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ---------- TITLE & PRICE ----------
                  Text(
                    property.title,
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _formatPrice(property.price, property.priceUnit),
                    style: const TextStyle(
                        fontSize: 20,
                        color: Colors.green,
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),

                  // ---------- TYPE / LISTING BADGES ----------
                  Wrap(
                    spacing: 8,
                    children: [
                      Chip(label: Text(property.propertyType)),
                      Chip(
                        label: Text(
                          property.listingType == 'rent' ? 'For Rent' : 'For Sale',
                        ),
                      ),
                      if (property.listedAs.isNotEmpty)
                        Chip(label: Text('Listed by ${property.listedAs}')),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // ---------- ADDRESS ----------
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.location_on, size: 18, color: Colors.grey),
                      const SizedBox(width: 4),
                      Expanded(child: Text(_buildAddress(property))),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // ---------- MAP (OpenStreetMap) ----------
                  if (hasLocation) ...[
                    const Text("Location",
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: SizedBox(
                        height: 200,
                        child: FlutterMap(
                          options: MapOptions(
                            initialCenter:
                                LatLng(property.latitude!, property.longitude!),
                            initialZoom: 15,
                            interactionOptions: const InteractionOptions(
                              flags: InteractiveFlag.pinchZoom | InteractiveFlag.drag,
                            ),
                          ),
                          children: [
                            TileLayer(
                              urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                              subdomains: const ['a', 'b', 'c'],
                              userAgentPackageName: 'com.niceplace.app',
                            ),
                            MarkerLayer(
                              markers: [
                                Marker(
                                  point: LatLng(
                                      property.latitude!, property.longitude!),
                                  width: 40,
                                  height: 40,
                                  child: const Icon(Icons.location_pin,
                                      color: Colors.red, size: 40),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.directions),
                        label: const Text("Get Directions"),
                        onPressed: () => _openDirections(
                            property.latitude!, property.longitude!),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // ---------- DESCRIPTION ----------
                  const Text("Description",
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(property.description, style: const TextStyle(fontSize: 15)),
                  const SizedBox(height: 16),

                  // ---------- DYNAMIC ATTRIBUTES (auto-updates from admin panel) ----------
                  if (property.attributeValues.isNotEmpty) ...[
                    const Text("Property Details",
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    ...property.attributeValues.map((attr) {
                      final displayValue = attr.unitValue.isNotEmpty
                          ? "${attr.value} ${attr.unitValue}"
                          : attr.value;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: Text(attr.name,
                                  style: const TextStyle(color: Colors.grey)),
                            ),
                            Expanded(
                              flex: 3,
                              child: Text(displayValue),
                            ),
                          ],
                        ),
                      );
                    }),
                    const SizedBox(height: 16),
                  ],

                  // ---------- TAGS ----------
                  if (property.tags.isNotEmpty) ...[
                    const Text("Tags",
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      children: property.tags
                          .map((t) => Chip(label: Text(t)))
                          .toList(),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // ---------- OWNER INFO ----------
                  const Text("Listed by",
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  Text(property.ownerName),
                  if (property.ownerPhone != null &&
                      property.ownerPhone!.isNotEmpty)
                    Text(property.ownerPhone!),
                  const SizedBox(height: 24),

                  // ---------- CONTACT OWNER BUTTON ----------
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.message),
                      label: const Text("Contact Owner"),
                      style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14)),
                      onPressed: _showContactDialog,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}