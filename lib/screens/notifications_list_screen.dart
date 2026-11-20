import 'package:flutter/material.dart';
import '../models/notification_model.dart';
import '../services/notification_service.dart';
import 'inquiry_detail_screen.dart';
import '../utils/auto_refresh.dart';

class NotificationsListScreen extends StatefulWidget {
  const NotificationsListScreen({super.key});

  @override
  State<NotificationsListScreen> createState() =>
      _NotificationsListScreenState();
}

class _NotificationsListScreenState extends State<NotificationsListScreen> {
  bool isLoading = true;
  String errorMessage = '';
  List<AppNotification> notifications = [];

  late final AutoRefresher _auto;

  @override
  void initState() {
    super.initState();
    _auto = AutoRefresher(onRefresh: _silentLoad, seconds: 10);
    loadNotifications();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _auto.start(context);
  }

  @override
  void dispose() {
    _auto.dispose();
    super.dispose();
  }

  // Bina spinner ke chup-chaap naya data lao
  Future<void> _silentLoad() async {
    final result = await NotificationService.fetchNotifications();
    if (!mounted) return;
    if (result['success']) {
      setState(() {
        notifications = result['data'];
        errorMessage = '';
        isLoading = false;
      });
    }
  }

  Future<void> loadNotifications() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    final result = await NotificationService.fetchNotifications();

    if (result['success']) {
      setState(() {
        notifications = result['data'];
        isLoading = false;
      });
    } else {
      setState(() {
        errorMessage = 'Could not load notifications. Please try again.';
        isLoading = false;
      });
    }
  }

  Future<void> handleTap(AppNotification notification) async {
    if (!notification.isRead) {
      final success = await NotificationService.markAsRead(notification.id);
      if (success) {
        setState(() {
          final index = notifications.indexWhere((n) => n.id == notification.id);
          if (index != -1) {
            notifications[index] = AppNotification(
              id: notification.id,
              title: notification.title,
              message: notification.message,
              channel: notification.channel,
              isRead: true,
              createdAt: notification.createdAt,
              relatedTag: notification.relatedTag,
              relatedTagName: notification.relatedTagName,
              relatedInquiry: notification.relatedInquiry,
            );
          }
        });
      }
    }
  }

  // Tap par poora message dikhao, aur chat se judi ho to "Open chat" button
  void _showDetail(AppNotification n) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(n.title,
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Flexible(child: SingleChildScrollView(child: Text(n.message))),
            const SizedBox(height: 16),
            Row(
              children: [
                if (n.relatedInquiry != null)
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(sheetContext);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                InquiryDetailScreen(inquiryId: n.relatedInquiry!),
                          ),
                        );
                      },
                      child: const Text('Open chat'),
                    ),
                  ),
                if (n.relatedInquiry != null) const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(sheetContext),
                    child: const Text('Close'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: RefreshIndicator(
        onRefresh: loadNotifications,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (errorMessage.isNotEmpty) {
      return ListView(
        children: [
          const SizedBox(height: 100),
          Center(child: Text(errorMessage)),
        ],
      );
    }

    if (notifications.isEmpty) {
      return ListView(
        children: const [
          SizedBox(height: 100),
          Center(child: Text('No notifications yet.')),
        ],
      );
    }

    return ListView.separated(
      itemCount: notifications.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final notification = notifications[index];
        return ListTile(
          tileColor: notification.isRead ? null : Colors.blue.shade50,
          leading: Icon(
            notification.isRead
                ? Icons.notifications_none
                : Icons.notifications_active,
            color: notification.isRead ? Colors.grey : Colors.blue,
          ),
          title: Text(
            notification.title,
            style: TextStyle(
              fontWeight:
                  notification.isRead ? FontWeight.normal : FontWeight.bold,
            ),
          ),
          subtitle: Text(
            notification.message,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          onTap: () async {
            await handleTap(notification);
            if (!mounted) return;
            _showDetail(notification);
          },
        );
      },
    );
  }
}