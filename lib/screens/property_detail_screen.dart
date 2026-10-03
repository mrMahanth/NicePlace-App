import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/property_model.dart';
import '../models/user_profile_model.dart';
import '../services/api_service.dart';
import '../services/inquiry_service.dart';
import '../services/property_service.dart';
import '../services/user_profile_service.dart';
import '../utils/auth_guard.dart';
import '../widgets/tag_badge.dart';

// Backend DecimalFields kabhi "5000.00" jaisi string mein aate hain -
// isliye Indian-style comma formatting yahan khud likhi hai.
String _formatRupees(double value) {
  final isNegative = value < 0;
  final absVal = value.abs();
  final wholePart = absVal.truncate();
  final decimalPart = absVal - wholePart;

  String numStr = wholePart.toString();
  String lastThree = numStr.length > 3 ? numStr.substring(numStr.length - 3) : numStr;
  String otherDigits = numStr.length > 3 ? numStr.substring(0, numStr.length - 3) : '';

  if (otherDigits.isNotEmpty) {
    otherDigits = otherDigits.replaceAllMapped(
        RegExp(r'\B(?=(\d{2})+(?!\d))'), (match) => ',');
    lastThree = ',$lastThree';
  }

  String formatted = otherDigits + lastThree;
  if (decimalPart > 0) {
    formatted += '.${(decimalPart * 100).round().toString().padLeft(2, '0')}';
  }
  return (isNegative ? '-' : '') + '₹$formatted';
}

class PropertyDetailScreen extends StatefulWidget {
  final Property property;

  const PropertyDetailScreen({super.key, required this.property});

  @override
  State<PropertyDetailScreen> createState() => _PropertyDetailScreenState();
}

class _PropertyDetailScreenState extends State<PropertyDetailScreen> {
  late Property _property;
  final _messageController = TextEditingController();

  bool _isSending = false;
  bool _isCalling = false;
  bool _inquirySent = false;
  String? _inquiryError;

  int? _currentUserId;
  bool _isStaff = false;
  int _currentImageIndex = 0;

  bool get _isRentedOrSold => _property.status == 'rented' || _property.status == 'sold';
  bool get _isOwnProperty => _currentUserId != null && _property.ownerId == _currentUserId;

  @override
  void initState() {
    super.initState();
    _property = widget.property;
    _bootstrap();
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  // ---------- Startup: current user id, staff status, aur fresh property fetch ----------
  Future<void> _bootstrap() async {
    final userId = await ApiService.getCurrentUserId();
    if (mounted) setState(() => _currentUserId = userId);

    if (userId != null) {
      final profileResult = await UserProfileService.fetchMyProfile();
      if (mounted && profileResult['success'] == true) {
        final profile = profileResult['data'] as UserProfileModel;
        setState(() => _isStaff = profile.isStaff);
      }
    }

    await _refreshProperty();
  }

  // Token ke saath fresh fetch - taaki owner_phone (logged-in hone par) aur latest status mil sake
  Future<void> _refreshProperty() async {
    final result = await PropertyService.fetchPropertyDetail(widget.property.id);
    if (mounted && result['success'] == true) {
      setState(() => _property = result['data'] as Property);
    }
  }

  // ---------- Send Inquiry ----------
  Future<void> _onSendInquiry() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) {
      setState(() => _inquiryError = "Inquiry message is required.");
      return;
    }

    setState(() => _inquiryError = null);

    final loggedIn = await AuthGuard.ensureLoggedIn(context);
    if (!loggedIn || !mounted) return;

    setState(() => _isSending = true);

    final result = await InquiryService.sendInquiry(
      propertyId: _property.id,
      message: message,
    );

    if (!mounted) return;
    setState(() => _isSending = false);

