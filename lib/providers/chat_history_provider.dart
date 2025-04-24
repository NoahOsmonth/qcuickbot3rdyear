import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'dart:developer';
import '../models/chat_session.dart';

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
    // Initialize with one default chat if no history exists (implement loading later)
    if (state.sessions.isEmpty) {
      startNewChat(activate: true); // Start and activate the first chat
    }
  }

  // Creates a new session, adds it to the list, and optionally activates it
  String startNewChat({bool activate = true}) {
    final newSessionId = _uuid.v4();
    final newSessionHeader = ChatSessionHeader(id: newSessionId, title: 'New Chat');
    final updatedSessions = [...state.sessions, newSessionHeader];

    state = state.copyWith(
      sessions: updatedSessions,
      activeSessionId: activate ? newSessionId : state.activeSessionId,
    );
    log('Started new chat: $newSessionId, Active: ${state.activeSessionId}');
    return newSessionId; // Return the ID for potential immediate use
  }

  void setActiveSession(String sessionId) {
    if (state.sessions.any((s) => s.id == sessionId)) {
       log('Setting active session: $sessionId');
      state = state.copyWith(activeSessionId: sessionId);
    } else {
       log('Attempted to set non-existent session active: $sessionId');
    }
  }

  void updateSessionTitle(String sessionId, String newTitle) {
    final sessionIndex = state.sessions.indexWhere((s) => s.id == sessionId);
    if (sessionIndex != -1 && state.sessions[sessionIndex].title != newTitle) {
      final updatedSessions = List<ChatSessionHeader>.from(state.sessions);
      updatedSessions[sessionIndex] = updatedSessions[sessionIndex].copyWith(title: newTitle);
      state = state.copyWith(sessions: updatedSessions);
       log('Updated title for session $sessionId to "$newTitle"');
    }
  }

  void deleteSession(String sessionId) {
    final updatedSessions = state.sessions.where((s) => s.id != sessionId).toList();

    // If the deleted session was the active one, activate another or none
    String? newActiveSessionId = state.activeSessionId;
    if (newActiveSessionId == sessionId) {
      if (updatedSessions.isNotEmpty) {
        // Activate the most recent remaining session
        newActiveSessionId = updatedSessions.last.id;
      } else {
        // No sessions left, set active to null (or start a new one immediately)
        newActiveSessionId = null; // Or call startNewChat() here if preferred
      }
    }

    state = state.copyWith(
      sessions: updatedSessions,
      activeSessionId: newActiveSessionId,
      forceActiveNull: newActiveSessionId == null && state.activeSessionId == sessionId, // Ensure null is set if needed
    );
     log('Deleted session: $sessionId. New active: $newActiveSessionId');

     // If no sessions are left after deletion, create a new one
     if (updatedSessions.isEmpty && newActiveSessionId == null) {
       startNewChat(activate: true);
     }
  }
}

// --- Chat History Provider ---
final chatHistoryProvider = StateNotifierProvider<ChatHistoryNotifier, ChatHistoryState>((ref) {
  return ChatHistoryNotifier();
});
