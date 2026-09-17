import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import '../services/user_profile_service.dart';

class PhotoUploadHelper {
  /// Returns true on success, false on upload failure, or null if the user
  /// cancelled at any step (picking or cropping) - callers should treat
  /// null as a silent no-op, not an error.
  static Future<bool?> pickCropAndUpload(BuildContext context) async {
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
    if (source == null) return null;

    final picked = await ImagePicker().pickImage(source: source, imageQuality: 90);
    if (picked == null) return null;

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
    if (cropped == null) return null;

    final result = await UserProfileService.uploadProfilePhoto(File(cropped.path));
    return result['success'] == true;
  }
}