    if (result["success"] == true) {
      setState(() => _inquirySent = true);
    } else {
      final statusCode = result["statusCode"];
      setState(() {
        _inquiryError = statusCode == 401
            ? "Login session has been expired. Please login again."
            : "Something went wrong. Please try again.";
      });
    }
  }

  // ---------- Call Owner ----------
  Future<void> _onCallOwner() async {
    final loggedIn = await AuthGuard.ensureLoggedIn(context);
    if (!loggedIn || !mounted) return;

    setState(() => _isCalling = true);

    // Phone abhi tak nahi mila (anonymous fetch tha) to login hone ke baad dobara try karo
    if (_property.ownerPhone == null || _property.ownerPhone!.isEmpty) {
      await _refreshProperty();
    }

    if (!mounted) return;
    setState(() => _isCalling = false);

    final phone = _property.ownerPhone;
    if (phone == null || phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Could not get owner's phone number. Please try again.")),
      );
      return;
    }

    final uri = Uri(scheme: 'tel', path: phone);
    if (!await launchUrl(uri)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Could not open dialer.")),
        );
      }
    }
  }

  Future<void> _openDirections(double lat, double lng) async {
    final url = Uri.parse("https://www.google.com/maps/dir/?api=1&destination=$lat,$lng");
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Could not open Maps app.")),
        );
      }
    }
  }

  Future<void> _openDirectionsQuery(String query) async {
    final url = Uri.parse("https://www.google.com/maps/dir/?api=1&destination=$query");
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Could not open Maps app.")),
        );
      }
    }
  }

  String _buildAddress(Property p) {
    final parts = [p.locality, p.city, p.district, p.state, p.country]
        .where((part) => part.trim().isNotEmpty)
        .toList();
    return parts.join(", ");
  }

  // ---------- PRICE BLOCK ----------
  Widget _negotiableBadge(bool show) {
    if (!show) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.only(left: 8),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFFEEF7EE),
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Text(
        "Negotiable",
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF2AA876)),
      ),
    );
  }

  Widget _buildPriceBlock(Property p) {
    if (p.listingType == 'sale') {
      final ratePerUnit = p.ratePerUnit;
      final totalPrice = p.totalPrice ?? double.tryParse(p.price); // legacy fallback
      final hasRate = ratePerUnit != null && ratePerUnit > 0;
      final rateUnitLabel = p.priceUnit == 'per_katha' ? 'Katha' : 'Sq.Ft.';

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Flexible(
                child: Text(
                  hasRate
                      ? "${_formatRupees(ratePerUnit)}/$rateUnitLabel"
                      : (totalPrice != null ? _formatRupees(totalPrice) : "Price on request"),
                  style: const TextStyle(
                      fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green),
                ),
              ),
              _negotiableBadge(hasRate ? p.ratePerUnitNegotiable : p.totalPriceNegotiable),
            ],
          ),
          if (hasRate && totalPrice != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                children: [
                  Text("Total Price: ${_formatRupees(totalPrice)}",
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                  _negotiableBadge(p.totalPriceNegotiable),
                ],
              ),
            ),
          if (p.bookingPrice != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                children: [
                  Text("Booking Amount: ${_formatRupees(p.bookingPrice!)}",
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                  _negotiableBadge(p.bookingPriceNegotiable),
                ],
              ),
            ),
        ],
      );
    }

    // ---- Rent ----
    const rentUnitLabels = {'per_day': 'day', 'per_month': 'month', 'per_year': 'year'};
    final rentUnitLabel = rentUnitLabels[p.priceUnit] ?? 'month';
    final rentAmount = p.rentAmount ?? double.tryParse(p.price); // legacy fallback

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Flexible(
              child: Text(
                rentAmount != null ? "${_formatRupees(rentAmount)}/$rentUnitLabel" : "Price on request",
                style: const TextStyle(
                    fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green),
              ),
            ),
            _negotiableBadge(p.rentNegotiable),
          ],
        ),
        if (p.securityDeposit != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(
              children: [
                Text("Security Deposit: ${_formatRupees(p.securityDeposit!)}",
                    style: const TextStyle(fontSize: 15)),
                _negotiableBadge(p.securityDepositNegotiable),
              ],
            ),
          ),
        if (p.maintenanceAmount != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(
              children: [
                Text("Maintenance: ${_formatRupees(p.maintenanceAmount!)}",
                    style: const TextStyle(fontSize: 15)),
                _negotiableBadge(p.maintenanceNegotiable),
              ],
            ),
          ),
      ],
    );
  }

  // ---------- STATUS BADGE ----------
  Widget? _buildStatusBadge(Property p) {
    if (p.status == 'rented') return _statusChip("Rented", Colors.orange);
    if (p.status == 'sold') return _statusChip("Sold", Colors.red);
    return null;
  }

  Widget _statusChip(String label, Color color) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
        ),
      );

  // ---------- NEARBY PLACES ----------
  Widget _buildNearbyPlaces(Property p) {
    if (p.nearbyPlaces.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Nearby Places",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ...p.nearbyPlaces.map((place) {
          final distance =
              place.distanceValue != null ? "${place.distanceValue} ${place.distanceUnit}" : "";
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                if (place.categoryIconUrl != null && place.categoryIconUrl!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Image.network(
                      place.categoryIconUrl!,
                      width: 20,
                      height: 20,
                      errorBuilder: (_, __, ___) => const Icon(Icons.place, size: 20),
                    ),
                  )
                else
                  const Padding(
                      padding: EdgeInsets.only(right: 8), child: Icon(Icons.place, size: 20)),
                Expanded(child: Text("${place.categoryName}: ${place.name}")),
                if (distance.isNotEmpty)
                  Text(distance, style: const TextStyle(color: Colors.grey)),
              ],
            ),
          );
        }),
        const SizedBox(height: 16),
      ],
    );
  }

  // ---------- DYNAMIC ATTRIBUTES ----------
  Widget _buildAttributes(Property p) {
    if (p.attributeValues.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Property Details",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ...p.attributeValues.map((attr) {
          if (attr.attributeType == 'file') {
            if (attr.file == null || attr.file!.isEmpty) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: InkWell(
                onTap: () => launchUrl(Uri.parse(attr.file!), mode: LaunchMode.externalApplication),
                child: Row(
                  children: [
                    Expanded(child: Text(attr.name, style: const TextStyle(color: Colors.grey))),
                    const Text("View File",
                        style: TextStyle(color: Colors.blue, decoration: TextDecoration.underline)),
                  ],
                ),
              ),
            );
          }

          if (attr.attributeType == 'checkbox') {
            final chips =
                attr.value.split(',').map((v) => v.trim()).where((v) => v.isNotEmpty).toList();
            if (chips.isEmpty) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(attr.name, style: const TextStyle(color: Colors.grey)),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: chips.map((c) => Chip(label: Text(c))).toList(),
                  ),
                ],
              ),
            );
          }

          final suffix = attr.unitValue.isNotEmpty ? attr.unitValue : attr.unitLabel;
          final displayValue = suffix.isNotEmpty ? "${attr.value} $suffix" : attr.value;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Expanded(flex: 2, child: Text(attr.name, style: const TextStyle(color: Colors.grey))),
                Expanded(flex: 3, child: Text(displayValue)),
              ],
            ),
          );
        }),
        const SizedBox(height: 16),
      ],
    );
  }

  // ---------- OWNER (display name only, phone kabhi text mein nahi) ----------
  Widget _buildOwnerSection() {
    final name =
        _property.ownerDisplayName.isNotEmpty ? _property.ownerDisplayName : "Property Owner";
    return Row(
      children: [
        const Icon(Icons.person_outline, size: 18, color: Colors.grey),
        const SizedBox(width: 6),
        Text("Listed by $name"),
      ],
    );
  }

  // ---------- CONTACT SECTION ----------
  Widget _buildContactSection() {
    if (_isOwnProperty || _isStaff) return const SizedBox.shrink();

    if (_isRentedOrSold) {
      final label = _property.status == 'rented' ? 'rented out' : 'sold';
      return Text(
        "This property has already been $label and is no longer available.",
        style: const TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Interested in this property?",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        if (_inquirySent)
          const Text(
            "Your message has been sent! The owner will contact you soon.",
            style: TextStyle(color: Colors.green),
          )
        else ...[
          TextField(
            controller: _messageController,
            maxLines: 3,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: "Hi, is this property still available?",
            ),
          ),
          if (_inquiryError != null)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(_inquiryError!, style: const TextStyle(color: Colors.red, fontSize: 13)),
            ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.call, size: 18),
                  label: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: const Text("Call Owner"),
                  ),
                  onPressed: _isCalling ? null : _onCallOwner,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.message, size: 18),
                  label: _isSending
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : FittedBox(
                          fit: BoxFit.scaleDown,
                          child: const Text("Send Inquiry"),
                        ),
                  onPressed: _isSending ? null : _onSendInquiry,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  // ---------- GALLERY ----------
  Widget _buildGallery(List<PropertyMedia> images) {
    if (images.isEmpty) {
      return Container(
        height: 220,
        color: Colors.grey[300],
        child: const Icon(Icons.home, size: 80, color: Colors.grey),
      );
    }
    return SizedBox(
      height: 220,
      child: Stack(
        children: [
          PageView.builder(
            itemCount: images.length,
            onPageChanged: (i) => setState(() => _currentImageIndex = i),
            itemBuilder: (context, index) {
              return GestureDetector(
                onTap: () => _openFullscreenGallery(images, index),
                child: Image.network(
                  images[index].file!,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  errorBuilder: (_, __, ___) => Container(
                    color: Colors.grey[300],
                    child: const Icon(Icons.broken_image, size: 60, color: Colors.grey),
                  ),
                ),
              );
            },
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

  void _openFullscreenGallery(List<PropertyMedia> images, int initialIndex) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _FullscreenGallery(images: images, initialIndex: initialIndex),
      ),
    );
  }

  // ---------- LOCATION / MAP ----------
  Widget _buildLocationSection(Property p) {
    final hasLocation = p.latitude != null && p.longitude != null;

    if (!hasLocation) {
      final query = Uri.encodeComponent("${p.locality}, ${p.city}");
      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            icon: const Icon(Icons.directions),
            label: const Text("Get Directions"),
            onPressed: () => _openDirectionsQuery(query),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Location", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            height: 200,
            child: FlutterMap(
              options: MapOptions(
                initialCenter: LatLng(p.latitude!, p.longitude!),
                initialZoom: 15,
                interactionOptions: const InteractionOptions(flags: InteractiveFlag.none),
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                  subdomains: const ['a', 'b', 'c'],
                  userAgentPackageName: 'com.niceplace.app',
                ),
                MarkerLayer(markers: [
                  Marker(
                    point: LatLng(p.latitude!, p.longitude!),
                    width: 40,
                    height: 40,
                    child: const Icon(Icons.location_pin, color: Colors.red, size: 40),
                  ),
                ]),
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
            onPressed: () => _openDirections(p.latitude!, p.longitude!),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final images = _property.media
        .where((m) => m.mediaType == 'image' && m.file != null && m.file!.isNotEmpty)
        .toList();

    return Scaffold(
      appBar: AppBar(title: Text(_property.title)),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildGallery(images),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _property.title,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  if (_buildStatusBadge(_property) != null) _buildStatusBadge(_property)!,
                  _buildPriceBlock(_property),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    children: [
                      Chip(label: Text(_property.propertyType)),
                      Chip(
                        label: Text(_property.listingType == 'rent' ? 'For Rent' : 'For Sale'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.location_on, size: 18, color: Colors.grey),
                      const SizedBox(width: 4),
                      Expanded(child: Text(_buildAddress(_property))),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildLocationSection(_property),
                  if (_property.description.trim().isNotEmpty) ...[
                    const Text("Description",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(_property.description, style: const TextStyle(fontSize: 15)),
                    const SizedBox(height: 16),
                  ],
                  _buildAttributes(_property),
                  _buildNearbyPlaces(_property),
                  if (_property.tags.isNotEmpty) ...[
                    const Text("Tags",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: _property.tags
                          .map((t) => TagChip(
                                name: t.name,
                                badgeIcon: t.badgeIcon,
                                badgeColor: t.badgeColor,
                              ))
                          .toList(),
                    ),
                    const SizedBox(height: 16),
                  ],
                  _buildOwnerSection(),
                  const SizedBox(height: 16),
                  _buildContactSection(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Simple built-in fullscreen viewer - photo_viewer_screen.dart se alag,
// taaki uski constructor signature na jaan-te hue koi galat integration na ho.
class _FullscreenGallery extends StatelessWidget {
  final List<PropertyMedia> images;
  final int initialIndex;

  const _FullscreenGallery({required this.images, required this.initialIndex});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: PageView.builder(
        controller: PageController(initialPage: initialIndex),
        itemCount: images.length,
        itemBuilder: (context, index) {
          return InteractiveViewer(
            child: Center(
              child: Image.network(images[index].file!, fit: BoxFit.contain),
            ),
          );
        },
      ),
    );
  }
}