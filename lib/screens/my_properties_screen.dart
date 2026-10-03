import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/property_model.dart';
import '../services/property_service.dart';
import '../services/tenancy_service.dart';
import '../utils/number_utils.dart';
import 'post_property_basic_details_screen.dart';
import 'post_project_bulk_units_screen.dart';
import 'rent_tracking_screen.dart';

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

  // ---------- DELETE (har status ke liye available) ----------
  Future<void> _confirmDelete(Property property) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text("Remove Listing"),
        content: Text(
          "Remove \"${property.title.isEmpty ? 'this listing' : property.title}\"? This cannot be undone.",
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text("Cancel")),
          TextButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text("Remove")),
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
        const SnackBar(content: Text("Could not remove. Please try again.")),
      );
    }
  }

  // ---------- EDIT (sahi route par) ----------
  void _onEdit(Property property) {
    if (property.projectId != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PostProjectBulkUnitsScreen(projectId: property.projectId!),
        ),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PostPropertyBasicDetailsScreen(propertyId: property.id),
        ),
      );
    }
  }

  // ---------- RESUBMIT ----------
  Future<void> _onResubmit(Property property) async {
    final result = await PropertyService.resubmit(property.id);
    if (!mounted) return;
    if (result["success"] == true) {
      _loadProperties();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Could not resubmit. Please try again.")),
      );
    }
  }

  // ---------- MARK SOLD ----------
  Future<void> _onMarkSold(Property property) async {
    final result = await PropertyService.markSold(property.id);
    if (!mounted) return;
    if (result["success"] == true) {
      _loadProperties();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Could not update status. Please try again.")),
      );
    }
  }

  // ---------- MARK RENTED (OTP flow) ----------
  Future<void> _openMarkRentedSheet(Property property) async {
    final completed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) => _MarkRentedSheet(property: property),
    );
    if (completed == true) _loadProperties();
  }

  // ---------- TRACK RENT ----------
  void _openRentTracking(Property property) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RentTrackingScreen(
          propertyId: property.id,
          propertyTitle: property.title,
          defaultRentAmount: property.rentAmount ?? double.tryParse(property.price),
        ),
      ),
    ).then((_) => _loadProperties()); // End Tenancy ke baad status wapas 'live' ho sakta hai
  }

  Widget _propertyCard(Property property) {
    final coverUrl = _coverPhotoUrl(property);
    final showRejection = property.status == 'draft' && property.rejectionReason.isNotEmpty;

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
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: [
                      if (property.status == 'live' && property.listingType != 'sale')
                        TextButton(
                          onPressed: () => _openMarkRentedSheet(property),
                          child: const Text("Mark Rented"),
                        ),
                      if (property.status == 'live' && property.listingType != 'rent')
                        TextButton(
                          onPressed: () => _onMarkSold(property),
                          child: const Text("Mark Sold"),
                        ),
                      if (property.status == 'rented')
                        TextButton(
                          onPressed: () => _openRentTracking(property),
                          child: const Text("Track Rent"),
                        ),
                      TextButton(onPressed: () => _onEdit(property), child: const Text("Edit")),
                      if (showRejection)
                        TextButton(
                          onPressed: () => _onResubmit(property),
                          child: const Text("Resubmit"),
                        ),
                      TextButton(
                        onPressed: () => _confirmDelete(property),
                        style: TextButton.styleFrom(foregroundColor: Colors.red),
                        child: const Text("Remove"),
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
              : RefreshIndicator(
                  onRefresh: _loadProperties,
                  child: Column(
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
                            ? ListView(
                                children: const [
                                  SizedBox(height: 100),
                                  Center(
                                    child: Text("No properties found.", style: TextStyle(color: Colors.black54)),
                                  ),
                                ],
                              )
                            : ListView(
                                padding: const EdgeInsets.all(12),
                                children: _filteredProperties.map(_propertyCard).toList(),
                              ),
                      ),
                    ],
                  ),
                ),
    );
  }
}

// ---------------- Mark Rented bottom sheet (3-step, web jaisa) ----------------

class _MarkRentedSheet extends StatefulWidget {
  final Property property;
  const _MarkRentedSheet({required this.property});

  @override
  State<_MarkRentedSheet> createState() => _MarkRentedSheetState();
}

enum _RentStep { phone, otp, notRegistered }

