import 'package:flutter/material.dart';
import '../services/property_service.dart';
import 'main_screen.dart';

class PostPropertyDescriptionScreen extends StatefulWidget {
  final int propertyId;

  const PostPropertyDescriptionScreen({super.key, required this.propertyId});

  @override
  State<PostPropertyDescriptionScreen> createState() =>
      _PostPropertyDescriptionScreenState();
}

class _PostPropertyDescriptionScreenState
    extends State<PostPropertyDescriptionScreen> {
  final TextEditingController _descriptionController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submitForReview() async {
    setState(() => _isSubmitting = true);

    // Description pehle save karte hain (agar khaali bhi ho to koi baat nahi,
    // ye field mandatory nahi hai backend validation mein)
    await PropertyService.updateDescription(
      propertyId: widget.propertyId,
      description: _descriptionController.text.trim(),
    );

    final result = await PropertyService.submitForReview(widget.propertyId);

    setState(() => _isSubmitting = false);

    if (!mounted) return;

    if (result["success"] == true) {
      _showSuccessAndExit();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result["error"].toString())),
      );
    }
  }

  void _showSuccessAndExit() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text("Submitted!"),
        content: const Text(
          "Your property has been submitted for review. It will go live once approved by the admin.",
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              // Poora posting flow band karke Home pe wapas jaate hain
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
      appBar: AppBar(title: const Text("Description")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _descriptionController,
              maxLines: 8,
              decoration: const InputDecoration(
                hintText: "Add any extra details about the property (anything you'd like buyers/tenants to know)",
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isSubmitting ? null : _submitForReview,
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(14)),
              child: _isSubmitting
                  ? const SizedBox(
                      height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text("Submit for Review"),
            ),
          ],
        ),
      ),
    );
  }
}