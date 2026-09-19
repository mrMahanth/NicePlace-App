import 'package:flutter/material.dart';
import '../models/tag_model.dart';

typedef ApplyCallback = void Function(Tag tag);

class TagStatusHelper {
  /// Returns (trailing widget, onTap) for a tag row, based on the user's
  /// most recent request for that tag (null if never applied).
  static (Widget, VoidCallback?) rowStatus({
    required BuildContext context,
    required Tag tag,
    required TagRequest? request,
    required ApplyCallback onApply,
  }) {
    if (request == null) {
      return (const Icon(Icons.chevron_right), () => onApply(tag));
    }
    switch (request.status) {
      case 'pending':
        return (
          Chip(label: const Text("Pending"), backgroundColor: Colors.orange.shade100),
          () => _showPendingDialog(context),
        );
      case 'rejected':
        return (
          Chip(label: const Text("Rejected"), backgroundColor: Colors.red.shade100),
          () => _showRejectedDialog(context, request.rejectionReason, () => onApply(tag)),
        );
      case 'approved':
        return (
          Chip(label: const Text("Approved"), backgroundColor: Colors.green.shade100),
          () => _showApprovedDialog(context),
        );
      default:
        return (const Icon(Icons.chevron_right), () => onApply(tag));
    }
  }

  static void _showPendingDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Application in Progress"),
        content: const Text("You have already applied for the Tag and Approval is in Progress."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("OK")),
        ],
      ),
    );
  }

  static void _showRejectedDialog(BuildContext context, String reason, VoidCallback onApplyAgain) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Application Rejected"),
        content: Text(reason.isNotEmpty ? reason : "Your application was rejected."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Close")),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              onApplyAgain();
            },
            child: const Text("Apply Again"),
          ),
        ],
      ),
    );
  }

  static void _showApprovedDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Already Earned"),
        content: const Text("You already have this tag."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("OK")),
        ],
      ),
    );
  }

  /// Builds a map of tagId -> most recent TagRequest (the backend already
  /// orders /tag-requests/mine/ newest-first, so the first match wins).
  static Map<int, TagRequest> buildRequestMap(List<TagRequest> requests) {
    final map = <int, TagRequest>{};
    for (final req in requests) {
      map.putIfAbsent(req.tag, () => req);
    }
    return map;
  }
}