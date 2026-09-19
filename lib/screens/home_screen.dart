import 'property_detail_screen.dart';
import 'notifications_list_screen.dart';
import 'profile_screen.dart'; // TODO: fix this path/class name if yours differs
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/property_model.dart';
import '../services/property_service.dart';
import '../services/notification_service.dart';
import '../services/location_helper.dart';
import '../services/recent_searches_helper.dart';
import '../utils/auth_guard.dart';
import '../theme/app_theme.dart';
import '../widgets/animated_hint_search_field.dart';
import '../widgets/hero_slider_banner.dart';
import '../widgets/location_picker_sheet.dart';
import 'all_localities_screen.dart';
import 'search_filter_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/slider_model.dart';
import '../services/slider_service.dart';
import '../utils/internal_page_registry.dart';
import '../widgets/tag_badge.dart';
import '../models/user_profile_model.dart';
import '../services/api_service.dart';
import '../services/user_profile_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<List<Property>> _propertiesFuture;
  int _unreadCount = 0;
  bool _avatarLoggedIn = false;
  String? _avatarPhoto;
  DisplayedTag? _avatarTag;

  final TextEditingController _searchController = TextEditingController();

  static const List<String> _searchHints = [
    '"2BHK Flats in SK Puri"',
    '"Banquet Halls Nearby"',
    '"Space for Office/Bank"',
    '"Plots in Punpun"',
    '"Hostels Near College"',
  ];

  late Future<List<SliderModel>> _slidersFuture;

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
    _slidersFuture = SliderService.fetchActiveSliders();
    _loadAvatarInfo();
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

  Future<void> _loadAvatarInfo() async {
    final token = await ApiService.getAccessToken();
    String? photo;
    DisplayedTag? displayedTag;
    if (token != null) {
      final result = await UserProfileService.fetchMyProfile();
      if (result['success'] == true) {
        final profile = result['data'] as UserProfileModel;
        photo = profile.profilePhoto;
        displayedTag = profile.displayedTag;
      }
    }
    if (mounted) {
      setState(() {
        _avatarLoggedIn = token != null;
        _avatarPhoto = photo;
        _avatarTag = displayedTag;
      });
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

  Future<void> _handleSliderTap(SliderModel slider) async {
    switch (slider.destinationType) {
      case 'property':
        if (slider.destinationPropertyId == null) return;
        try {
          final property = await SliderService.fetchPropertyById(slider.destinationPropertyId!);
          if (!mounted) return;
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => PropertyDetailScreen(property: property)),
          );
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Could not load this property.')),
            );
          }
        }
        break;

      case 'property_type':
        setState(() {
          _propertyTypeId = slider.destinationPropertyTypeId;
        });
        _loadProperties();
        break;

      case 'prefilled_search':
        setState(() {
          _searchController.text = slider.searchLocality ?? '';
          _propertyTypeId = slider.searchPropertyTypeId;
          _listingType = (slider.searchListingType?.isNotEmpty ?? false) ? slider.searchListingType : null;
          _city = null;
        });
        _loadProperties();
        break;

      case 'external_url':
        if (slider.externalUrl == null || slider.externalUrl!.isEmpty) return;
        final uri = Uri.tryParse(slider.externalUrl!);
        if (uri != null && await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
        break;

      case 'internal_page':
        final key = slider.internalPageAppScreenKey;
        final builder = (key != null && key.isNotEmpty) ? internalPageRegistry[key] : null;
        if (builder != null) {
          Navigator.push(context, MaterialPageRoute(builder: builder));
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("This page isn't available in the app yet.")),
          );
        }
        break;

      case 'project':
      case 'agent_profile':
      case 'category':
        // TODO: these still need screens/wiring that don't exist in the app
        // yet (Project detail screen, an agent profile screen, and
        // category-based browsing support in PropertyService). Graceful
        // no-op for now instead of crashing.
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("This link isn't supported in the app yet.")),
          );
        }
        break;

      case 'none':
      default:
        break; // decorative slide, no destination
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
        child: ProfileScreen(
          onProfileUpdated: _loadAvatarInfo,
          onLoggedOut: _loadAvatarInfo,
        ),
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
              builder: (innerContext) => Stack(
                clipBehavior: Clip.none,
                children: [
                  GestureDetector(
                    onTap: () => Scaffold.of(innerContext).openEndDrawer(),
                    child: CircleAvatar(
                      radius: 18,
                      backgroundColor: Colors.white,
                      backgroundImage: _avatarPhoto != null
                          ? CachedNetworkImageProvider(_avatarPhoto!)
                          : null,
                      child: _avatarPhoto == null
                          ? const Icon(Icons.person, color: AppColors.primary)
                          : null,
                    ),
                  ),
                  if (_avatarLoggedIn && _avatarTag != null)
                    Positioned(
                      bottom: -1,
                      right: -1,
                      child: TagBadgeIcon(
                        badgeIcon: _avatarTag!.badgeIcon,
                        badgeColor: _avatarTag!.badgeColor,
                        size: 14,
                      ),
                    ),
                  if (!_avatarLoggedIn)
                    Positioned(
                      bottom: -2,
                      left: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: () async {
                          final loggedIn = await AuthGuard.ensureLoggedIn(context);
                          if (loggedIn) _loadAvatarInfo();
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 0, horizontal: 0),
                          decoration: BoxDecoration(
                            color: AppColors.accent,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.white, width: 1),
                          ),
                          child: const Text(
                            'Login',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                    ),
                ],
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
          // === Replace both SliverToBoxAdapter blocks with this ===
          SliverAppBar(
            backgroundColor: AppColors.searchStripBackground,
            pinned: false,
            floating: true,
            snap: true,
            elevation: 0,
            toolbarHeight: 64, // search strip's own height, NOT the slider's
            automaticallyImplyLeading: false,
            actions: const [SizedBox.shrink()],
            flexibleSpace: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: GestureDetector(
                  onTap: _openSearchFilterScreen,
                  child: AbsorbPointer(
                    child: AnimatedHintSearchField(
                      controller: _searchController,
                      hints: _searchHints,
                      hasActiveFilters: _hasActiveFilters,
                      backgroundColor: AppColors.background,
                      borderColor: null,
                    ),
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: FutureBuilder<List<SliderModel>>(
              future: _slidersFuture,
              builder: (context, snapshot) {
                final sliders = snapshot.data ?? [];
                return HeroSliderBanner(
                  sliders: sliders,
                  onSliderTap: _handleSliderTap,
                );
              },
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
                      margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
                      child: InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) =>
                                    PropertyDetailScreen(property: property)),
                          );
                        },
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ListTile(
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
                            ),
                            if (property.tags.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(left: 16, right: 16, bottom: 12),
                                child: Wrap(
                                  spacing: 6,
                                  runSpacing: 6,
                                  children: property.tags
                                      .map((t) => TagChip(
                                            name: t.name,
                                            badgeIcon: t.badgeIcon,
                                            badgeColor: t.badgeColor,
                                          ))
                                      .toList(),
                                ),
                              ),
                          ],
                        ),
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