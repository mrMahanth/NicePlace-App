import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/property_model.dart';
import '../theme/app_theme.dart';
import '../utils/price_formatter.dart';
import 'property_action_icons.dart';

/// A vertical property card with the cover image, a bottom gradient overlay
/// showing price + locality, small badges in the top corners, and a strip
/// below the image showing up to 3 attributes marked `show_on_card` by the
/// admin (e.g. Bedrooms, Bathrooms, Area).
class PropertyCardModern extends StatelessWidget {
  final Property property;
  final VoidCallback onTap;
  final double? width;

  const PropertyCardModern({
    super.key,
    required this.property,
    required this.onTap,
    this.width,
  });

  // === add these two static helpers ===
  static double widthFor(BuildContext context) => MediaQuery.of(context).size.width / 1.5;

  static double heightFor(BuildContext context) {
    final w = widthFor(context);
    final imageHeight = w * 3 / 4; // AspectRatio(4/3) jo image ke liye use ho raha hai
    return imageHeight + 76; // + title row + attributes strip + thoda breathing room
  }
  // === end add ===

  String? get _coverImageUrl {
    if (property.media.isEmpty) return null;
    final cover = property.media.where((m) => m.mediaType == 'image' && m.isCover);
    if (cover.isNotEmpty) return cover.first.file;
    final firstImage = property.media.where((m) => m.mediaType == 'image');
    return firstImage.isNotEmpty ? firstImage.first.file : null;
  }

  String get _displayPrice => propertyPriceLabel(property);

  @override
  Widget build(BuildContext context) {
    final imageUrl = _coverImageUrl;
    final cardAttributes = property.attributeValues.where((a) => a.showOnCard).take(3).toList();
    final cardWidth = width ?? widthFor(context); // === add this line ===

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: cardWidth, // === changed: 'width' se 'cardWidth' kiya ===
        margin: const EdgeInsets.only(right: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.cardBorder),
          color: Colors.white,
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // ---------- IMAGE + GRADIENT + PRICE/TITLE ----------
            AspectRatio(
              aspectRatio: 4 / 3,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  imageUrl != null
                      ? CachedNetworkImage(
                          imageUrl: imageUrl,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(color: AppColors.cardBorder),
                          errorWidget: (context, url, error) => Container(
                            color: AppColors.cardBorder,
                            child: const Icon(Icons.broken_image),
                          ),
                        )
                      : Container(
                          color: AppColors.cardBorder,
                          child: const Icon(Icons.home, size: 40, color: AppColors.textMuted),
                        ),

                  // Bottom gradient — only the lower half darkens
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          stops: const [0.45, 1.0],
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.80),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Top-left badge: Rent/Sale
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        property.listingType == 'rent' ? 'For Rent' : 'For Sale',
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                      ),
                    ),
                  ),

                  // Action icons - right edge, vertically centered. Positioned.fill +
                  // Align (fixed top/bottom ki jagah) taaki icon column apni content
                  // ke hisaab se size ho, forced-height overflow na ho.
                  Positioned.fill(
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Padding(
                        padding: const EdgeInsets.only(right: 4),
                        child: PropertyActionIcons(
                          property: property,
                          direction: Axis.vertical,
                          onImage: true,
                        ),
                      ),
                    ),
                  ),

                  // Price + locality, sitting on the gradient
                  Positioned(
                    left: 10,
                    right: 10,
                    bottom: 8,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _displayPrice,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            shadows: [Shadow(blurRadius: 4, color: Colors.black54)],
                          ),
                        ),
                        Text(
                          '${property.locality}, ${property.city}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            shadows: [Shadow(blurRadius: 4, color: Colors.black54)],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ---------- TITLE (below image) ----------
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 4),
              child: Text(
                property.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
              ),
            ),

            // ---------- ATTRIBUTES STRIP (Bedrooms, Bathrooms, Area, etc.) ----------
            if (cardAttributes.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
                child: Row(
                  children: cardAttributes.map((attr) {
                    final display = attr.unitValue.isNotEmpty
                        ? '${attr.value} ${attr.unitValue}'
                        : attr.value;
                    return Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: Text(
                        display,
                        style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                      ),
                    );
                  }).toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}