import 'package:flutter/material.dart';
import '../models/user_profile_model.dart';
import '../services/user_profile_service.dart';
import '../screens/edit_profile_screen.dart';
import 'auth_guard.dart';

class ProfileGuard {
  /// Login aur first-name dono confirm karta hai, property/project post karne
  /// se pehle (spec: first name mandatory hai). Dono satisfy hone par hi true.
  static Future<bool> ensureReadyToPost(BuildContext context) async {
    final loggedIn = await AuthGuard.ensureLoggedIn(
      context,
      message: "Please login to post a property.",
    );
    if (!loggedIn || !context.mounted) return false;

    final result = await UserProfileService.fetchMyProfile();
    if (result['success'] != true) {
      // Network hiccup - apna check na roke, backend to final safety net hai hi.
      return true;
    }

    final profile = result['data'] as UserProfileModel;
    if (profile.firstName.trim().isNotEmpty) return true;

    if (!context.mounted) return false;

    final shouldEdit = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        content: const Text(
          "Please add your first name to your profile before posting a property.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Edit Profile"),
          ),
        ],
      ),
    );

    if (shouldEdit != true || !context.mounted) return false;

    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (context) => const EditProfileScreen()),
    );

    if (saved != true) return false;

    // Wapas aane par dobara check - user ne cancel kiya to bhi pakad lega.
    final recheck = await UserProfileService.fetchMyProfile();
    if (recheck['success'] == true) {
      final updatedProfile = recheck['data'] as UserProfileModel;
      return updatedProfile.firstName.trim().isNotEmpty;
    }
    return false;
  }
}