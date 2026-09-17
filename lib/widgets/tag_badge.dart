import 'package:flutter/material.dart';

IconData badgeIconData(String badgeIcon) {
  switch (badgeIcon) {
    case 'verified':
      return Icons.check;
    case 'star':
      return Icons.star;
    case 'crown':
      return Icons.emoji_events;
    case 'medal':
      return Icons.military_tech;
    case 'shield':
      return Icons.shield;
    default:
      return Icons.circle;
  }
}

Color badgeColorFromHex(String? hex) {
  if (hex == null || hex.isEmpty) return const Color(0xFF2ECC71);
  var value = hex.replaceAll('#', '');
  if (value.length == 6) value = 'FF$value';
  try {
    return Color(int.parse(value, radix: 16));
  } catch (e) {
    return const Color(0xFF2ECC71);
  }
}

/// Small filled circle badge - used as a corner overlay on avatars.
class TagBadgeIcon extends StatelessWidget {
  final String badgeIcon;
  final String? badgeColor;
  final double size;

  const TagBadgeIcon({super.key, required this.badgeIcon, this.badgeColor, this.size = 20});

  @override
  Widget build(BuildContext context) {
    if (badgeIcon == 'none') return const SizedBox.shrink();
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: badgeColorFromHex(badgeColor),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 1.5),
      ),
      child: Icon(badgeIconData(badgeIcon), color: Colors.white, size: size * 0.6),
    );
  }
}

/// Outlined pill with icon + name - used for property tags shown side by side.
class TagChip extends StatelessWidget {
  final String name;
  final String badgeIcon;
  final String? badgeColor;

  const TagChip({super.key, required this.name, required this.badgeIcon, this.badgeColor});

  @override
  Widget build(BuildContext context) {
    final color = badgeColorFromHex(badgeColor);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (badgeIcon != 'none') ...[
            Icon(badgeIconData(badgeIcon), size: 13, color: color),
            const SizedBox(width: 4),
          ],
          Text(name, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}