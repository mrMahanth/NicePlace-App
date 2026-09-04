import 'package:flutter/material.dart';
import '../models/notification_model.dart';
import '../services/notification_service.dart';

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

  @override
  void initState() {
    super.initState();
    loadNotifications();
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
          onTap: () => handleTap(notification),
        );
      },
    );
  }
}