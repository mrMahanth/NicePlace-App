import 'package:flutter/material.dart';
import '../models/user_profile_model.dart';
import '../services/api_service.dart';
import '../services/app_lock_service.dart';
import '../services/user_profile_service.dart';
import '../utils/auth_guard.dart';
import 'inquiries_list_screen.dart';
import 'my_profile_screen.dart';
import 'tags/tags_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'photo_viewer_screen.dart';
import '../widgets/tag_badge.dart';

class ProfileScreen extends StatefulWidget {
  final VoidCallback? onLoggedOut;
  final VoidCallback? onProfileUpdated;

  const ProfileScreen({super.key, this.onLoggedOut, this.onProfileUpdated});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isLoggedIn = false;
  bool _isChecking = true;
  bool _appLockEnabled = false;
  String? _firstName;
  String? _lastName;
  String? _username;
  String? _phone;
  String? _profilePhoto;
  DisplayedTag? _displayedTag;

  String get _fullName => "${_firstName ?? ''} ${_lastName ?? ''}".trim();

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    final token = await ApiService.getAccessToken();
    final lockEnabled = await AppLockService.isAppLockEnabled();

    String? firstName;
    String? lastName;
    String? username;
    String? phone;
    String? profilePhoto;
    DisplayedTag? displayedTag;
    if (token != null) {
      final profileResult = await UserProfileService.fetchMyProfile();
      if (profileResult['success'] == true) {
        final profile = profileResult['data'] as UserProfileModel;
        firstName = profile.firstName;
        lastName = profile.lastName;
        username = profile.username;
        phone = profile.phone;
        profilePhoto = profile.profilePhoto;
        displayedTag = profile.displayedTag;
      }
    }

    if (mounted) {
      setState(() {
        _isLoggedIn = token != null;
        _appLockEnabled = lockEnabled;
        _firstName = firstName;
        _lastName = lastName;
        _username = username;
        _phone = phone;
        _profilePhoto = profilePhoto;
        _displayedTag = displayedTag;
        _isChecking = false;
      });
    }
    widget.onProfileUpdated?.call();
  }

  Future<void> _handleLoginTap() async {
    final loggedIn = await AuthGuard.ensureLoggedIn(context);
    if (loggedIn) _checkLoginStatus();
  }

  Future<void> _confirmLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Are you sure?"),
        content: const Text("You will be logged out of your account."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Log Out"),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      _handleLogout();
    }
  }

  Future<void> _handleLogout() async {
    await ApiService.logout();
    widget.onLoggedOut?.call();
    if (mounted) Navigator.of(context).pop(); // close the drawer, back to Home
  }

  Future<void> _openMessages() async {
    final loggedIn = await AuthGuard.ensureLoggedIn(context);
    if (!loggedIn) return;
    if (mounted) {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const InquiriesListScreen()),
      );
    }
  }

  Future<void> _openMyProfile() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const MyProfileScreen()),
    );
    _checkLoginStatus();
  }

  Future<void> _toggleAppLock(bool newValue) async {
    if (newValue) {
      // ON karne se pehle verify karo ki device lock kaam karta hai
      final available = await AppLockService.isDeviceLockAvailable();
      if (!available) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Pehle phone settings mein lock (PIN/Pattern/Fingerprint) set karein.")),
          );
        }
        return;
      }
      final success = await AppLockService.authenticate();
      if (!success) return; // verification fail, toggle wahi rehne do
    }

    await AppLockService.setAppLockEnabled(newValue);
    setState(() => _appLockEnabled = newValue);
  }

  @override
  Widget build(BuildContext context) {
    if (_isChecking) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Profile")),
      body: Column(
        children: [
          const SizedBox(height: 24),
          Stack(
            children: [
              GestureDetector(
                onTap: _isLoggedIn
                    ? () async {
                        final changed = await Navigator.push<bool>(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PhotoViewerScreen(photoUrl: _profilePhoto),
                          ),
                        );
                        if (changed == true) _checkLoginStatus();
                      }
                    : null,
                child: CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.grey.shade200,
                  backgroundImage: _profilePhoto != null
                      ? CachedNetworkImageProvider(_profilePhoto!)
                      : null,
                  child: _profilePhoto == null
                      ? const Icon(Icons.person, size: 50)
                      : null,
                ),
              ),
              if (_isLoggedIn && _displayedTag != null)
                Positioned(
                  bottom: 2,
                  right: 2,
                  child: TagBadgeIcon(
                    badgeIcon: _displayedTag!.badgeIcon,
                    badgeColor: _displayedTag!.badgeColor,
                    size: 22,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              _isLoggedIn
                  ? (_fullName.isNotEmpty ? _fullName : "Your Profile")
                  : "Browsing as guest",
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 32),

          if (_isLoggedIn)
            ListTile(
              leading: const Icon(Icons.person_outline),
              title: const Text("My Profile"),
              subtitle: const Text("View your details, tags and account info"),
              trailing: const Icon(Icons.chevron_right),
              onTap: _openMyProfile,
            ),

          if (_isLoggedIn)
            SwitchListTile(
              secondary: const Icon(Icons.lock),
              title: const Text("App Lock"),
              subtitle: const Text("Fingerprint/PIN/Pattern se app secure karein"),
              value: _appLockEnabled,
              onChanged: _toggleAppLock,
            ),

          if (_isLoggedIn)
            ListTile(
              leading: const Icon(Icons.local_offer_outlined),
              title: const Text("Tags & Benefits"),
              subtitle: const Text("Apply for tags and view your benefits"),
              trailing: const Icon(Icons.chevron_right),
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const TagsScreen()),
                );
              },
            ),

          ListTile(
            leading: const Text("💬", style: TextStyle(fontSize: 22)),
            title: const Text("Messages"),
            subtitle: const Text("Your inquiries and replies"),
            trailing: const Icon(Icons.chevron_right),
            onTap: _openMessages,
          ),
          const Divider(),

          const Spacer(),

          Padding(
            padding: const EdgeInsets.only(bottom: 32),
            child: _isLoggedIn
                ? ElevatedButton.icon(
                    icon: const Icon(Icons.logout),
                    label: const Text("Logout"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                    ),
                    onPressed: _confirmLogout,
                  )
                : ElevatedButton.icon(
                    icon: const Icon(Icons.login),
                    label: const Text("Login"),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                    ),
                    onPressed: _handleLoginTap,
                  ),
          ),
        ],
      ),
    );
  }
}