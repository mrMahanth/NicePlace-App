import 'package:flutter/material.dart';
import '../../models/tag_model.dart';
import '../../services/tag_service.dart';
import 'tag_apply_screen.dart';

class TagsScreen extends StatefulWidget {
  const TagsScreen({super.key});

  @override
  State<TagsScreen> createState() => _TagsScreenState();
}

class _TagsScreenState extends State<TagsScreen> {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Tags & Benefits"),
          bottom: const TabBar(
            tabs: [
              Tab(text: "Available"),
              Tab(text: "My Requests"),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _AvailableTagsTab(),
            _MyRequestsTab(),
          ],
        ),
      ),
    );
  }
}

// ---------------- AVAILABLE TAGS TAB ----------------

class _AvailableTagsTab extends StatefulWidget {
  const _AvailableTagsTab();

  @override
  State<_AvailableTagsTab> createState() => _AvailableTagsTabState();
}

class _AvailableTagsTabState extends State<_AvailableTagsTab> {
  bool isLoading = true;
  String errorMessage = '';
  List<Tag> tags = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    final result = await TagService.fetchAvailableTags();

    if (result['success']) {
      setState(() {
        tags = result['data'];
        isLoading = false;
      });
    } else {
      setState(() {
        errorMessage = 'Could not load tags.';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) return const Center(child: CircularProgressIndicator());
    if (errorMessage.isNotEmpty) {
      return Center(child: Text(errorMessage));
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: tags.isEmpty
          ? ListView(
              children: const [
                SizedBox(height: 100),
                Center(child: Text("No tags available right now.")),
              ],
            )
          : ListView.separated(
              itemCount: tags.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final tag = tags[index];
                return ListTile(
                  leading: const Icon(Icons.local_offer_outlined),
                  title: Text(tag.name),
                  subtitle: Text(
                    tag.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () async {
                    final applied = await Navigator.push<bool>(
                      context,
                      MaterialPageRoute(builder: (context) => TagApplyScreen(tag: tag)),
                    );
                    if (applied == true) {
                      // Could show a message here, but the "My Requests" tab
                      // will reflect it next time it's opened.
                    }
                  },
                );
              },
            ),
    );
  }
}

// ---------------- MY REQUESTS TAB ----------------

class _MyRequestsTab extends StatefulWidget {
  const _MyRequestsTab();

  @override
  State<_MyRequestsTab> createState() => _MyRequestsTabState();
}

class _MyRequestsTabState extends State<_MyRequestsTab> {
  bool isLoading = true;
  String errorMessage = '';
  List<TagRequest> requests = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    final result = await TagService.fetchMyTagRequests();

    if (result['success']) {
      setState(() {
        requests = result['data'];
        isLoading = false;
      });
    } else {
      setState(() {
        errorMessage = 'Could not load your requests.';
        isLoading = false;
      });
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'approved':
        return Colors.green.shade100;
      case 'rejected':
        return Colors.red.shade100;
      default:
        return Colors.orange.shade100;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) return const Center(child: CircularProgressIndicator());
    if (errorMessage.isNotEmpty) {
      return Center(child: Text(errorMessage));
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: requests.isEmpty
          ? ListView(
              children: const [
                SizedBox(height: 100),
                Center(child: Text("You haven't applied for any tags yet.")),
              ],
            )
          : ListView.separated(
              itemCount: requests.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final req = requests[index];
                return ListTile(
                  title: Text(req.tagName),
                  subtitle: req.status == 'rejected' && req.rejectionReason.isNotEmpty
                      ? Text("Reason: ${req.rejectionReason}")
                      : Text("Requested on ${req.requestedAt.split('T').first}"),
                  trailing: Chip(
                    label: Text(req.status),
                    backgroundColor: _statusColor(req.status),
                  ),
                );
              },
            ),
    );
  }
}