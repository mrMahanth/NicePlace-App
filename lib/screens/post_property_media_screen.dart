import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/property_model.dart';
import '../services/property_service.dart';
import 'post_property_description_screen.dart';

class PostPropertyMediaScreen extends StatefulWidget {
  final int propertyId;

  const PostPropertyMediaScreen({super.key, required this.propertyId});

  @override
  State<PostPropertyMediaScreen> createState() => _PostPropertyMediaScreenState();
}

class _PostPropertyMediaScreenState extends State<PostPropertyMediaScreen> {
  List<PropertyMedia> _media = [];
  bool _isLoading = true;
  bool _isUploading = false;
  bool _isAddingVideo = false;
  String? _loadError;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadMedia();
  }

  Future<void> _loadMedia() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });
    try {
      final property = await PropertyService.fetchPropertyRaw(widget.propertyId);
      final mediaList = (property['media'] as List<dynamic>? ?? [])
          .map((m) => PropertyMedia.fromJson(m))
          .toList();
      mediaList.sort((a, b) => a.order.compareTo(b.order));
      setState(() {
        _media = mediaList;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _loadError = "Could not load photos. Please check your internet connection.";
        _isLoading = false;
      });
    }
  }

  Future<void> _addPhotos() async {
    final List<XFile> picked = await _picker.pickMultiImage();
    if (picked.isEmpty) return;

    setState(() => _isUploading = true);

    for (final xfile in picked) {
      final result = await PropertyService.uploadImage(
        propertyId: widget.propertyId,
        filePath: xfile.path,
      );
      if (!mounted) return;
      if (result["success"] != true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("One of the photos failed to upload.")),
        );
      }
    }

    setState(() => _isUploading = false);
    await _loadMedia();
  }

  Future<void> _addVideoLink() async {
    final controller = TextEditingController();
    final url = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text("Add Video Link"),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: "Paste YouTube link here",
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, controller.text.trim()),
            child: const Text("Add"),
          ),
        ],
      ),
    );

    if (url == null || url.isEmpty) return;

    setState(() => _isAddingVideo = true);
    final result = await PropertyService.addVideo(propertyId: widget.propertyId, videoUrl: url);
    setState(() => _isAddingVideo = false);

    if (!mounted) return;

    if (result["success"] == true) {
      await _loadMedia();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result["error"].toString())),
      );
    }
  }

  Future<void> _deleteMedia(PropertyMedia media) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(media.mediaType == 'video' ? "Delete Video" : "Delete Photo"),
        content: Text(
          "Are you sure you want to delete this ${media.mediaType == 'video' ? 'video' : 'photo'}?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text("Delete"),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final result = await PropertyService.deleteImage(
      propertyId: widget.propertyId,
      mediaId: media.id,
    );

    if (!mounted) return;

    if (result["success"] == true) {
      setState(() => _media.removeWhere((m) => m.id == media.id));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Could not delete. Please try again.")),
      );
    }
  }

  Future<void> _setCover(PropertyMedia media) async {
    final result = await PropertyService.setCoverImage(
      propertyId: widget.propertyId,
      mediaId: media.id,
    );

    if (!mounted) return;

    if (result["success"] == true) {
      setState(() {
        _media = _media.map((m) {
          return PropertyMedia(
            id: m.id,
            file: m.file,
            videoUrl: m.videoUrl,
            mediaType: m.mediaType,
            order: m.order,
            isCover: m.id == media.id,
          );
        }).toList();
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Could not set cover photo. Please try again.")),
      );
    }
  }

  Future<void> _onReorder(int oldIndex, int newIndex) async {
    setState(() {
      if (newIndex > oldIndex) newIndex -= 1;
      final item = _media.removeAt(oldIndex);
      _media.insert(newIndex, item);
    });

    final result = await PropertyService.reorderImages(
      propertyId: widget.propertyId,
      mediaIds: _media.map((m) => m.id).toList(),
    );

    if (!mounted) return;

    if (result["success"] != true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Could not save new order. Please try again.")),
      );
    }
  }

  // YouTube link se thumbnail image nikalne ke liye video ID extract karte hain
  String? _youtubeThumbnail(String? url) {
    if (url == null) return null;
    final regExp = RegExp(
      r'(?:youtube\.com\/(?:watch\?v=|embed\/|shorts\/)|youtu\.be\/)([a-zA-Z0-9_-]{11})',
    );
    final match = regExp.firstMatch(url);
    if (match == null) return null;
    return "https://img.youtube.com/vi/${match.group(1)}/0.jpg";
  }

  Future<void> _continue() async {
    final hasImage = _media.any((m) => m.mediaType == 'image');
    if (!hasImage) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please add at least one photo before continuing.")),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PostPropertyDescriptionScreen(propertyId: widget.propertyId),
      ),
    );
  }

  Widget _buildMediaTile(PropertyMedia media) {
    final thumbnail = media.mediaType == 'video' ? _youtubeThumbnail(media.videoUrl) : media.file;

    return Padding(
      key: ValueKey(media.id),
      padding: const EdgeInsets.only(right: 10),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: thumbnail != null
                ? Image.network(
                    thumbnail,
                    width: 140,
                    height: 180,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 140,
                      height: 180,
                      color: Colors.grey.shade300,
                      child: const Icon(Icons.broken_image),
                    ),
                  )
                : Container(
                    width: 140,
                    height: 180,
                    color: Colors.grey.shade300,
                    child: const Icon(Icons.videocam),
                  ),
          ),
          if (media.mediaType == 'video')
            const Positioned.fill(
              child: Center(
                child: Icon(Icons.play_circle_fill, color: Colors.white70, size: 40),
              ),
            ),
          if (media.isCover)
            Positioned(
              top: 4,
              left: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.amber,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text("Cover", style: TextStyle(fontSize: 10, color: Colors.black)),
              ),
            ),
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: () => _deleteMedia(media),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                child: const Icon(Icons.close, color: Colors.white, size: 16),
              ),
            ),
          ),
          if (media.mediaType == 'image' && !media.isCover)
            Positioned(
              bottom: 4,
              right: 4,
              child: GestureDetector(
                onTap: () => _setCover(media),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                  child: const Icon(Icons.star_border, color: Colors.white, size: 16),
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Property Photos")),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _loadError != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_loadError!),
                      const SizedBox(height: 12),
                      ElevatedButton(onPressed: _loadMedia, child: const Text("Try Again")),
                    ],
                  ),
                )
              : Column(
                  children: [
                    const Padding(
                      padding: EdgeInsets.all(12),
                      child: Text(
                        "Add photos and videos. Long-press and drag to reorder. Tap the star to set the cover photo.",
                        style: TextStyle(fontSize: 12, color: Colors.black54),
                      ),
                    ),
                    Expanded(
                      child: _media.isEmpty
                          ? const Center(child: Text("No photos or videos added yet."))
                          : ReorderableListView.builder(
                              scrollDirection: Axis.horizontal,
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              itemCount: _media.length,
                              onReorder: _onReorder,
                              itemBuilder: (context, index) => _buildMediaTile(_media[index]),
                            ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: _isUploading ? null : _addPhotos,
                                  icon: _isUploading
                                      ? const SizedBox(
                                          height: 16,
                                          width: 16,
                                          child: CircularProgressIndicator(strokeWidth: 2))
                                      : const Icon(Icons.add_photo_alternate_outlined),
                                  label: Text(_isUploading ? "Uploading..." : "Add Photos"),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: _isAddingVideo ? null : _addVideoLink,
                                  icon: _isAddingVideo
                                      ? const SizedBox(
                                          height: 16,
                                          width: 16,
                                          child: CircularProgressIndicator(strokeWidth: 2))
                                      : const Icon(Icons.video_call_outlined),
                                  label: const Text("Add Video"),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            onPressed: _continue,
                            style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(14)),
                            child: const Text("Save & Continue"),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }
}