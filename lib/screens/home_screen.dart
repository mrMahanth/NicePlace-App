import 'property_detail_screen.dart';
import 'notifications_list_screen.dart';
import 'profile_screen.dart'; // TODO: fix this path/class name if yours differs
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/property_model.dart';
import '../services/property_service.dart';
import '../services/notification_service.dart';
import '../services/location_helper.dart';
import '../utils/auth_guard.dart';
import '../theme/app_theme.dart';
import '../widgets/animated_hint_search_field.dart';
import '../widgets/inline_filter_panel.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<List<Property>> _propertiesFuture;
  int _unreadCount = 0;

  final TextEditingController _searchController = TextEditingController();

  static const List<String> _searchHints = [
    'Find Flats...',
    'Find Plots...',
    'Find Space for Office...',
    'Find ATM and Banks...',
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

  bool _showFilterPanel = false;

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

  void _applyInlineFilters(Map<String, dynamic> result) {
    setState(() {
      _city = (result['city'] as String?)?.isEmpty ?? true ? null : result['city'];
      _propertyTypeId = result['propertyTypeId'];
      _listingType = result['listingType'];
      _minPrice = result['minPrice'];
      _maxPrice = result['maxPrice'];
      _showFilterPanel = false;
    });
    _loadProperties();
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
        child: const ProfileScreen(),
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
              child: AnimatedHintSearchField(
                controller: _searchController,
                hints: _searchHints,
                onSubmitted: (_) => _loadProperties(),
                onFilterTap: () => setState(() => _showFilterPanel = !_showFilterPanel),
                hasActiveFilters: _hasActiveFilters,
                onFocusChanged: (focused) {
                  if (focused) setState(() => _showFilterPanel = true);
                },
              ),
            ),
          ),
          // The attached filter panel - appears/disappears with a smooth
          // height animation, pushing the property list down while open.
          SliverToBoxAdapter(
            child: AnimatedSize(
              duration: const Duration(milliseconds: 250),
              child: _showFilterPanel
                  ? InlineFilterPanel(
                      initialCity: _city,
                      initialPropertyTypeId: _propertyTypeId,
                      initialListingType: _listingType,
                      initialMinPrice: _minPrice,
                      initialMaxPrice: _maxPrice,
                      onApply: _applyInlineFilters,
                      onClose: () => setState(() => _showFilterPanel = false),
                    )
                  : const SizedBox.shrink(),
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
                        leading: property.media.isNotEmpty
                            ? CachedNetworkImage(
                                imageUrl: property.media.first.file,
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