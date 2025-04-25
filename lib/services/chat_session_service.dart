import 'dart:developer';
import '../models/chat_session.dart';
import '../utils/supabase_client.dart';

class ChatSessionService {
  // Singleton pattern
  static final ChatSessionService _instance = ChatSessionService._internal();
  factory ChatSessionService() => _instance;
  ChatSessionService._internal();

  Future<List<ChatSessionHeader>> loadUserChats(String userId) async {
    try {
      final response = await supabase
          .from('chat_sessions')
          .select() // Select all columns by default, including new ones
          .eq('user_id', userId)
          // Order by pinned status first, then by creation date
          .order('is_pinned', ascending: false)
          .order('created_at', ascending: false);

      return response.map((data) => ChatSessionHeader(
            id: data['id'],
            title: data['title'],
            isPinned: data['is_pinned'] ?? false, // Fetch and provide default
            isArchived: data['is_archived'] ?? false, // Fetch and provide default
          )).toList();
    } catch (e, stackTrace) {
      log('[ChatSessionService] Error loading chats: $e');
      log('[ChatSessionService] Stack trace: $stackTrace');
      rethrow;
    }
  }

  Future<void> createNewChat(String sessionId, String userId) async {
    try {
      await supabase.from('chat_sessions').insert({
        'id': sessionId,
        'user_id': userId,
        'title': 'New Chat',
        'created_at': DateTime.now().toIso8601String(),
        // is_pinned and is_archived default to false in DB
      });
      log('[ChatSessionService] Successfully created chat in Supabase');
    } catch (e, stackTrace) {
      log('[ChatSessionService] Error creating new chat: $e');
      log('[ChatSessionService] Stack trace: $stackTrace');
      rethrow;
    }
  }

  Future<void> updateChatTitle(String sessionId, String userId, String newTitle) async {
    try {
      await supabase
          .from('chat_sessions')
          .update({'title': newTitle})
          .eq('id', sessionId)
          .eq('user_id', userId);
      log('[ChatSessionService] Successfully updated chat title in Supabase');
    } catch (e, stackTrace) {
      log('[ChatSessionService] Error updating chat title: $e');
      log('[ChatSessionService] Stack trace: $stackTrace');
      rethrow;
    }
  }

  // Renamed from deleteChat for consistency with plan
  Future<void> deleteSession(String sessionId, String userId) async {
    try {
      await supabase
          .from('chat_sessions')
          .delete()
          .eq('id', sessionId)
          .eq('user_id', userId);
      log('[ChatSessionService] Successfully deleted chat from Supabase');
    } catch (e, stackTrace) {
      log('[ChatSessionService] Error deleting chat: $e');
      log('[ChatSessionService] Stack trace: $stackTrace');
      rethrow;
    }
  }

  // --- New Methods ---

  Future<void> updatePinStatus(String sessionId, String userId, bool isPinned) async {
    try {
      await supabase
          .from('chat_sessions')
          .update({'is_pinned': isPinned})
          .eq('id', sessionId)
          .eq('user_id', userId);
      log('[ChatSessionService] Successfully updated pin status for chat $sessionId');
    } catch (e, stackTrace) {
      log('[ChatSessionService] Error updating pin status: $e');
      log('[ChatSessionService] Stack trace: $stackTrace');
      rethrow;
    }
  }

  Future<void> updateArchiveStatus(String sessionId, String userId, bool isArchived) async {
    try {
      await supabase
          .from('chat_sessions')
          .update({'is_archived': isArchived})
          .eq('id', sessionId)
          .eq('user_id', userId);
      log('[ChatSessionService] Successfully updated archive status for chat $sessionId');
    } catch (e, stackTrace) {
      log('[ChatSessionService] Error updating archive status: $e');
      log('[ChatSessionService] Stack trace: $stackTrace');
      rethrow;
    }
  }
}
