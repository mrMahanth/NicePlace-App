import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../models/project_document_model.dart';
import '../services/project_service.dart';
import 'post_project_nearby_places_screen.dart';

class PostProjectDocumentsScreen extends StatefulWidget {
  final int projectId;

  const PostProjectDocumentsScreen({super.key, required this.projectId});

  @override
  State<PostProjectDocumentsScreen> createState() => _PostProjectDocumentsScreenState();
}

class _PostProjectDocumentsScreenState extends State<PostProjectDocumentsScreen> {
  List<ProjectDocumentModel> _documents = [];
  bool _isLoading = true;
  String? _loadError;
  bool _isUploading = false;

  final TextEditingController _labelController = TextEditingController();

  static const List<String> _suggestedLabels = [
    "RERA Certificate", "Floor Plan", "NOC", "Builder Approval",
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _labelController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });
    try {
      final project = await ProjectService.fetchProjectRaw(widget.projectId);
      final docs = (project['documents'] as List<dynamic>? ?? [])
          .map((d) => ProjectDocumentModel.fromJson(d))
          .toList();
      setState(() {
        _documents = docs;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _loadError = "Could not load documents. Please check your internet connection.";
        _isLoading = false;
      });
    }
  }

  Future<void> _pickLabelAndUpload() async {
    _labelController.clear();
    final label = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text("Document Label"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _labelController,
                decoration: const InputDecoration(
                  hintText: "e.g. RERA Certificate",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                children: _suggestedLabels.map((l) {
                  return ActionChip(
                    label: Text(l, style: const TextStyle(fontSize: 12)),
                    onPressed: () => _labelController.text = l,
                  );
                }).toList(),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext, _labelController.text.trim()),
              child: const Text("Choose File"),
            ),
          ],
        );
      },
    );

    if (label == null || label.isEmpty) return;

    final file = await FilePicker.pickFile();
    if (file == null || file.path == null) return;

    setState(() => _isUploading = true);

    final result = await ProjectService.uploadDocument(
      projectId: widget.projectId,
      label: label,
      filePath: file.path!,
    );

    setState(() => _isUploading = false);

    if (!mounted) return;

    if (result["success"] == true) {
      await _loadData();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Upload failed. Please try again.")),
      );
    }
  }

  Future<void> _deleteDocument(ProjectDocumentModel doc) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text("Delete Document"),
        content: Text("Delete \"${doc.label}\"?"),
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

    final result = await ProjectService.deleteDocument(
      projectId: widget.projectId,
      documentId: doc.id,
    );

    if (!mounted) return;

    if (result["success"] == true) {
      setState(() => _documents.removeWhere((d) => d.id == doc.id));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Could not delete. Please try again.")),
      );
    }
  }

  void _continue() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PostProjectNearbyPlacesScreen(projectId: widget.projectId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Project Documents")),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _loadError != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_loadError!),
                      const SizedBox(height: 12),
                      ElevatedButton(onPressed: _loadData, child: const Text("Try Again")),
                    ],
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    const Text(
                      "Upload shared documents like RERA Certificate, Floor Plan, or NOC. This step is optional.",
                      style: TextStyle(fontSize: 12, color: Colors.black54),
                    ),
                    const SizedBox(height: 16),
                    ..._documents.map((doc) {
                      return Card(
                        child: ListTile(
                          leading: const Icon(Icons.description_outlined),
                          title: Text(doc.label),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.red),
                            onPressed: () => _deleteDocument(doc),
                          ),
                        ),
                      );
                    }),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: _isUploading ? null : _pickLabelAndUpload,
                      icon: _isUploading
                          ? const SizedBox(
                              height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.upload_file),
                      label: Text(_isUploading ? "Uploading..." : "Upload Document"),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _continue,
                      style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(14)),
                      child: const Text("Save & Continue"),
                    ),
                  ],
                ),
    );
  }
}