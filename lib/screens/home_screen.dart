import 'property_detail_screen.dart';
import 'notifications_list_screen.dart';
import 'property_filter_sheet.dart';
import 'profile_screen.dart'; // TODO: fix this path/class name if yours differs
import 'package:flutter/material.dart';
import '../models/property_model.dart';
import '../services/property_service.dart';
import '../services/notification_service.dart';
import '../services/location_helper.dart';
import '../utils/auth_guard.dart';
import '../theme/app_theme.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<List<Property>> _propertiesFuture;
  int _unreadCount = 0;

  final TextEditingController _searchController = TextEditingController();

  String? _city;
  int? _propertyTypeId;
  String? _listingType;
  double? _minPrice;
  double? _maxPrice;

  // Current-location display state
  String? _locationCity;
  String? _locationLocality;
  bool _locationLoading = false;

  @override
  void initState() {
    super.initState();
    _loadProperties();
    _loadUnreadCount();
    _refreshLocation();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadProperties() {
    setState(() {
      _propertiesFuture = PropertyService.fetchProperties(
        city: _city,
        propertyTypeId: _propertyTypeId,
        listingType: _listingType,
        minPrice: _minPrice,
        maxPrice: _maxPrice,
        search: _searchController.text.trim(),
      );
    });
  }

  Future<void> _loadUnreadCount() async {
    // Returns 0 automatically if not logged in - safe to call always
    final count = await NotificationService.fetchUnreadCount();
    if (mounted) {
      setState(() => _unreadCount = count);
    }
  }

  Future<void> _refreshLocation() async {
    setState(() => _locationLoading = true);
    try {
      final result = await LocationHelper.getCurrentCityAndLocality();
      if (!mounted) return;
      setState(() {
        _locationCity = result.city;
        _locationLocality = result.locality;
        _locationLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _locationCity = 'Set location';
        _locationLocality = null;
        _locationLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e')),
      );
    }
  }

  Future<void> _openNotifications() async {
    final loggedIn = await AuthGuard.ensureLoggedIn(context);
    if (!loggedIn) return;
    if (mounted) {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const NotificationsListScreen()),
      );
      _loadUnreadCount();
    }
  }

  Future<void> _openFilterSheet() async {
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => PropertyFilterSheet(
        initialCity: _city,
        initialPropertyTypeId: _propertyTypeId,
        initialListingType: _listingType,
        initialMinPrice: _minPrice,
        initialMaxPrice: _maxPrice,
      ),
    );

    if (result != null) {
      setState(() {
        _city = (result['city'] as String?)?.isEmpty ?? true ? null : result['city'];
        _propertyTypeId = result['propertyTypeId'];
        _listingType = result['listingType'];
        _minPrice = result['minPrice'];
        _maxPrice = result['maxPrice'];
      });
      _loadProperties();
    }
  }

  bool get _hasActiveFilters =>
      _city != null ||
      _propertyTypeId != null ||
      _listingType != null ||
      _minPrice != null ||
      _maxPrice != null;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // The slide-in panel from the right. Flutter opens this automatically
      // whenever something calls Scaffold.of(context).openEndDrawer().
      endDrawer: Drawer(
        width: MediaQuery.of(context).size.width * 0.85,
        child: const ProfileScreen(),
      ),
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        titleSpacing: 12,
        title: Row(
          children: [
            // Logo in a white pill badge, matching the website header
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Image.asset(
                'assets/images/real_logo_appbar_240.png',
                height: 34,
              ),
            ),
            const SizedBox(width: 10),
            // Tappable current-location display
            Expanded(
              child: InkWell(
                onTap: _locationLoading ? null : _refreshLocation,
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              _locationLoading
                                  ? 'Detecting...'
                                  : (_locationCity ?? 'Set location'),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 2),
                          const Icon(Icons.keyboard_arrow_down,
                              color: Colors.white, size: 18),
                        ],
                      ),
                      if (!_locationLoading &&
                          _locationLocality != null &&
                          _locationLocality!.isNotEmpty)
                        Text(
                          _locationLocality!,
                          style: const TextStyle(color: Colors.white70, fontSize: 11),
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Badge(
              label: Text('$_unreadCount'),
              isLabelVisible: _unreadCount > 0,
              child: const Icon(Icons.notifications, color: Colors.white),
            ),
            tooltip: "Notifications",
            onPressed: _openNotifications,
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12, left: 2),
            child: Builder(
              builder: (innerContext) => GestureDetector(
                onTap: () => Scaffold.of(innerContext).openEndDrawer(),
                child: const CircleAvatar(
                  radius: 18,
                  backgroundColor: Colors.white,
                  child: Icon(Icons.person, color: AppColors.primary),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: "Search properties...",
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      isDense: true,
                    ),
                    onSubmitted: (_) => _loadProperties(),
                  ),
                ),
                const SizedBox(width: 8),
                Stack(
                  children: [
                    IconButton.filled(
                      icon: const Icon(Icons.filter_list),
                      onPressed: _openFilterSheet,
                    ),
                    if (_hasActiveFilters)
                      Positioned(
                        right: 4,
                        top: 4,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Property>>(
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
                  return const Center(
                    child: Text("No properties found. Try adjusting filters."),
                  );
                }
                return ListView.builder(
                  itemCount: properties.length,
                  itemBuilder: (context, index) {
                    final property = properties[index];
                    return Card(
                      margin: const EdgeInsets.all(8),
                      child: ListTile(
                        leading: property.media.isNotEmpty
                            ? Image.network(
                                property.media.first.file,
                                width: 60,
                                height: 60,
                                fit: BoxFit.cover,
                              )
                            : const Icon(Icons.home, size: 40),
                        title: Text(property.title),
                        subtitle: Text(
                            "${property.locality}, ${property.city}\n₹${property.price}"),
                        isThreeLine: true,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) =>
                                    PropertyDetailScreen(property: property)),
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
    );
  }
}