class _MarkRentedSheetState extends State<_MarkRentedSheet> {
  _RentStep _step = _RentStep.phone;
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  final _renterNameController = TextEditingController();
  String? _registeredUsername;
  String? _error;
  bool _isBusy = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    _renterNameController.dispose();
    super.dispose();
  }

  Future<void> _handleCheckPhone() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) {
      setState(() => _error = "Enter a phone number.");
      return;
    }
    setState(() {
      _isBusy = true;
      _error = null;
    });

    final result = await TenancyService.checkPhone(phone);
    if (!mounted) return;

    if (result["success"] != true) {
      setState(() {
        _isBusy = false;
        _error = "Something went wrong. Please try again.";
      });
      return;
    }

    final data = result["data"] as Map<String, dynamic>;
    if (data["registered"] == true) {
      _registeredUsername = data["username"];
      await TenancyService.sendOtp(phone);
      if (!mounted) return;
      setState(() {
        _isBusy = false;
        _step = _RentStep.otp;
      });
    } else {
      setState(() {
        _isBusy = false;
        _step = _RentStep.notRegistered;
      });
    }
  }

  Future<void> _handleVerifyOtp() async {
    setState(() {
      _isBusy = true;
      _error = null;
    });

    final result = await TenancyService.verifyAndCreate(
      phone: _phoneController.text.trim(),
      otp: _otpController.text.trim(),
      propertyId: widget.property.id,
    );
    if (!mounted) return;

    if (result["success"] == true) {
      await _markPropertyRented();
    } else {
      setState(() {
        _isBusy = false;
        _error = result["error"]?.toString() ?? "Invalid or expired code. Please try again.";
      });
    }
  }

  Future<void> _handleUnverifiedSave() async {
    setState(() {
      _isBusy = true;
      _error = null;
    });

    final result = await TenancyService.createUnverified(
      propertyId: widget.property.id,
      renterName: _renterNameController.text.trim(),
      renterPhone: _phoneController.text.trim(),
    );
    if (!mounted) return;

    if (result["success"] == true) {
      await _markPropertyRented();
    } else {
      setState(() {
        _isBusy = false;
        _error = result["error"]?.toString() ?? "Could not save. Please try again.";
      });
    }
  }

  Future<void> _markPropertyRented() async {
    final result = await PropertyService.markRented(widget.property.id);
    if (!mounted) return;
    if (result["success"] == true) {
      Navigator.pop(context, true);
    } else {
      setState(() {
        _isBusy = false;
        _error = "Could not update status. Please try again.";
      });
    }
  }

  Future<void> _openWhatsappInvite() async {
    final phone = _phoneController.text.trim();
    final text = Uri.encodeComponent(
      "The owner has added you as a renter on NicePlace. Please download the app to view your rental details.",
    );
    final url = Uri.parse("https://wa.me/91$phone?text=$text");
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Could not open WhatsApp.")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(_error!, style: const TextStyle(color: Colors.red)),
            ),
          if (_step == _RentStep.phone) ...[
            const Text("Find Renter", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            const Text("Enter the renter's phone number to check if they're on NicePlace.",
                style: TextStyle(color: Colors.grey, fontSize: 13)),
            const SizedBox(height: 12),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: "Renter's phone number",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isBusy ? null : () => Navigator.pop(context),
                    child: const Text("Cancel"),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isBusy ? null : _handleCheckPhone,
                    child: _isBusy
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text("Check"),
                  ),
                ),
              ],
            ),
          ],
          if (_step == _RentStep.otp) ...[
            Text("Verify ${_registeredUsername ?? ''}",
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            const Text(
              "A verification code has been sent to their NicePlace notifications. Ask them for the code.",
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _otpController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "Enter code", border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isBusy ? null : () => Navigator.pop(context),
                    child: const Text("Cancel"),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isBusy ? null : _handleVerifyOtp,
                    child: _isBusy
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text("Verify & Confirm"),
                  ),
                ),
              ],
            ),
          ],
          if (_step == _RentStep.notRegistered) ...[
            const Text("Not on NicePlace Yet", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            const Text(
              "This number isn't registered. You can invite them, or save their details without verification.",
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _renterNameController,
              decoration: const InputDecoration(labelText: "Renter's Name", border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              icon: const Icon(Icons.chat),
              label: const Text("Send WhatsApp Invite"),
              onPressed: _openWhatsappInvite,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isBusy ? null : () => Navigator.pop(context),
                    child: const Text("Cancel"),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isBusy ? null : _handleUnverifiedSave,
                    child: _isBusy
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text("Save Without Verification"),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}