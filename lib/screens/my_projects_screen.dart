import 'package:flutter/material.dart';
import '../services/project_service.dart';
import '../utils/number_utils.dart';
import 'project_units_detail_screen.dart';

class MyProjectsScreen extends StatefulWidget {
  const MyProjectsScreen({super.key});

  @override
  State<MyProjectsScreen> createState() => _MyProjectsScreenState();
}

class _MyProjectsScreenState extends State<MyProjectsScreen> {
  List<Map<String, dynamic>> _projects = [];
  bool _isLoading = true;
  String? _loadError;
  String _statusFilter = 'all';

  static const List<Map<String, String>> _filterOptions = [
    {'value': 'all', 'label': 'All'},
    {'value': 'draft', 'label': 'Draft'},
    {'value': 'under_review', 'label': 'Under Review'},
    {'value': 'approved', 'label': 'Approved'},
    {'value': 'rejected', 'label': 'Rejected'},
  ];

  static const Map<String, String> _unitSuffixes = {
    'per_day': '/day',
    'per_month': '/month',
    'per_year': '/year',
    'per_sqft': '/sq.ft.',
  };

  @override
  void initState() {
    super.initState();
    _loadProjects();
  }

  Future<void> _loadProjects() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });
    try {
      final projects = await ProjectService.fetchMyProjects();
      setState(() {
        _projects = projects;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _loadError = "Could not load your projects. Please check your internet connection.";
        _isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> get _filteredProjects {
    if (_statusFilter == 'all') return _projects;
    return _projects.where((p) => p['approval_status'] == _statusFilter).toList();
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'draft':
        return Colors.grey;
      case 'under_review':
        return Colors.orange;
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _statusLabel(String status) {
    if (status == 'under_review') return 'Under Review';
    return status.isEmpty ? '' : status[0].toUpperCase() + status.substring(1);
  }

  String _startingPriceLabel(Map<String, dynamic> project) {
    final amount = NumberUtils.parseFlexibleDouble(project['starting_price']);
    if (amount == null) return 'Starting price not set';
    final unit = project['starting_price_unit'] as String? ?? '';
    final suffix = _unitSuffixes[unit] ?? '';
    return 'Starting ₹${NumberUtils.formatPrice(amount)}$suffix';
  }

  String? _coverPhotoUrl(Map<String, dynamic> project) {
    final mediaList = project['media'] as List<dynamic>? ?? [];
    final images = mediaList.where((m) => m['media_type'] == 'image').toList();
    if (images.isEmpty) return null;
    final cover = images.where((m) => m['is_cover'] == true).toList();
    return (cover.isNotEmpty ? cover.first : images.first)['file'];
  }

  Future<void> _confirmDelete(Map<String, dynamic> project) async {
    final name = project['name'] as String?;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text("Delete Project"),
        content: Text(
          "Delete \"${(name?.isNotEmpty ?? false) ? name : 'this draft project'}\"? This cannot be undone.",
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text("Cancel")),
          TextButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text("Delete")),
        ],
      ),
    );
    if (confirmed != true) return;

    final result = await ProjectService.deleteProject(project['id']);
    if (!mounted) return;

    if (result["success"] == true) {
      setState(() => _projects.removeWhere((p) => p['id'] == project['id']));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Could not delete. Please try again.")),
      );
    }
  }

  void _editComingSoon() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Editing existing projects is coming soon.")),
    );
  }

  void _openUnits(Map<String, dynamic> project) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProjectUnitsDetailScreen(
          projectId: project['id'],
          projectName: project['name'] ?? '',
        ),
      ),
    );
  }

  Widget _projectCard(Map<String, dynamic> project) {
    final status = project['approval_status'] as String? ?? 'draft';
    final isDraft = status == 'draft';
    final rejectionReason = project['rejection_reason'] as String? ?? '';
    final showRejection = status == 'rejected' && rejectionReason.isNotEmpty;
    final coverUrl = _coverPhotoUrl(project);
    final name = project['name'] as String? ?? '';
    final locality = project['locality'] as String? ?? '';
    final city = project['city'] as String? ?? '';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _openUnits(project),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: coverUrl != null
                    ? Image.network(
                        coverUrl,
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          width: 80,
                          height: 80,
                          color: Colors.grey.shade300,
                          child: const Icon(Icons.broken_image),
                        ),
                      )
                    : Container(
                        width: 80,
                        height: 80,
                        color: Colors.grey.shade300,
                        child: const Icon(Icons.apartment_outlined),
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name.isEmpty ? "(Unnamed project)" : name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (locality.isNotEmpty || city.isNotEmpty)
                      Text(
                        [locality, city].where((s) => s.isNotEmpty).join(', '),
                        style: const TextStyle(fontSize: 12, color: Colors.black54),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    const SizedBox(height: 4),
                    Text(_startingPriceLabel(project), style: const TextStyle(fontSize: 13)),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: _statusColor(status).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _statusLabel(status),
                        style: TextStyle(
                          fontSize: 11,
                          color: _statusColor(status),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (showRejection) ...[
                      const SizedBox(height: 6),
                      Text(
                        "Rejected: $rejectionReason",
                        style: const TextStyle(fontSize: 12, color: Colors.red),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        TextButton(onPressed: _editComingSoon, child: const Text("Edit")),
                        if (isDraft)
                          TextButton(
                            onPressed: () => _confirmDelete(project),
                            style: TextButton.styleFrom(foregroundColor: Colors.red),
                            child: const Text("Delete"),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("My Projects")),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _loadError != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_loadError!),
                      const SizedBox(height: 12),
                      ElevatedButton(onPressed: _loadProjects, child: const Text("Try Again")),
                    ],
                  ),
                )
              : Column(
                  children: [
                    SizedBox(
                      height: 44,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        children: _filterOptions.map((opt) {
                          final selected = _statusFilter == opt['value'];
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text(opt['label']!),
                              selected: selected,
                              onSelected: (_) => setState(() => _statusFilter = opt['value']!),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    Expanded(
                      child: _filteredProjects.isEmpty
                          ? const Center(
                              child: Text("No projects found.", style: TextStyle(color: Colors.black54)))
                          : ListView(
                              padding: const EdgeInsets.all(12),
                              children: _filteredProjects.map(_projectCard).toList(),
                            ),
                    ),
                  ],
                ),
    );
  }
}