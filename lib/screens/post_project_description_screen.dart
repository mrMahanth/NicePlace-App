import 'package:flutter/material.dart';
import '../services/project_service.dart';
import 'main_screen.dart';

class PostProjectDescriptionScreen extends StatefulWidget {
  final int projectId;

  const PostProjectDescriptionScreen({super.key, required this.projectId});

  @override
  State<PostProjectDescriptionScreen> createState() =>
      _PostProjectDescriptionScreenState();
}

class _PostProjectDescriptionScreenState
    extends State<PostProjectDescriptionScreen> {
  final TextEditingController _descriptionController = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    setState(() => _isSaving = true);

    final result = await ProjectService.updateDescription(
      projectId: widget.projectId,
      description: _descriptionController.text.trim(),
    );

    setState(() => _isSaving = false);

    if (!mounted) return;

    if (result["success"] == true) {
      _showSuccessAndExit();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Could not save description. Please try again.")),
      );
    }
  }

  void _showSuccessAndExit() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text("Project Saved!"),
        content: const Text(
          "Your project details are saved. Units that were submitted for review will go live "
          "once approved by the admin, and the project itself will also be reviewed before "
          "it becomes publicly visible.",
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const MainScreen()),
                (route) => false,
              );
            },
            child: const Text("Done"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Project Description")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _descriptionController,
              maxLines: 8,
              decoration: const InputDecoration(
                hintText: "Add any extra details about the project (amenities, connectivity, possession date, etc.)",
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isSaving ? null : _finish,
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(14)),
              child: _isSaving
                  ? const SizedBox(
                      height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text("Finish"),
            ),
          ],
        ),
      ),
    );
  }
}