import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../utils/photo_upload_helper.dart';

class PhotoViewerScreen extends StatefulWidget {
  final String? photoUrl;

  const PhotoViewerScreen({super.key, this.photoUrl});

  @override
  State<PhotoViewerScreen> createState() => _PhotoViewerScreenState();
}

class _PhotoViewerScreenState extends State<PhotoViewerScreen> {
  bool _isUploading = false;

  Future<void> _handleEdit() async {
    setState(() => _isUploading = true);
    final success = await PhotoUploadHelper.pickCropAndUpload(context);
    setState(() => _isUploading = false);

    if (success == true) {
      // Return true so the caller (My Profile / side panel) knows to
      // reload the full profile and pick up the new photo everywhere.
      if (mounted) Navigator.pop(context, true);
    } else if (success == false && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Could not update photo. Please try again.")),
      );
    }
    // success == null (cancelled) - stay on the viewer, do nothing.
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: _isUploading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.edit),
            onPressed: _isUploading ? null : _handleEdit,
          ),
        ],
      ),
      body: Center(
        child: widget.photoUrl != null
            ? InteractiveViewer(
                child: CachedNetworkImage(
                  imageUrl: widget.photoUrl!,
                  fit: BoxFit.contain,
                ),
              )
            : const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.person, size: 120, color: Colors.white54),
                  SizedBox(height: 12),
                  Text("No photo set", style: TextStyle(color: Colors.white70)),
                ],
              ),
      ),
    );
  }
}