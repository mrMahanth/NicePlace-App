import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import '../models/user_profile_model.dart';
import '../models/tag_model.dart';
import '../services/user_profile_service.dart';
import '../services/tag_service.dart';
import 'edit_profile_screen.dart';
import 'change_password_screen.dart';
import 'tags/tag_apply_screen.dart';

class MyProfileScreen extends StatefulWidget {
  const MyProfileScreen({super.key});

  @override
  State<MyProfileScreen> createState() => _MyProfileScreenState();
}

class _MyProfileScreenState extends State<MyProfileScreen> {
  bool _isLoading = true;
  bool _isUploadingPhoto = false;
  UserProfileModel? _profile;
  List<Tag> _availableToEarn = [];

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() => _isLoading = true);

    final profileResult = await UserProfileService.fetchMyProfile();
    final tagsResult = await TagService.fetchAvailableTags();

    if (!mounted) return;

    UserProfileModel? profile;
    List<Tag> available = [];

    if (profileResult['success'] == true) {
      profile = profileResult['data'] as UserProfileModel;
    }
    if (tagsResult['success'] == true) {
      final allTags = tagsResult['data'] as List<Tag>;
      final earnedIds = (profile?.tags ?? []).map((t) => t.id).toSet();
      available = allTags.where((t) => !earnedIds.contains(t.id)).toList();
    }

    setState(() {
      _profile = profile;
      _availableToEarn = available;
      _isLoading = false;
    });
  }

  Future<void> _handleChangePhoto() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: const Text("Take Photo"),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text("Choose from Gallery"),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;

    final picked = await ImagePicker().pickImage(source: source, imageQuality: 90);
    if (picked == null) return;

    final cropped = await ImageCropper().cropImage(
      sourcePath: picked.path,
      aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Adjust Photo',
          lockAspectRatio: true,
          aspectRatioPresets: const [CropAspectRatioPreset.square],
        ),
        IOSUiSettings(
          title: 'Adjust Photo',
          aspectRatioLockEnabled: true,
        ),
      ],
    );
    if (cropped == null) return;

    setState(() => _isUploadingPhoto = true);
    final result = await UserProfileService.uploadProfilePhoto(File(cropped.path));
    setState(() => _isUploadingPhoto = false);

    if (result['success'] == true) {
      _loadAll();
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Could not update photo. Please try again.")),
      );
    }
  }

  Future<void> _openEditProfile() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const EditProfileScreen()),
    );
    _loadAll();
  }

  Future<void> _openChangePassword() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ChangePasswordScreen()),
    );
    _loadAll();
  }

  Future<void> _applyForTag(Tag tag) async {
    final applied = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (context) => TagApplyScreen(tag: tag)),
    );
    if (applied == true) _loadAll();
  }

  Widget _sectionCard({required String title, required Widget child, Widget? action}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(title,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
                if (action != null) action,
              ],
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(label, style: TextStyle(color: Colors.grey.shade600)),
          ),
          Expanded(child: Text(value.isEmpty ? "-" : value)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final profile = _profile;
    if (profile == null) {
      return Scaffold(
        appBar: AppBar(title: const Text("My Profile")),
        body: const Center(child: Text("Could not load profile.")),
      );
    }

    final fullName = "${profile.firstName} ${profile.lastName}".trim();
    final addressParts = [
      profile.addressLine,
      profile.locality,
      profile.city,
      profile.district,
      profile.state,
      profile.pincode,
      profile.country,
    ].where((p) => p.isNotEmpty).join(", ");

    return Scaffold(
      appBar: AppBar(title: const Text("My Profile")),
      body: RefreshIndicator(
        onRefresh: _loadAll,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.grey.shade200,
                    backgroundImage: profile.profilePhoto != null
                        ? CachedNetworkImageProvider(profile.profilePhoto!)
                        : null,
                    child: profile.profilePhoto == null
                        ? const Icon(Icons.person, size: 50)
                        : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: _isUploadingPhoto ? null : _handleChangePhoto,
                      child: CircleAvatar(
                        radius: 16,
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        child: _isUploadingPhoto
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.camera_alt, size: 16, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            _sectionCard(
              title: "Personal Details",
              action: IconButton(
                icon: const Icon(Icons.edit_outlined),
                onPressed: _openEditProfile,
              ),
              child: Column(
                children: [
                  _detailRow("Name", fullName),
                  _detailRow("Mobile Number", profile.phone),
                  _detailRow("Email", profile.email),
                  _detailRow("Address", addressParts),
                ],
              ),
            ),

            _sectionCard(
              title: "Username & Password",
              action: IconButton(
                icon: const Icon(Icons.edit_outlined),
                onPressed: _openChangePassword,
              ),
              child: Column(
                children: [
                  _detailRow("Username", profile.username),
                  _detailRow("Password", "••••••••"),
                ],
              ),
            ),

            _sectionCard(
              title: "Tags & Badges",
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Earned", style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  if (profile.tags.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text("No tags earned yet.", style: TextStyle(color: Colors.grey.shade600)),
                    )
                  else
                    ...profile.tags.map((t) => ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.local_offer, color: Colors.green),
                          title: Text(t.name),
                          subtitle: t.description.isNotEmpty ? Text(t.description) : null,
                        )),
                  const Divider(),
                  const SizedBox(height: 4),
                  const Text("Available to Earn", style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  if (_availableToEarn.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text("Nothing available right now.", style: TextStyle(color: Colors.grey.shade600)),
                    )
                  else
                    ..._availableToEarn.map((tag) => ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.local_offer_outlined),
                          title: Text(tag.name),
                          subtitle: tag.description.isNotEmpty ? Text(tag.description) : null,
                          trailing: TextButton(
                            onPressed: () => _applyForTag(tag),
                            child: const Text("Apply"),
                          ),
                        )),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}