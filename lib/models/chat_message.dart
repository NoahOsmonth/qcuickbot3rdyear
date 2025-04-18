enum MessageType { text, quickReplies }

class ChatMessage {
  final String text;
  final bool isUser;
  final MessageType type;
  final List<String>? quickReplies;
  final String? avatarUrl;

  ChatMessage({
    required this.text,
    required this.isUser,
    this.type = MessageType.text,
    this.quickReplies,
    this.avatarUrl,
  });
}
