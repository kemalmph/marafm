class ChatConversation {
  final String id;
  final String category;
  final String status;
  final DateTime lastMessageAt;
  final String? lastMessagePreview;
  final int unreadByStudio;

  ChatConversation({
    required this.id,
    required this.category,
    required this.status,
    required this.lastMessageAt,
    this.lastMessagePreview,
    required this.unreadByStudio,
  });

  factory ChatConversation.fromJson(Map<String, dynamic> json) {
    return ChatConversation(
      id: json['id'] as String,
      category: json['category'] as String,
      status: json['status'] as String,
      lastMessageAt: DateTime.parse(json['last_message_at'] as String),
      lastMessagePreview: json['last_message_preview'] as String?,
      unreadByStudio: (json['unread_by_studio'] as num?)?.toInt() ?? 0,
    );
  }
}

class ChatMessage {
  final String id;
  final String conversationId;
  final String senderType;
  final String body;
  final bool isRead;
  final DateTime createdAt;

  ChatMessage({
    required this.id,
    required this.conversationId,
    required this.senderType,
    required this.body,
    required this.isRead,
    required this.createdAt,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as String,
      conversationId: json['conversation_id'] as String,
      senderType: json['sender_type'] as String,
      body: json['body'] as String,
      isRead: (json['is_read'] as bool?) ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  bool get isFromStudio => senderType == 'studio';
}
