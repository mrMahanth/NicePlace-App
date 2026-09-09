import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../screens/favourites_screen.dart';
import '../screens/saved_properties_screen.dart';
import '../screens/interested_properties_screen.dart';

class _QuickLink {
  final IconData icon;
  final String label;
  final WidgetBuilder screenBuilder;
  const _QuickLink({required this.icon, required this.label, required this.screenBuilder});
}

// To add another shortcut later, just add another entry here - the grid
// below lays these out automatically, no other code needs to change.
final List<_QuickLink> _quickLinks = [
  _QuickLink(
    icon: Icons.favorite_border,
    label: 'Favourites',
    screenBuilder: (_) => const FavouritesScreen(),
  ),
  _QuickLink(
    icon: Icons.bookmark_border,
    label: 'Saved',
    screenBuilder: (_) => const SavedPropertiesScreen(),
  ),
  _QuickLink(
    icon: Icons.thumb_up_outlined,
    label: 'Interested',
    screenBuilder: (_) => const InterestedPropertiesScreen(),
  ),
];

Future<void> showQuickLinksSheet(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (context) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppColors.cardBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const Text('Quick Links', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 16),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 3,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.9,
              children: _quickLinks.map((link) {
                return InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: link.screenBuilder));
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(link.icon, color: AppColors.accent, size: 26),
                        const SizedBox(height: 8),
                        Text(link.label, style: const TextStyle(fontSize: 12, color: AppColors.textPrimary)),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    ),
  );
}