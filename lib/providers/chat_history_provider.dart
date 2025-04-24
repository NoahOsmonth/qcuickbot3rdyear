import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'dart:developer';
import '../models/chat_session.dart';
import '../utils/supabase_client.dart';
import '../services/auth_service.dart';

// --- Provider ---
final StateNotifierProvider<ChatHistoryNotifier, ChatHistoryState> chatHistoryProvider =
    StateNotifierProvider<ChatHistoryNotifier, ChatHistoryState>((ref) {
  return ChatHistoryNotifier(ref);
});

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
    bool forceActiveNull = false,
  }) {
    return ChatHistoryState(
      sessions: sessions ?? this.sessions,
      activeSessionId: forceActiveNull ? null : activeSessionId ?? this.activeSessionId,
    );
  }
}

class ChatHistoryNotifier extends StateNotifier<ChatHistoryState> {
  final Ref ref;
  ChatHistoryNotifier(this.ref) : super(const ChatHistoryState()) {
    // Listen to auth state changes
    ref.listen(authStateProvider, (previous, next) {
      next.whenData((user) {
        if (user == null) {
          // Clear history when user logs out
          clearState();
        }
      });
    });
    _loadUserChats();
  }

  bool _isLoading = false;

  void clearState() {
    log('[ChatHistory] Clearing state');
    state = const ChatHistoryState();
    _isLoading = false;
  }

  Future<void> _loadUserChats() async {
    if (_isLoading) return;
    _isLoading = true;

    final user = supabase.auth.currentUser;
    if (user == null) {
      log('[ChatHistory] No user logged in, skipping chat loading');
      _isLoading = false;
      return;
    }

    try {
      log('[ChatHistory] Loading chats for user: ${user.id}');
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

        if (mounted) {
          state = state.copyWith(
            sessions: sessions,
            activeSessionId: sessions.first.id,
          );
        }
        log('[ChatHistory] Set active session to: ${sessions.first.id}');
      } else {
        log('[ChatHistory] No existing chats found, creating new chat');
        if (mounted) {
          startNewChat(activate: true);
        }
      }
    } catch (e, stackTrace) {
      log('[ChatHistory] Error loading chats: $e');
      log('[ChatHistory] Stack trace: $stackTrace');
      // Start with empty state and create new chat
      if (mounted && state.sessions.isEmpty) {
        startNewChat(activate: true);
      }
    } finally {
      _isLoading = false;
    }
  }

  Future<String> startNewChat({bool activate = true}) async {
    final user = supabase.auth.currentUser;
    final newSessionId = _uuid.v4();
    final newSessionHeader = ChatSessionHeader(id: newSessionId, title: 'New Chat');

    try {
      if (user != null) {
        log('[ChatHistory] Creating new chat in Supabase: $newSessionId for user ${user.id}');
        await supabase.from('chat_sessions').insert({
          'id': newSessionId,
          'user_id': user.id,
          'title': 'New Chat',
          'created_at': DateTime.now().toIso8601String(),
        });
        log('[ChatHistory] Successfully created chat in Supabase');
      }

      if (mounted) {
        final updatedSessions = [...state.sessions, newSessionHeader];
        state = state.copyWith(
          sessions: updatedSessions,
          activeSessionId: activate ? newSessionId : state.activeSessionId,
        );
      }
      log('[ChatHistory] Updated local state with new chat: $newSessionId');
      return newSessionId;
    } catch (e, stackTrace) {
      log('[ChatHistory] Error creating new chat: $e');
      log('[ChatHistory] Stack trace: $stackTrace');
      rethrow;
    }
  }

  Future<void> updateSessionTitle(String sessionId, String newTitle) async {
    final user = supabase.auth.currentUser;
    final sessionIndex = state.sessions.indexWhere((s) => s.id == sessionId);
    
    if (sessionIndex != -1 && state.sessions[sessionIndex].title != newTitle) {
      try {
        if (user != null) {
          log('[ChatHistory] Updating chat title in Supabase: $sessionId');
          await supabase
              .from('chat_sessions')
              .update({'title': newTitle})
              .eq('id', sessionId)
              .eq('user_id', user.id);
          log('[ChatHistory] Successfully updated chat title in Supabase');
        }

        if (mounted) {
          final updatedSessions = List<ChatSessionHeader>.from(state.sessions);
          updatedSessions[sessionIndex] = updatedSessions[sessionIndex].copyWith(title: newTitle);
          state = state.copyWith(sessions: updatedSessions);
        }
        log('[ChatHistory] Updated local state with new title for session: $sessionId');
      } catch (e, stackTrace) {
        log('[ChatHistory] Error updating chat title: $e');
        log('[ChatHistory] Stack trace: $stackTrace');
      }
    }
  }

  Future<void> deleteSession(String sessionId) async {
    final user = supabase.auth.currentUser;
    
    try {
      if (user != null) {
        log('[ChatHistory] Deleting chat from Supabase: $sessionId');
        await supabase
            .from('chat_sessions')
            .delete()
            .eq('id', sessionId)
            .eq('user_id', user.id);
        log('[ChatHistory] Successfully deleted chat from Supabase');
      }

      final updatedSessions = state.sessions.where((s) => s.id != sessionId).toList();
      String? newActiveSessionId = state.activeSessionId;

      if (newActiveSessionId == sessionId) {
        if (updatedSessions.isNotEmpty) {
          newActiveSessionId = updatedSessions.last.id;
          log('[ChatHistory] Setting new active session: $newActiveSessionId');
        } else {
          newActiveSessionId = null;
          log('[ChatHistory] No sessions left after deletion');
        }
      }

      if (mounted) {
        state = state.copyWith(
          sessions: updatedSessions,
          activeSessionId: newActiveSessionId,
          forceActiveNull: newActiveSessionId == null && state.activeSessionId == sessionId,
        );
      }

      if (updatedSessions.isEmpty && newActiveSessionId == null) {
        log('[ChatHistory] Creating new chat after deleting last one');
        await startNewChat(activate: true);
      }
    } catch (e, stackTrace) {
      log('[ChatHistory] Error deleting chat: $e');
      log('[ChatHistory] Stack trace: $stackTrace');
    }
  }

  void setActiveSession(String sessionId) {
    if (mounted) {
      state = state.copyWith(activeSessionId: sessionId);
      log('[ChatHistory] Set active session to: $sessionId');
    }
  }
}
