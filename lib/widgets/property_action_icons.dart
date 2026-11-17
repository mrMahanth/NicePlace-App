import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../models/property_model.dart';
import '../services/property_action_store.dart';
import '../services/property_service.dart';
import '../utils/auth_guard.dart';
import '../theme/app_theme.dart';

class PropertyActionIcons extends StatefulWidget {
  final Property property;
  final Axis direction;
  final bool onImage;

  const PropertyActionIcons({
    super.key,
    required this.property,
    this.direction = Axis.horizontal,
    this.onImage = false,
  });

  @override
  State<PropertyActionIcons> createState() => _PropertyActionIconsState();
}

class _PropertyActionIconsState extends State<PropertyActionIcons> {
  static const Color _facebookBlue = Color(0xFF1877F2);
  final PropertyActionStore _store = PropertyActionStore.instance;

  @override
  void initState() {
    super.initState();
    _store.addListener(_onStoreChanged);
  }

  @override
  void dispose() {
    _store.removeListener(_onStoreChanged);
    super.dispose();
  }

  void _onStoreChanged() {
    if (mounted) setState(() {});
  }

  // Store mein value ho to wahi, warna server se aayi hui property ki value
  bool _isOn(String actionType) {
    final p = widget.property;
    final fallback = actionType == 'favorite'
        ? p.isFavorited
        : actionType == 'save'
            ? p.isSaved
            : p.isInterested;
    return _store.get(p.id, actionType) ?? fallback;
  }

  Future<void> _toggle(String actionType) async {
    final loggedIn = await AuthGuard.ensureLoggedIn(context, message: _loginMessageFor(actionType));
    if (!loggedIn || !mounted) return;

    final id = widget.property.id;
    final previous = _isOn(actionType);
    _store.set(id, actionType, !previous); // turant visual feedback, sab jagah

    final result = await PropertyService.togglePropertyAction(
      propertyId: id,
      actionType: actionType,
    );

    if (result['success'] == true) {
      final serverActive = result['data']?['active'] as bool?;
      if (serverActive != null) _store.set(id, actionType, serverActive);
    } else {
      _store.set(id, actionType, previous); // revert
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Could not update. Please try again.")),
        );
      }
    }
  }

  String _loginMessageFor(String actionType) {
    switch (actionType) {
      case 'favorite':
        return "Please login to add favourites";
      case 'save':
        return "Please login to save properties";
      case 'interested':
        return "Please login to show interest";
      default:
        return "Please login to continue";
    }
  }

  void _onShare() {
    final p = widget.property;
    Share.share('Check out "${p.title}" on NicePlace - ${p.locality}, ${p.city}', subject: p.title);
  }

  Widget _iconButton({
    required IconData icon,
    required bool active,
    required Color activeColor,
    required VoidCallback onTap,
  }) {
    final color = active ? activeColor : (widget.onImage ? Colors.white : AppColors.textMuted);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: widget.direction == Axis.vertical
            ? const EdgeInsets.symmetric(vertical: 4, horizontal: 4)
            : const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Icon(
          icon,
          size: 24,
          color: color,
          shadows: widget.onImage
              ? const [Shadow(blurRadius: 4, color: Colors.black45)]
              : null,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final favorited = _isOn('favorite');
    final saved = _isOn('save');
    final interested = _isOn('interested');

    final icons = [
      _iconButton(
        icon: favorited ? Icons.favorite : Icons.favorite_border,
        active: favorited,
        activeColor: Colors.red,
        onTap: () => _toggle('favorite'),
      ),
      _iconButton(
        icon: saved ? Icons.bookmark : Icons.bookmark_border,
        active: saved,
        activeColor: const Color(0xFFEC4899), // pink
        onTap: () => _toggle('save'),
      ),
      _iconButton(
        icon: interested ? Icons.thumb_up : Icons.thumb_up_outlined,
        active: interested,
        activeColor: _facebookBlue,
        onTap: () => _toggle('interested'),
      ),
      _iconButton(
        icon: Icons.share_outlined,
        active: false,
        activeColor: AppColors.textMuted,
        onTap: _onShare,
      ),
    ];

    return widget.direction == Axis.vertical
        ? Column(mainAxisSize: MainAxisSize.min, children: icons)
        : Row(mainAxisSize: MainAxisSize.min, children: icons);
  }
}