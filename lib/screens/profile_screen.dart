import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../utils/auth_guard.dart';
import 'inquiries_list_screen.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatefulWidget {
  final VoidCallback? onLoggedOut;

  const ProfileScreen({super.key, this.onLoggedOut});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}


class _ProfileScreenState extends State<ProfileScreen> {
  bool _isLoggedIn = false;
  bool _isChecking = true;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    final token = await ApiService.getAccessToken();
    if (mounted) {
      setState(() {
        _isLoggedIn = token != null;
        _isChecking = false;
      });
    }
  }

  Future<void> _handleLoginTap() async {
    final loggedIn = await AuthGuard.ensureLoggedIn(context);
    if (loggedIn) _checkLoginStatus();
  }

  Future<void> _handleLogout() async {
    await ApiService.logout();
    _checkLoginStatus();
    widget.onLoggedOut?.call();
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
            _isLoggedIn ? "Your Profile" : "Browsing as guest",
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 32),

          if (_isLoggedIn)
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text("Edit Profile"),
              subtitle: const Text("Update your details and address"),
              trailing: const Icon(Icons.chevron_right),
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const EditProfileScreen()),
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
                    onPressed: _handleLogout,
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