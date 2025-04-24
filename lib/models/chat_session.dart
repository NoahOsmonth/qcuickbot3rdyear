import 'package:flutter/foundation.dart';

// --- Chat Session Header ---
@immutable
class ChatSessionHeader {
  final String id;
  final String title; // e.g., derived from the first user message

  const ChatSessionHeader({required this.id, required this.title});

  // Add copyWith and equality for potential state updates
  ChatSessionHeader copyWith({String? id, String? title}) {
    return ChatSessionHeader(
      id: id ?? this.id,
      title: title ?? this.title,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChatSessionHeader &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          title == other.title;

  @override
  int get hashCode => id.hashCode ^ title.hashCode;
}
