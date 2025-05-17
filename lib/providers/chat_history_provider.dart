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
  final List<ChatSessionHeader> sessions; // Includes pinned and active, excludes archived
  final List<ChatSessionHeader> archivedSessions; // Separate list for archived
  final String? activeSessionId;
  final bool isLoading;

  const ChatHistoryState({
    this.sessions = const [],
    this.archivedSessions = const [], // Initialize archived list
    this.activeSessionId,
    this.isLoading = false,
  });

  ChatHistoryState copyWith({
    List<ChatSessionHeader>? sessions,
    List<ChatSessionHeader>? archivedSessions, // Add archivedSessions
    String? activeSessionId,
    bool? isLoading,
    bool forceActiveNull = false,
  }) {
    return ChatHistoryState(
      sessions: sessions ?? this.sessions,
      archivedSessions: archivedSessions ?? this.archivedSessions, // Update archivedSessions
      activeSessionId: forceActiveNull ? null : activeSessionId ?? this.activeSessionId,
      isLoading: isLoading ?? this.isLoading,
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
      // Service now returns chats ordered by pinned, then created_at
      final allSessions = await _chatService.loadUserChats(user.id);

      if (!mounted) return;

      log('[ChatHistory] Loaded ${allSessions.length} chats for user ${user.id}');

      // Separate active/pinned from archived
      final activeAndPinnedSessions = allSessions.where((s) => !s.isArchived).toList();
      final archivedSessions = allSessions.where((s) => s.isArchived).toList();

      log('[ChatHistory] Found ${activeAndPinnedSessions.length} active/pinned and ${archivedSessions.length} archived sessions.'); // <-- ADDED LOG

      if (activeAndPinnedSessions.isNotEmpty) {
        final newActiveId = activeAndPinnedSessions.first.id; // <-- Store ID
        state = state.copyWith(
          sessions: activeAndPinnedSessions,
          archivedSessions: archivedSessions,
          activeSessionId: newActiveId, // <-- Use stored ID
          isLoading: false,
        );
        log('[ChatHistory] Set active session to: $newActiveId'); // <-- Use stored ID
      } else {
        log('[ChatHistory] No active/pinned sessions found.'); // <-- ADDED LOG
        // If only archived chats exist or no chats exist, start a new one
        if (mounted) {
          state = state.copyWith(
            isLoading: false,
            sessions: [], // Ensure main list is empty
            archivedSessions: archivedSessions, // Keep archived ones
            activeSessionId: null, // Explicitly null before starting new
          );
          log('[ChatHistory] State updated with empty sessions, activeSessionId is null.'); // <-- ADDED LOG
          // Only start a new chat if there are no archived ones either
          if (archivedSessions.isEmpty) {
             log('[ChatHistory] No archived sessions either, starting new chat.'); // <-- ADDED LOG
             await startNewChat(activate: true);
          } else {
             log('[ChatHistory] Archived sessions exist, not starting new chat automatically.'); // <-- ADDED LOG
          }
        }
      }
    } catch (e, stackTrace) {
      log('[ChatHistory] Error loading chats: $e'); // <-- Keep this
      log('[ChatHistory] Stack trace: $stackTrace'); // <-- Keep this
      if (mounted) {
        state = state.copyWith(isLoading: false, activeSessionId: null); // Ensure active ID is null on error before potentially starting new
        log('[ChatHistory] Error occurred, state updated. isLoading: false, activeSessionId: null.'); // <-- ADDED LOG
        // Start new chat only if there are absolutely no sessions loaded (active or archived)
        if (state.sessions.isEmpty && state.archivedSessions.isEmpty) {
          log('[ChatHistory] Starting new chat after error as no sessions exist.'); // <-- ADDED LOG
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
    // Fix: Add required isPinned and isArchived
    final newSessionHeader = ChatSessionHeader(
      id: newSessionId,
      title: 'New Chat',
      isPinned: false,
      isArchived: false,
    );

    final previousState = state;
    if (mounted) {
      // Add to the beginning of the main sessions list
      final updatedSessions = [newSessionHeader, ...state.sessions];
      final newActiveId = activate ? newSessionId : state.activeSessionId; // <-- Store ID
      state = state.copyWith(
        sessions: updatedSessions,
        activeSessionId: newActiveId, // <-- Use stored ID
      );
      log('[ChatHistory] Optimistically updated local state with new chat: $newSessionId. Active ID set to: $newActiveId'); // <-- UPDATED LOG
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
        state = previousState; // Revert optimistic update
      }
      rethrow;
    }
  }

  Future<void> updateSessionTitle(String sessionId, String newTitle) async {
    final user = supabase.auth.currentUser;
    // Check both active and archived lists
    final sessionIndex = state.sessions.indexWhere((s) => s.id == sessionId);
    final archivedSessionIndex = state.archivedSessions.indexWhere((s) => s.id == sessionId);

    if (sessionIndex != -1 || archivedSessionIndex != -1) {
      final previousState = state;
      List<ChatSessionHeader> updatedSessions = List.from(state.sessions);
      List<ChatSessionHeader> updatedArchivedSessions = List.from(state.archivedSessions);
      bool updated = false;

      if (sessionIndex != -1 && updatedSessions[sessionIndex].title != newTitle) {
         updatedSessions[sessionIndex] = updatedSessions[sessionIndex].copyWith(title: newTitle);
         updated = true;
      } else if (archivedSessionIndex != -1 && updatedArchivedSessions[archivedSessionIndex].title != newTitle) {
         updatedArchivedSessions[archivedSessionIndex] = updatedArchivedSessions[archivedSessionIndex].copyWith(title: newTitle);
         updated = true;
      }


      if (updated && mounted) {
        state = state.copyWith(sessions: updatedSessions, archivedSessions: updatedArchivedSessions);
        log('[ChatHistory] Optimistically updated local title for session: $sessionId');
      } else if (!mounted) {
         log('[ChatHistory] Not mounted, cannot update session title.');
         return;
      } else {
         // Title was already the same, no need to update
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
          state = previousState; // Revert optimistic update
        }
      }
    }
  }

  Future<void> deleteSession(String sessionId) async {
    final user = supabase.auth.currentUser;
    final previousState = state;

    // Remove from both lists
    final updatedSessions = state.sessions.where((s) => s.id != sessionId).toList();
    final updatedArchivedSessions = state.archivedSessions.where((s) => s.id != sessionId).toList();

    String? newActiveSessionId = state.activeSessionId;
    bool activeChanged = false;

    // If the deleted session was active, find a new active session from the updated main list
    if (newActiveSessionId == sessionId) {
      activeChanged = true;
      if (updatedSessions.isNotEmpty) {
        newActiveSessionId = updatedSessions.first.id; // Activate the first remaining non-archived
      } else {
        newActiveSessionId = null; // No active sessions left
      }
    }

    if (mounted) {
      state = state.copyWith(
        sessions: updatedSessions,
        archivedSessions: updatedArchivedSessions,
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
        // Fix: Use renamed service method
        await _chatService.deleteSession(sessionId, user.id);
      } else {
        log('[ChatHistory] No user logged in, cannot delete from Supabase');
      }

      // If deleting the last non-archived session, start a new one only if no archived exist
      if (mounted && state.sessions.isEmpty && state.activeSessionId == null) {
         if (state.archivedSessions.isEmpty) {
            await startNewChat(activate: true);
         }
      }

    } catch (e, stackTrace) {
      log('[ChatHistory] Error deleting chat: $e');
      log('[ChatHistory] Stack trace: $stackTrace');
      if (mounted) {
        state = previousState; // Revert optimistic update
      }
    }
  }

  // --- New Methods for Pinning and Archiving ---

  Future<void> pinSession(String sessionId, bool isPinned) async {
     final user = supabase.auth.currentUser;
     final sessionIndex = state.sessions.indexWhere((s) => s.id == sessionId);

     if (sessionIndex == -1 || user == null) {
        log('[ChatHistory] Cannot pin/unpin session $sessionId: Not found in active list or user not logged in.');
        return;
     }

     final previousState = state;
     final updatedSession = state.sessions[sessionIndex].copyWith(isPinned: isPinned);
     var updatedSessions = List<ChatSessionHeader>.from(state.sessions);
     updatedSessions[sessionIndex] = updatedSession;

     // Re-sort the list: Pinned first, then by creation date (descending - assumed from load)
     updatedSessions.sort((a, b) {
        if (a.isPinned && !b.isPinned) return -1;
        if (!a.isPinned && b.isPinned) return 1;
        // Keep original relative order for items with same pin status
        return 0;
     });


     if (mounted) {
        state = state.copyWith(sessions: updatedSessions);
        log('[ChatHistory] Optimistically updated pin status for session: $sessionId');
     } else {
        return;
     }

     try {
        await _chatService.updatePinStatus(sessionId, user.id, isPinned);
     } catch (e, stackTrace) {
        log('[ChatHistory] Error updating pin status: $e');
        log('[ChatHistory] Stack trace: $stackTrace');
        if (mounted) {
           state = previousState; // Revert
        }
     }
  }

  Future<void> archiveSession(String sessionId, bool isArchived) async {
     final user = supabase.auth.currentUser;
     if (user == null) {
        log('[ChatHistory] Cannot archive/unarchive session $sessionId: User not logged in.');
        return;
     }

     final previousState = state;
     List<ChatSessionHeader> updatedSessions = List.from(state.sessions);
     List<ChatSessionHeader> updatedArchivedSessions = List.from(state.archivedSessions);
     ChatSessionHeader? sessionToMove;
     String? newActiveSessionId = state.activeSessionId;
     bool activeChanged = false;

     if (isArchived) {
        // Archiving: Move from sessions to archivedSessions
        final sessionIndex = updatedSessions.indexWhere((s) => s.id == sessionId);
        if (sessionIndex != -1) {
           sessionToMove = updatedSessions.removeAt(sessionIndex).copyWith(isArchived: true, isPinned: false); // Unpin when archiving
           updatedArchivedSessions.insert(0, sessionToMove); // Add to start of archived

           // If archived session was active, pick a new active one
           if (state.activeSessionId == sessionId) {
              activeChanged = true;
              newActiveSessionId = updatedSessions.isNotEmpty ? updatedSessions.first.id : null;
           }
        } else {
           log('[ChatHistory] Session $sessionId not found in active list for archiving.');
           return; // Session not found or already archived
        }
     } else {
        // Unarchiving: Move from archivedSessions to sessions
        final sessionIndex = updatedArchivedSessions.indexWhere((s) => s.id == sessionId);
        if (sessionIndex != -1) {
           sessionToMove = updatedArchivedSessions.removeAt(sessionIndex).copyWith(isArchived: false);
           updatedSessions.insert(0, sessionToMove); // Add to start of active (will be sorted by pin later if needed)
           // Re-sort active sessions (pinned first)
           updatedSessions.sort((a, b) {
              if (a.isPinned && !b.isPinned) return -1;
              if (!a.isPinned && b.isPinned) return 1;
              return 0;
           });
           // Optionally activate the unarchived session
           // newActiveSessionId = sessionId;
           // activeChanged = true;
        } else {
           log('[ChatHistory] Session $sessionId not found in archived list for unarchiving.');
           return; // Session not found or already active
        }
     }

     if (mounted) {
        state = state.copyWith(
           sessions: updatedSessions,
           archivedSessions: updatedArchivedSessions,
           activeSessionId: newActiveSessionId,
           forceActiveNull: activeChanged && newActiveSessionId == null,
        );
        log('[ChatHistory] Optimistically updated archive status for session: $sessionId');
     } else {
        return;
     }

     try {
        // Update archive status in DB. Also update pin status if archiving (set to false).
        await _chatService.updateArchiveStatus(sessionId, user.id, isArchived);
        if (isArchived && sessionToMove.isPinned) { // Check sessionToMove is not null
           await _chatService.updatePinStatus(sessionId, user.id, false);
        }

        // Handle edge cases after DB update
        if (mounted) {
           // If unarchiving made the main list non-empty and no active session was set, activate the first one.
           if (!isArchived && state.sessions.isNotEmpty && state.activeSessionId == null) {
              state = state.copyWith(activeSessionId: state.sessions.first.id);
           }
           // If archiving removed the last active session, start a new one only if no archived exist.
           else if (isArchived && state.sessions.isEmpty && state.activeSessionId == null && state.archivedSessions.isEmpty) {
              await startNewChat(activate: true);
           }
        }

     } catch (e, stackTrace) {
        log('[ChatHistory] Error updating archive status: $e');
        log('[ChatHistory] Stack trace: $stackTrace');
        if (mounted) {
           state = previousState; // Revert
        }
     }
  }


  // --- End New Methods ---

  void setActiveSession(String sessionId) {
    // Allow setting active only if it's in the main 'sessions' list (not archived)
    if (state.sessions.any((s) => s.id == sessionId)) {
      if (state.activeSessionId != sessionId) {
        log('[ChatHistory] Setting active session: $sessionId');
        if (mounted) {
          state = state.copyWith(activeSessionId: sessionId);
        }
      }
    } else {
      log('[ChatHistory] Attempted to set non-existent or archived session active: $sessionId');
      // If the current active ID is invalid (not in sessions), reset it
      if (mounted && state.activeSessionId == sessionId) {
         state = state.copyWith(activeSessionId: state.sessions.isNotEmpty ? state.sessions.first.id : null);
      }
    }
  }
}
