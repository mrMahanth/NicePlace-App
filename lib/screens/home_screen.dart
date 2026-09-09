import 'property_detail_screen.dart';
import 'notifications_list_screen.dart';
import 'profile_screen.dart'; // TODO: fix this path/class name if yours differs
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/property_model.dart';
import '../services/property_service.dart';
import '../services/notification_service.dart';
import '../services/api_service.dart';
import '../services/location_helper.dart';
import '../services/recent_searches_helper.dart';
import '../utils/auth_guard.dart';
import '../theme/app_theme.dart';
import '../widgets/animated_hint_search_field.dart';
import '../widgets/location_picker_sheet.dart';
import 'all_localities_screen.dart';
import 'search_filter_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<List<Property>> _propertiesFuture;
  int _unreadCount = 0;
  bool _isLoggedIn = false;

  final TextEditingController _searchController = TextEditingController();

  static const List<String> _searchHints = [
      '"2BHK Flats in SK Puri"',
      '"Banquet Halls Nearby"',
      '"Shop in Bhootnath"',
      '"Space for Office/Bank"',
      '"Plots in Bihta"',
      '"Hostels Near College"',
    ];

  String? _city;
  int? _propertyTypeId;
  String? _listingType;
  double? _minPrice;
  double? _maxPrice;

  // Current-location display state
  String? _locationCity;
  String? _locationLocality;
  bool _locationLoading = false;
  bool _locationDetected = false; // true only on real GPS success, not the placeholder

  @override
  void initState() {
    super.initState();
    _loadProperties();
    _loadUnreadCount();
    _refreshLocation();
    _checkLoginStatus();
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

  Future<void> _checkLoginStatus() async {
    final token = await ApiService.getAccessToken();
    if (mounted) {
      setState(() => _isLoggedIn = token != null);
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
        _locationDetected = true;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _locationCity = 'Set location';
        _locationLocality = null;
        _locationLoading = false;
        _locationDetected = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e')),
      );
    }
  }

  Future<void> _openLocationPicker() async {
    final picked = await showLocationPickerSheet(
      context,
      currentCity: _locationDetected ? _locationCity : null,
      onUseCurrentLocation: _refreshLocation,
    );

    if (picked == seeAllSentinel) {
      if (!mounted) return;
      final fromAll = await Navigator.push<String>(
        context,
        MaterialPageRoute(
          builder: (context) => AllLocalitiesScreen(
            currentCity: _locationDetected ? _locationCity : null,
          ),
        ),
      );
      if (fromAll != null) _applyPickedLocality(fromAll);
      return;
    }

    if (picked != null) _applyPickedLocality(picked);
  }

  void _applyPickedLocality(String locality) {
    setState(() {
      _searchController.text = locality;
      _city = null;
    });
    RecentSearchesHelper.addRecent(locality);
    _loadProperties();
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

  // Guest -> send straight to Login (via the same AuthGuard used elsewhere
  // in this file, so behavior/UX stays consistent app-wide).
  // Logged-in -> open the profile side panel as before.
  Future<void> _handleAvatarTap(BuildContext innerContext) async {
    if (_isLoggedIn) {
      Scaffold.of(innerContext).openEndDrawer();
      return;
    }
    final loggedIn = await AuthGuard.ensureLoggedIn(context);
    if (loggedIn && mounted) {
      _checkLoginStatus();
      _loadUnreadCount();
    }
  }

  // Called by ProfileScreen (shown in the endDrawer) after a logout, so the
  // "Login" pill reappears on the avatar without needing to reopen the app.
  void _handleLoggedOutFromDrawer() {
    _checkLoginStatus();
    setState(() => _unreadCount = 0);
  }

  Future<void> _openSearchFilterScreen() async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (context) => SearchFilterScreen(
          initialSearch: _searchController.text,
          initialCity: _city,
          initialPropertyTypeId: _propertyTypeId,
          initialListingType: _listingType,
          initialMinPrice: _minPrice,
          initialMaxPrice: _maxPrice,
        ),
      ),
    );
    if (result != null) {
      setState(() {
        _searchController.text = (result['search'] as String?) ?? '';
        _city = null; // search text now carries the locality/keyword instead
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
      // The slide-in panel from the right.
      endDrawer: Drawer(
        width: MediaQuery.of(context).size.width * 0.85,
        child: ProfileScreen(onLoggedOut: _handleLoggedOutFromDrawer),
      ),
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        titleSpacing: 12,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Image.asset(
                'assets/images/home-screen-logo-240.png',
                height: 34,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: InkWell(
                onTap: _openLocationPicker,
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
                onTap: () => _handleAvatarTap(innerContext),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircleAvatar(
                      radius: 18,
                      backgroundColor: Colors.white,
                      child: Icon(Icons.person, color: AppColors.primary),
                    ),
                    if (!_isLoggedIn)
                      Container(
                        margin: const EdgeInsets.only(top: 3),
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: Colors.amber,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          "Login",
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                            height: 1,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        cacheExtent: 500, // pre-renders items just outside the screen for smoother scroll
        slivers: [
          // The search strip. floating: true + snap: true gives the
          // "hide while scrolling down through the list, reappear instantly
          // when scrolling back up" behavior, independent of the AppBar
          // above (which stays pinned since it's the Scaffold's own appBar).
          SliverAppBar(
            backgroundColor: AppColors.searchStripBackground,
            pinned: false,
            floating: true,
            snap: true,
            elevation: 0,
            toolbarHeight: 70,
            automaticallyImplyLeading: false,
            actions: const [SizedBox.shrink()], // non-empty but invisible - reliably blocks the automatic endDrawer icon
            titleSpacing: 12,
            title: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              // Wrapped in AbsorbPointer so tapping never opens a keyboard
              // here - it always navigates to the dedicated Filters screen,
              // which avoids the keyboard/filter overlap problem entirely.
              child: GestureDetector(
                onTap: _openSearchFilterScreen,
                child: AbsorbPointer(
                  child: AnimatedHintSearchField(
                    controller: _searchController,
                    hints: _searchHints,
                    hasActiveFilters: _hasActiveFilters,
                  ),
                ),
              ),
            ),
          ),
          FutureBuilder<List<Property>>(
            future: _propertiesFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              if (snapshot.hasError) {
                return SliverFillRemaining(
                  child: Center(child: Text("Error: ${snapshot.error}")),
                );
              }
              final properties = snapshot.data ?? [];
              if (properties.isEmpty) {
                return const SliverFillRemaining(
                  child: Center(
                    child: Text("No properties found. Try adjusting filters."),
                  ),
                );
              }
              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final property = properties[index];
                    return Card(
                      margin: const EdgeInsets.all(8),
                      child: ListTile(
                        leading: property.media.any((m) => m.mediaType == 'image')
                            ? CachedNetworkImage(
                                imageUrl: property.media.firstWhere((m) => m.mediaType == 'image').file!,
                                width: 60,
                                height: 60,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => Container(
                                  width: 60,
                                  height: 60,
                                  color: AppColors.cardBorder,
                                ),
                                errorWidget: (context, url, error) =>
                                    const Icon(Icons.broken_image, size: 40),
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
                  childCount: properties.length,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}