import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'dart:developer';
import '../models/chat_session.dart';
import '../utils/supabase_client.dart';

final _uuid = Uuid();

// --- Chat History State ---
@immutable
class ChatHistoryState {
  final List<ChatSessionHeader> sessions;
  final String? activeSessionId;

  const ChatHistoryState({this.sessions = const [], this.activeSessionId});

  ChatHistoryState copyWith({
    List<ChatSessionHeader>? sessions,
    String? activeSessionId,
    bool forceActiveNull = false, // Helper to explicitly set activeSessionId to null
  }) {
    return ChatHistoryState(
      sessions: sessions ?? this.sessions,
      activeSessionId: forceActiveNull ? null : activeSessionId ?? this.activeSessionId,
    );
  }
}

// --- Chat History Notifier ---
class ChatHistoryNotifier extends StateNotifier<ChatHistoryState> {
  ChatHistoryNotifier() : super(const ChatHistoryState()) {
    // Initialize by loading user's chats from Supabase
    _loadUserChats();
  }

  Future<void> _loadUserChats() async {
    final user = supabase.auth.currentUser;
    if (user == null) {
      log('[ChatHistory] No user logged in, skipping chat loading');
      return;
    }

    try {
      final response = await supabase
          .from('chat_sessions')
          .select()
          .eq('user_id', user.id)
          .order('created_at', ascending: false);

      log('[ChatHistory] Loaded ${response.length} chats for user ${user.id}');

      if (response.isNotEmpty) {
        final sessions = response.map((data) => ChatSessionHeader(
              id: data['id'],
              title: data['title'],
            )).toList();

        state = state.copyWith(
          sessions: sessions,
          activeSessionId: sessions.first.id, // Set most recent chat as active
        );
      } else {
        startNewChat(activate: true); // Create first chat if none exist
      }
    } catch (e) {
      log('[ChatHistory] Error loading chats: $e');
      // Start with empty state and create new chat
      if (state.sessions.isEmpty) {
        startNewChat(activate: true);
      }
    }
  }

  Future<String> startNewChat({bool activate = true}) async {
    final user = supabase.auth.currentUser;
    final newSessionId = _uuid.v4();
    final newSessionHeader = ChatSessionHeader(id: newSessionId, title: 'New Chat');

    try {
      if (user != null) {
        await supabase.from('chat_sessions').insert({
          'id': newSessionId,
          'user_id': user.id,
          'title': 'New Chat',
          'created_at': DateTime.now().toIso8601String(),
        });
        log('[ChatHistory] Created new chat in Supabase: $newSessionId for user ${user.id}');
      }
    } catch (e) {
      log('[ChatHistory] Error creating chat in Supabase: $e');
    }

    final updatedSessions = [...state.sessions, newSessionHeader];
    state = state.copyWith(
      sessions: updatedSessions,
      activeSessionId: activate ? newSessionId : state.activeSessionId,
    );
    log('[ChatHistory] Started new chat locally: $newSessionId, Active: ${state.activeSessionId}');
    return newSessionId;
  }

  Future<void> updateSessionTitle(String sessionId, String newTitle) async {
    final user = supabase.auth.currentUser;
    final sessionIndex = state.sessions.indexWhere((s) => s.id == sessionId);
    
    if (sessionIndex != -1 && state.sessions[sessionIndex].title != newTitle) {
      try {
        if (user != null) {
          await supabase
              .from('chat_sessions')
              .update({'title': newTitle})
              .eq('id', sessionId)
              .eq('user_id', user.id);
          log('[ChatHistory] Updated chat title in Supabase: $sessionId to "$newTitle"');
        }

        final updatedSessions = List<ChatSessionHeader>.from(state.sessions);
        updatedSessions[sessionIndex] = updatedSessions[sessionIndex].copyWith(title: newTitle);
        state = state.copyWith(sessions: updatedSessions);
        log('[ChatHistory] Updated chat title locally: $sessionId to "$newTitle"');
      } catch (e) {
        log('[ChatHistory] Error updating chat title: $e');
      }
    }
  }

  Future<void> deleteSession(String sessionId) async {
    final user = supabase.auth.currentUser;
    
    try {
      if (user != null) {
        await supabase
            .from('chat_sessions')
            .delete()
            .eq('id', sessionId)
            .eq('user_id', user.id);
        log('[ChatHistory] Deleted chat from Supabase: $sessionId');
      }
    } catch (e) {
      log('[ChatHistory] Error deleting chat from Supabase: $e');
    }

    final updatedSessions = state.sessions.where((s) => s.id != sessionId).toList();
    String? newActiveSessionId = state.activeSessionId;

    if (newActiveSessionId == sessionId) {
      if (updatedSessions.isNotEmpty) {
        newActiveSessionId = updatedSessions.last.id;
      } else {
        newActiveSessionId = null;
      }
    }

    state = state.copyWith(
      sessions: updatedSessions,
      activeSessionId: newActiveSessionId,
      forceActiveNull: newActiveSessionId == null && state.activeSessionId == sessionId,
    );
    log('[ChatHistory] Deleted chat locally: $sessionId. New active: $newActiveSessionId');

    if (updatedSessions.isEmpty && newActiveSessionId == null) {
      startNewChat(activate: true);
    }
  }

  void setActiveSession(String sessionId) {
    if (state.sessions.any((s) => s.id == sessionId)) {
      log('[ChatHistory] Setting active session: $sessionId');
      state = state.copyWith(activeSessionId: sessionId);
    } else {
      log('[ChatHistory] Attempted to set non-existent session active: $sessionId');
    }
  }
}

// --- Chat History Provider ---
final chatHistoryProvider = StateNotifierProvider<ChatHistoryNotifier, ChatHistoryState>((ref) {
  return ChatHistoryNotifier();
});
