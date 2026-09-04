class AppNotification {
  final int id;
  final String title;
  final String message;
  final String channel;
  final bool isRead;
  final String createdAt;
  final int? relatedTag;
  final String? relatedTagName;
  final int? relatedInquiry;

  AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.channel,
    required this.isRead,
    required this.createdAt,
    required this.relatedTag,
    required this.relatedTagName,
    required this.relatedInquiry,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'],
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      channel: json['channel'] ?? 'app',
      isRead: json['is_read'] ?? false,
      createdAt: json['created_at'] ?? '',
      relatedTag: json['related_tag'],
      relatedTagName: json['related_tag_name'],
      relatedInquiry: json['related_inquiry'],
    );
  }
}