class ConversationModel {
  final int partnerId;
  final String partnerName;
  final String partnerRole;
  final String? partnerAvatarUrl;
  final String lastMessage;
  final String lastSentAt;
  final int lastSenderId;
  final int unreadCount;

  const ConversationModel({
    required this.partnerId,
    required this.partnerName,
    required this.partnerRole,
    this.partnerAvatarUrl,
    required this.lastMessage,
    required this.lastSentAt,
    required this.lastSenderId,
    this.unreadCount = 0,
  });

  factory ConversationModel.fromJson(Map<String, dynamic> json) {
    return ConversationModel(
      partnerId: (json['partner_id'] as num).toInt(),
      partnerName: json['partner_name']?.toString() ?? 'Usuario',
      partnerRole: json['partner_role']?.toString() ?? 'reader',
      partnerAvatarUrl: json['partner_avatar_url']?.toString(),
      lastMessage: json['last_message']?.toString() ?? '',
      lastSentAt: json['last_sent_at']?.toString() ?? '',
      lastSenderId: (json['last_sender_id'] as num).toInt(),
      unreadCount: (json['unread_count'] as num?)?.toInt() ?? 0,
    );
  }
}

class PrivateMessageModel {
  final int id;
  final int senderId;
  final int recipientId;
  final String content;
  final String sentAt;
  final String? readAt;

  const PrivateMessageModel({
    required this.id,
    required this.senderId,
    required this.recipientId,
    required this.content,
    required this.sentAt,
    this.readAt,
  });

  factory PrivateMessageModel.fromJson(Map<String, dynamic> json) {
    return PrivateMessageModel(
      id: (json['id'] as num).toInt(),
      senderId: (json['sender_id'] as num).toInt(),
      recipientId: (json['recipient_id'] as num).toInt(),
      content: json['content']?.toString() ?? '',
      sentAt: json['sent_at']?.toString() ?? '',
      readAt: json['read_at']?.toString(),
    );
  }
}
