import 'package:flutter/material.dart';
import '../services/property_service.dart';
import '../services/project_service.dart';
import 'post_project_description_screen.dart';

class PostProjectUnitsSummaryScreen extends StatefulWidget {
  final int projectId;

  const PostProjectUnitsSummaryScreen({super.key, required this.projectId});

  @override
  State<PostProjectUnitsSummaryScreen> createState() =>
      _PostProjectUnitsSummaryScreenState();
}

class _PostProjectUnitsSummaryScreenState
    extends State<PostProjectUnitsSummaryScreen> {
  List<Map<String, dynamic>> _units = [];
  bool _isLoading = true;
  String? _loadError;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadUnits();
  }

  Future<void> _loadUnits() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });
    try {
      final units = await PropertyService.fetchUnitsForProject(widget.projectId);
      setState(() {
        _units = units;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _loadError = "Could not load units. Please check your internet connection.";
        _isLoading = false;
      });
    }
  }

  int _photoCount(Map<String, dynamic> unit) {
    final media = unit['media'] as List<dynamic>? ?? [];
    return media.where((m) => m['media_type'] == 'image').length;
  }

  Future<void> _submitAll() async {
    setState(() => _isSubmitting = true);

    final result = await ProjectService.bulkSubmitForReview(widget.projectId);

    setState(() => _isSubmitting = false);

    if (!mounted) return;

    if (result["success"] == true) {
      final data = result["data"];
      final submittedIds = (data["submitted_ids"] as List<dynamic>? ?? []);
      final alreadySubmitted = data["already_submitted_count"] ?? 0;
      final skipped = (data["skipped"] as List<dynamic>? ?? []);

      await showDialog(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text("Submission Result"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("✅ ${submittedIds.length} unit(s) submitted for review now."),
                if (alreadySubmitted > 0)
                  Text("ℹ️ $alreadySubmitted unit(s) were already submitted earlier."),
                if (skipped.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  const Text("⚠️ Skipped units (missing info):",
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  ...skipped.map((s) {
                    final missing = (s["missing"] as List<dynamic>? ?? []).join(", ");
                    return Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text("• ${s["title"]} — missing: $missing"),
                    );
                  }),
                ],
              ],
            ),
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text("OK"),
            ),
          ],
        ),
      );

      await _loadUnits();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result["error"].toString())),
      );
    }
  }

  void _continue() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PostProjectDescriptionScreen(projectId: widget.projectId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Units Summary")),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _loadError != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_loadError!),
                      const SizedBox(height: 12),
                      ElevatedButton(onPressed: _loadUnits, child: const Text("Try Again")),
                    ],
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    const Text(
                      "Review all units before submitting for admin approval.",
                      style: TextStyle(fontSize: 12, color: Colors.black54),
                    ),
                    const SizedBox(height: 16),

                    if (_units.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Text("No units created yet."),
                      )
                    else
                      ..._units.map((unit) {
                        final photoCount = _photoCount(unit);
                        final hasNoPhotos = photoCount == 0;

                        return Card(
                          child: ListTile(
                            title: Text(unit['title'] ?? ''),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("Status: ${unit['status']}"),
                                Text("$photoCount photo(s)"),
                                if (hasNoPhotos)
                                  const Text(
                                    "⚠️ Photos are missing, you can upload them later.",
                                    style: TextStyle(color: Colors.orange, fontSize: 12),
                                  ),
                              ],
                            ),
                          ),
                        );
                      }),

                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: (_units.isEmpty || _isSubmitting) ? null : _submitAll,
                      style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(14)),
                      child: _isSubmitting
                          ? const SizedBox(
                              height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Text("Submit All for Review"),
                    ),

                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _continue,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.all(14),
                        backgroundColor: Colors.grey.shade300,
                        foregroundColor: Colors.black,
                      ),
                      child: const Text("Continue to Project Description"),
                    ),
                  ],
                ),
    );
  }
}