import 'package:flutter/material.dart';
import '../services/locality_service.dart';
import '../services/recent_searches_helper.dart';
import '../services/waitlist_service.dart';
import '../theme/app_theme.dart';
import '../utils/auth_guard.dart';

/// Returned from the sheet instead of a locality name when the user taps
/// "See all" - the caller (Home screen) checks for this and pushes the
/// All Localities screen instead of treating it as a picked locality.
const String seeAllSentinel = '__see_all_localities__';

/// Opens the location bottom sheet. Returns the picked locality/city name
/// via the Future if the user selects one from the lists, [seeAllSentinel]
/// if they tapped "See all", or null if they used "Use Current Location"
/// (handled separately via [onUseCurrentLocation]) or dismissed the sheet.
Future<String?> showLocationPickerSheet(
  BuildContext context, {
  String? currentCity,
  required VoidCallback onUseCurrentLocation,
}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (context) => _LocationPickerSheet(
      currentCity: currentCity,
      onUseCurrentLocation: onUseCurrentLocation,
    ),
  );
}

class _LocationPickerSheet extends StatefulWidget {
  final String? currentCity;
  final VoidCallback onUseCurrentLocation;

  const _LocationPickerSheet({
    this.currentCity,
    required this.onUseCurrentLocation,
  });

  @override
  State<_LocationPickerSheet> createState() => _LocationPickerSheetState();
}

class _LocationPickerSheetState extends State<_LocationPickerSheet> {
  List<String> _activeLocalities = [];
  List<String> _recentSearches = [];
  bool _loadingLocalities = true;

  @override
  void initState() {
    super.initState();
    _loadLocalities();
    _loadRecentSearches();
  }

  Future<void> _loadLocalities() async {
    try {
      final localities = await LocalityService.fetchLocalitiesWithProperties(
        city: widget.currentCity ?? 'Patna',
      );
      if (!mounted) return;
      setState(() {
        _activeLocalities = localities;
        _loadingLocalities = false;
      });
    } catch (e) {
      if (mounted) setState(() => _loadingLocalities = false);
    }
  }

  Future<void> _loadRecentSearches() async {
    final recent = await RecentSearchesHelper.getRecent();
    if (mounted) setState(() => _recentSearches = recent);
  }

  Future<void> _showComingSoonDialog(String cityName) async {
    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Coming Soon!'),
        content: Text(
          'We are currently onboarding local property dealers in $cityName. '
          'Want to know when we go live?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              // Waitlist requires login, per the backend's IsAuthenticated rule.
              final loggedIn = await AuthGuard.ensureLoggedIn(context);
              if (!loggedIn) return;

              final success = await WaitlistService.joinWaitlist(cityName);
              if (!dialogContext.mounted) return;
              Navigator.pop(dialogContext);

              if (success && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("Awesome! We'll notify you when we launch in $cityName."),
                  ),
                );
              } else if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Something went wrong. Please try again.')),
                );
              }
            },
            child: const Text('🔔 Notify Me'),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
        child: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textMuted, fontSize: 13),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.cardBorder,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              // Use Current Location
              ListTile(
                leading: const Icon(Icons.my_location, color: AppColors.accent),
                title: const Text('Use Current Location', style: TextStyle(fontWeight: FontWeight.w600)),
                onTap: () {
                  widget.onUseCurrentLocation();
                  Navigator.pop(context);
                },
              ),
              const Divider(height: 1),

              // Locations with active properties - horizontal scrollable
              // tiles instead of a vertical list, so this section can't push
              // the rest of the sheet further and further down as the
              // locality count grows.
              _sectionHeader('LOCATIONS WITH ACTIVE PROPERTIES'),
              if (_loadingLocalities)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_activeLocalities.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text('No active localities yet.', style: TextStyle(color: AppColors.textMuted)),
                )
              else
                SizedBox(
                  height: 44,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      ..._activeLocalities.take(6).map(
                        (locality) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ActionChip(
                            avatar: const Icon(Icons.location_on_outlined, size: 16),
                            label: Text(locality),
                            backgroundColor: Colors.white,
                            side: const BorderSide(color: AppColors.cardBorder),
                            onPressed: () => Navigator.pop(context, locality),
                          ),
                        ),
                      ),
                      ActionChip(
                        avatar: const Icon(Icons.arrow_forward, size: 16, color: AppColors.accent),
                        label: const Text(
                          'See all',
                          style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.w600),
                        ),
                        backgroundColor: AppColors.accent.withValues(alpha: 0.08),
                        side: const BorderSide(color: AppColors.accent),
                        onPressed: () => Navigator.pop(context, seeAllSentinel),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 8),

              // Recent searches
              if (_recentSearches.isNotEmpty) ...[
                const Divider(height: 1),
                _sectionHeader('RECENT SEARCHES'),
                ..._recentSearches.map(
                  (recent) => ListTile(
                    leading: const Icon(Icons.history, color: AppColors.textMuted),
                    title: Text(recent),
                    onTap: () => Navigator.pop(context, recent),
                  ),
                ),
              ],

              const Divider(height: 1),
              // Expanding soon
              _sectionHeader('EXPANDING SOON'),
              const ListTile(
                leading: Icon(Icons.check_circle, color: AppColors.success),
                title: Text('Patna'),
                trailing: Text('Active', style: TextStyle(color: AppColors.success, fontWeight: FontWeight.w600)),
              ),
              ListTile(
                leading: const Icon(Icons.lock_outline, color: AppColors.textMuted),
                title: const Text('Ranchi'),
                trailing: const Text('Coming Soon', style: TextStyle(color: AppColors.textMuted)),
                onTap: () => _showComingSoonDialog('Ranchi'),
              ),
              ListTile(
                leading: const Icon(Icons.lock_outline, color: AppColors.textMuted),
                title: const Text('Muzaffarpur'),
                trailing: const Text('Coming Soon', style: TextStyle(color: AppColors.textMuted)),
                onTap: () => _showComingSoonDialog('Muzaffarpur'),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}