import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/property_model.dart';
import '../theme/app_theme.dart';
import '../utils/price_formatter.dart';
import 'tag_badge.dart';

/// Poori app ka universal LIST card.
/// - Public lists (Home, See All, Search results): sirf property, onTap.
/// - Owner view (My Properties): showStatus: true + footer mein action buttons.
class PropertyCardList extends StatelessWidget {
  final Property property;
  final VoidCallback onTap;
  final bool showStatus;
  final Widget? footer;

  const PropertyCardList({
    super.key,
    required this.property,
    required this.onTap,
    this.showStatus = false,
    this.footer,
  });

  String? get _coverUrl {
    final images = property.media.where((m) => m.mediaType == 'image' && m.file != null && m.file!.isNotEmpty);
    if (images.isEmpty) return null;
    final cover = images.where((m) => m.isCover);
    return (cover.isNotEmpty ? cover.first : images.first).file;
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'live':
        return Colors.green;
      case 'under_review':
        return Colors.orange;
      case 'sold':
      case 'rented':
        return Colors.blue;
      case 'expired':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _statusLabel(String s) {
    if (s == 'under_review') return 'Under Review';
    return s.isEmpty ? '' : s[0].toUpperCase() + s.substring(1);
  }

  Widget _badge(String text, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(text,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
      );

  @override
  Widget build(BuildContext context) {
    final imageUrl = _coverUrl;
    final secondary = propertySecondaryPriceLabel(property);
    final location = [property.locality, property.city]
        .where((s) => s.trim().isNotEmpty)
        .join(', ');

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: imageUrl != null
                        ? CachedNetworkImage(
                            imageUrl: imageUrl,
                            width: 90,
                            height: 90,
                            fit: BoxFit.cover,
                            placeholder: (_, __) =>
                                Container(width: 90, height: 90, color: AppColors.cardBorder),
                            errorWidget: (_, __, ___) => Container(
                                width: 90,
                                height: 90,
                                color: AppColors.cardBorder,
                                child: const Icon(Icons.broken_image)),
                          )
                        : Container(
                            width: 90,
                            height: 90,
                            color: AppColors.cardBorder,
                            child: const Icon(Icons.home_outlined, color: AppColors.textMuted),
                          ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          property.title.isEmpty ? '(Untitled)' : property.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          propertyPriceLabel(property),
                          style: const TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.primary),
                        ),
                        if (secondary != null)
                          Text(secondary,
                              style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                        if (location.isNotEmpty) ...[
                          const SizedBox(height: 3),
                          Text(location,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                        ],
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: [
                            _badge(property.listingType == 'rent' ? 'For Rent' : 'For Sale',
                                AppColors.textPrimary),
                            if (showStatus)
                              _badge(_statusLabel(property.status), _statusColor(property.status)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (property.tags.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
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
              ],
              if (footer != null) ...[
                const SizedBox(height: 4),
                footer!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}