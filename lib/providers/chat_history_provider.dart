import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'dart:developer';
import '../models/chat_session.dart';
import '../services/chat_session_service.dart';
import '../services/auth_service.dart';
import '../utils/supabase_client.dart';

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
  final bool isLoading; // Add loading state

  const ChatHistoryState({
    this.sessions = const [],
    this.activeSessionId,
    this.isLoading = false, // Default to false
  });

  ChatHistoryState copyWith({
    List<ChatSessionHeader>? sessions,
    String? activeSessionId,
    bool? isLoading, // Add isLoading
    bool forceActiveNull = false,
  }) {
    return ChatHistoryState(
      sessions: sessions ?? this.sessions,
      activeSessionId: forceActiveNull ? null : activeSessionId ?? this.activeSessionId,
      isLoading: isLoading ?? this.isLoading, // Update isLoading
    );
  }
}

class ChatHistoryNotifier extends StateNotifier<ChatHistoryState> {
  final Ref ref;
  final ChatSessionService _chatService = ChatSessionService();
  
  ChatHistoryNotifier(this.ref) : super(const ChatHistoryState()) {
    _initializeAuthListener();
    _loadUserChats();
  }

  void _initializeAuthListener() {
    ref.listen<AsyncValue<User?>>(authStateProvider, (previous, next) {
      final user = next.value;
      if (user == null) {
        clearState();
      } else if (previous?.value == null) {
        log('[ChatHistory] Auth state changed to logged in, triggering chat load.');
        _loadUserChats();
      }
    });
  }

  void clearState() {
    log('[ChatHistory] Clearing state');
    if (mounted) {
      state = const ChatHistoryState(); // Reset to initial state
    }
  }
  Future<void> _loadUserChats() async {
    if (state.isLoading) {
       log('[ChatHistory] Already loading chats, skipping.');
       return;
    }

    final user = supabase.auth.currentUser;
    if (user == null) {
      log('[ChatHistory] No user logged in, ensuring state is clear.');
      if (mounted) {
         state = const ChatHistoryState();
      }
      return;
    }

    if (mounted) {
      state = state.copyWith(isLoading: true);
    }

    try {
      log('[ChatHistory] Loading chats for user: ${user.id}');
      final sessions = await _chatService.loadUserChats(user.id);

      if (!mounted) return;

      log('[ChatHistory] Loaded ${sessions.length} chats for user ${user.id}');

      if (sessions.isNotEmpty) {
        state = state.copyWith(
          sessions: sessions,
          activeSessionId: sessions.first.id,
          isLoading: false,
        );
        log('[ChatHistory] Set active session to: ${sessions.first.id}');
      } else {
        if (mounted) {
            state = state.copyWith(isLoading: false);
            await startNewChat(activate: true);
        }
      }
    } catch (e, stackTrace) {
      log('[ChatHistory] Error loading chats: $e');
      log('[ChatHistory] Stack trace: $stackTrace');
      if (mounted) {
        state = state.copyWith(isLoading: false);
        if (state.sessions.isEmpty) {
          await startNewChat(activate: true);
        }
      }
    } finally {
       if (mounted && state.isLoading) {
          state = state.copyWith(isLoading: false);
       }
    }
  }
  Future<String> startNewChat({bool activate = true}) async {
    final user = supabase.auth.currentUser;
    if (user == null) {
       log('[ChatHistory] Cannot start new chat, no user logged in.');
       return '';
    }
    
    final newSessionId = _uuid.v4();
    final newSessionHeader = ChatSessionHeader(id: newSessionId, title: 'New Chat');

    final previousState = state;
    if (mounted) {
       final updatedSessions = [newSessionHeader, ...state.sessions];
       state = state.copyWith(
         sessions: updatedSessions,
         activeSessionId: activate ? newSessionId : state.activeSessionId,
       );
       log('[ChatHistory] Optimistically updated local state with new chat: $newSessionId');
    } else {
        log('[ChatHistory] Not mounted, cannot start new chat.');
        return '';
    }

    try {
      await _chatService.createNewChat(newSessionId, user.id);
      return newSessionId;
    } catch (e, stackTrace) {
      log('[ChatHistory] Error creating new chat: $e');
      log('[ChatHistory] Stack trace: $stackTrace');
      if (mounted) {
         state = previousState;
      }
      rethrow;
    }
  }
  Future<void> updateSessionTitle(String sessionId, String newTitle) async {
    final user = supabase.auth.currentUser;
    final sessionIndex = state.sessions.indexWhere((s) => s.id == sessionId);

    if (sessionIndex != -1 && state.sessions[sessionIndex].title != newTitle) {
      final previousState = state;
      final updatedSessions = List<ChatSessionHeader>.from(state.sessions);
      updatedSessions[sessionIndex] = updatedSessions[sessionIndex].copyWith(title: newTitle);

      if (mounted) {
        state = state.copyWith(sessions: updatedSessions);
        log('[ChatHistory] Optimistically updated local title for session: $sessionId');
      } else {
         log('[ChatHistory] Not mounted, cannot update session title.');
         return;
      }

      try {
        if (user != null) {
          await _chatService.updateChatTitle(sessionId, user.id, newTitle);
        } else {
          log('[ChatHistory] No user logged in, cannot update title in Supabase');
        }
      } catch (e, stackTrace) {
        log('[ChatHistory] Error updating chat title: $e');
        log('[ChatHistory] Stack trace: $stackTrace');
        if (mounted) {
          state = previousState;
        }
      }
    }
  }
  Future<void> deleteSession(String sessionId) async {
    final user = supabase.auth.currentUser;
    final previousState = state;

    final updatedSessions = state.sessions.where((s) => s.id != sessionId).toList();
    String? newActiveSessionId = state.activeSessionId;
    bool activeChanged = false;

    if (newActiveSessionId == sessionId) {
      activeChanged = true;
      if (updatedSessions.isNotEmpty) {
        newActiveSessionId = updatedSessions.first.id;
      } else {
        newActiveSessionId = null;
      }
    }

    if (mounted) {
      state = state.copyWith(
        sessions: updatedSessions,
        activeSessionId: newActiveSessionId,
        forceActiveNull: activeChanged && newActiveSessionId == null,
      );
      log('[ChatHistory] Optimistically deleted session locally: $sessionId');
    } else {
       log('[ChatHistory] Not mounted, cannot delete session.');
       return;
    }

    try {
      if (user != null) {
        await _chatService.deleteChat(sessionId, user.id);
      } else {
         log('[ChatHistory] No user logged in, cannot delete from Supabase');
      }

      if (mounted && state.sessions.isEmpty && state.activeSessionId == null) {
        await startNewChat(activate: true);
      }

    } catch (e, stackTrace) {
      log('[ChatHistory] Error deleting chat: $e');
      log('[ChatHistory] Stack trace: $stackTrace');
      if (mounted) {
        state = previousState;
      }
    }
  }

   void setActiveSession(String sessionId) {
    if (state.sessions.any((s) => s.id == sessionId)) {
      if (state.activeSessionId != sessionId) {
         log('[ChatHistory] Setting active session: $sessionId');
         if (mounted) {
            state = state.copyWith(activeSessionId: sessionId);
         }
      }
    } else {
      log('[ChatHistory] Attempted to set non-existent session active: $sessionId');
      // Optionally, if the active session ID is somehow invalid, reset it
      if (mounted && state.activeSessionId == sessionId) {
         state = state.copyWith(activeSessionId: state.sessions.isNotEmpty ? state.sessions.first.id : null);
      }
    }
  }
}
