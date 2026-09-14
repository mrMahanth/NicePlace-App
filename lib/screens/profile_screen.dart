import 'package:flutter/material.dart';
import '../models/user_profile_model.dart';
import '../services/api_service.dart';
import '../services/app_lock_service.dart';
import '../services/user_profile_service.dart';
import '../utils/auth_guard.dart';
import 'inquiries_list_screen.dart';
import 'edit_profile_screen.dart';
import 'set_username_screen.dart';
import 'tags/tags_screen.dart';

class ProfileScreen extends StatefulWidget {
  final VoidCallback? onLoggedOut;

  const ProfileScreen({super.key, this.onLoggedOut});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isLoggedIn = false;
  bool _isChecking = true;
  bool _appLockEnabled = false;
  String? _firstName;
  String? _username;
  String? _phone;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    final token = await ApiService.getAccessToken();
    final lockEnabled = await AppLockService.isAppLockEnabled();

    String? firstName;
    String? username;
    String? phone;
    if (token != null) {
      final profileResult = await UserProfileService.fetchMyProfile();
      if (profileResult['success'] == true) {
        final profile = profileResult['data'] as UserProfileModel;
        firstName = profile.firstName;
        username = profile.username;
        phone = profile.phone;
      }
    }

    if (mounted) {
      setState(() {
        _isLoggedIn = token != null;
        _appLockEnabled = lockEnabled;
        _firstName = firstName;
        _username = username;
        _phone = phone;
        _isChecking = false;
      });
    }
  }

  // Heuristic: OTP-only users have username == phone (set automatically at
  // signup). Once they use "Set Username", the two diverge. Edge case: if
  // someone deliberately sets their username to their own phone number,
  // this row would reappear - acceptable for now, flagged for later if a
  // dedicated has_custom_username flag is ever wanted.
  bool get _hasCustomUsername =>
      _username != null &&
      _username!.isNotEmpty &&
      _phone != null &&
      _phone!.isNotEmpty &&
      _username != _phone;

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

  Future<void> _openEditProfile() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const EditProfileScreen()),
    );
    _checkLoginStatus();
  }

  Future<void> _openSetUsername() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SetUsernameScreen()),
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
          const CircleAvatar(
            radius: 50,
            child: Icon(Icons.person, size: 50),
          ),
          const SizedBox(height: 16),
          Text(
            _isLoggedIn
                ? ((_firstName != null && _firstName!.isNotEmpty)
                    ? _firstName!
                    : "Your Profile")
                : "Browsing as guest",
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 32),

          if (_isLoggedIn)
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text("Edit Profile"),
              subtitle: const Text("Update your details and address"),
              trailing: const Icon(Icons.chevron_right),
              onTap: _openEditProfile,
            ),

          if (_isLoggedIn && !_hasCustomUsername)
            ListTile(
              leading: const Icon(Icons.badge_outlined),
              title: const Text("Set Username"),
              subtitle: const Text("Create a username & password to also login without OTP"),
              trailing: const Icon(Icons.chevron_right),
              onTap: _openSetUsername,
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