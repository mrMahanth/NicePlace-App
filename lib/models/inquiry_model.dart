class ChatMessage {
  final int id;
  final int sender;
  final String senderName;
  final String message;
  final String sentAt;
  final bool isRead;

  ChatMessage({
    required this.id,
    required this.sender,
    required this.senderName,
    required this.message,
    required this.sentAt,
    required this.isRead,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'],
      sender: json['sender'],
      senderName: json['sender_name'] ?? '',
      message: json['message'] ?? '',
      sentAt: json['sent_at'] ?? '',
      isRead: json['is_read'] ?? false,
    );
  }
}

class Inquiry {
  final int id;
  final int property;
  final String propertyTitle;
  final int buyer;
  final String buyerName;
  final int owner;
  final String ownerName;
  final String initialMessage;
  final String status;
  final String createdAt;
  final List<ChatMessage> messages;

  Inquiry({
    required this.id,
    required this.property,
    required this.propertyTitle,
    required this.buyer,
    required this.buyerName,
    required this.owner,
    required this.ownerName,
    required this.initialMessage,
    required this.status,
    required this.createdAt,
    required this.messages,
  });

  factory Inquiry.fromJson(Map<String, dynamic> json) {
    return Inquiry(
      id: json['id'],
      property: json['property'],
      propertyTitle: json['property_title'] ?? '',
      buyer: json['buyer'],
      buyerName: json['buyer_name'] ?? '',
      owner: json['owner'],
      ownerName: json['owner_name'] ?? '',
      initialMessage: json['initial_message'] ?? '',
      status: json['status'] ?? 'open',
      createdAt: json['created_at'] ?? '',
      messages: json['messages'] != null
          ? List<ChatMessage>.from(
              json['messages'].map((m) => ChatMessage.fromJson(m)))
          : [],
    );
  }
}