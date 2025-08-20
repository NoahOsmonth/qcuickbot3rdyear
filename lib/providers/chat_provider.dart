import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'dart:developer';
import '../models/chat_message.dart';
import '../services/gemini_service.dart';
import 'chat_history_provider.dart';
import '../models/chat_session.dart';
import '../utils/supabase_client.dart';
import '../services/auth_service.dart';

// Provider for GeminiService
final geminiServiceProvider = Provider<GeminiService>((ref) => GeminiService());

@immutable
class ChatState {
  final List<ChatMessage> messages;
  final bool isLoading;
  final String sessionId;

  const ChatState({
    required this.sessionId,
    this.messages = const [],
    this.isLoading = false,
  });

  ChatState copyWith({
    List<ChatMessage>? messages,
    bool? isLoading,
  }) {
    return ChatState(
      sessionId: sessionId,
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class ChatNotifier extends StateNotifier<ChatState> {
  final Ref ref;
  final String sessionId;
  final GeminiService _geminiService;
  bool _isInitialized = false;

  ChatNotifier(this.ref, this.sessionId)
      : _geminiService = ref.read(geminiServiceProvider),
        super(ChatState(sessionId: sessionId)) {
    _loadMessages();

    // Listen to auth state changes
    ref.listen(authStateProvider, (previous, next) {
      next.whenData((user) {
        if (user == null) {
          // Clear messages when user logs out
          _clearState();
        } else {
          // Reload messages when user logs in
          _loadMessages();
        }
      });
    });
  }

  void _clearState() {
    if (mounted) {
      state = ChatState(sessionId: sessionId);
      _isInitialized = false;
      log('[Chat] Cleared chat state for session: $sessionId');
    }
  }

  Future<void> _loadMessages() async {
    log('[ChatNotifier $sessionId] _loadMessages called. _isInitialized: $_isInitialized'); // <-- ADDED LOG
    if (_isInitialized) {
       log('[ChatNotifier $sessionId] Already initialized, skipping load.'); // <-- ADDED LOG
       return;
    }

    final user = supabase.auth.currentUser;
    if (user == null) {
      log('[ChatNotifier $sessionId] No user logged in, skipping message loading.'); // <-- UPDATED LOG
      return;
    }
    log('[ChatNotifier $sessionId] User found: ${user.id}. Proceeding to load messages.'); // <-- ADDED LOG

    // Set loading state immediately before the async call
    if (mounted) {
        state = state.copyWith(isLoading: true);
        log('[ChatNotifier $sessionId] Set isLoading = true');
    }


    try {
      log('[ChatNotifier $sessionId] Starting Supabase query for messages.'); // <-- UPDATED LOG
      final response = await supabase
          .from('chat_messages')
          .select()
          .eq('session_id', sessionId)
          .eq('user_id', user.id)
          .order('created_at', ascending: true);

      log('[ChatNotifier $sessionId] Supabase query completed.'); // <-- ADDED LOG

      if (!mounted) {
         log('[ChatNotifier $sessionId] Not mounted after query, returning.'); // <-- ADDED LOG
         return;
      }

      final messages = response.map((data) => ChatMessage(
            text: data['content'],
            isUser: data['is_user'],
          )).toList();

      log('[ChatNotifier $sessionId] Successfully loaded ${messages.length} messages.'); // <-- UPDATED LOG

      state = state.copyWith(messages: messages, isLoading: false); // Set isLoading false on success
      _isInitialized = true;
      log('[ChatNotifier $sessionId] State updated with messages. isLoading: false, _isInitialized: true'); // <-- ADDED LOG
    } catch (e, stackTrace) { // <-- ADDED stackTrace
      log('[ChatNotifier $sessionId] Error loading messages: $e'); // <-- UPDATED LOG
      log('[ChatNotifier $sessionId] Stack trace: $stackTrace'); // <-- ADDED LOG
      if (mounted) {
          state = state.copyWith(isLoading: false); // Set isLoading false on error too
          log('[ChatNotifier $sessionId] State updated after error. isLoading: false'); // <-- ADDED LOG
      }
      _isInitialized = false; // Keep false on error? Or set true to prevent retries? Let's keep false for now.
    }
  }

  Future<void> _saveMessage(ChatMessage message) async {
    final user = supabase.auth.currentUser;
    if (user == null) {
      log('[Chat] No user logged in, skipping message save for session: $sessionId');
      return;
    }

    try {
      log('[Chat] Saving ${message.isUser ? "user" : "bot"} message in session: $sessionId');
      await supabase.from('chat_messages').insert({
        'session_id': sessionId,
        'user_id': user.id,
        'content': message.text,
        'is_user': message.isUser,
        'created_at': DateTime.now().toIso8601String(),
      });
      log('[Chat] Successfully saved message in session: $sessionId');
    } catch (e, stackTrace) {
      log('[Chat] Error saving message in session $sessionId: $e');
      log('[Chat] Stack trace: $stackTrace');
    }
  }

  Future<void> sendMessage(String text) async {
    if (text.isEmpty) return;

    final userMessage = ChatMessage(text: text, isUser: true);

    // Update state optimistically and set loading true
    state = state.copyWith(
      messages: [...state.messages, userMessage],
      isLoading: true,
    );
    log('[ChatNotifier $sessionId] User message added optimistically. isLoading: true');

    try {
      // Save user message
      await _saveMessage(userMessage);
      log('[ChatNotifier $sessionId] User message saved.');

      // Update session title if it's the first user message
      if (state.messages.where((m) => m.isUser).length == 1) {
        final historyNotifier = ref.read(chatHistoryProvider.notifier);
        final historyState = ref.read(chatHistoryProvider);
        final currentSession = historyState.sessions.firstWhere(
          (s) => s.id == sessionId,
          orElse: () => historyState.archivedSessions.firstWhere(
            (s) => s.id == sessionId,
            orElse: () => const ChatSessionHeader(id: '', title: '', isPinned: false, isArchived: false),
          ),
        );
        if (currentSession.id.isNotEmpty && currentSession.title == 'New Chat') {
          await historyNotifier.updateSessionTitle(sessionId, text);
          log('[Chat] Updated session title for first message: $sessionId');
        }
      }

      // --- Call Gemini Service ---
      try {
        log('[ChatNotifier $sessionId] Calling Gemini service.');
        final responseText = await _geminiService.sendMessage(text);
        final botMessage = ChatMessage(text: responseText, isUser: false);
        log('[ChatNotifier $sessionId] Gemini response received.');

        // Update state with bot message (isLoading will be set false in finally)
        if (mounted) {
          state = state.copyWith(
            messages: [...state.messages, botMessage],
            // isLoading: false, // Moved to finally
          );
          log('[ChatNotifier $sessionId] Bot message added.');
        }

        // Save bot message
        await _saveMessage(botMessage);
        log('[ChatNotifier $sessionId] Bot response saved.');

      } catch (e, stackTrace) {
        log('[ChatNotifier $sessionId] Error getting/saving bot response: $e');
        log('[ChatNotifier $sessionId] Stack trace: $stackTrace');

        final errorMessage = ChatMessage(
          text: 'Error: Could not get response.',
          isUser: false,
        );

        // Update state with error message (isLoading will be set false in finally)
        if (mounted) {
          state = state.copyWith(
            messages: [...state.messages, errorMessage],
            // isLoading: false, // Moved to finally
          );
          log('[ChatNotifier $sessionId] Error message added.');
        }
        await _saveMessage(errorMessage); // Save the error message
      }
      // --- End Gemini Service Call ---

    } finally {
      // Ensure isLoading is always set to false after processing
      if (mounted) {
        state = state.copyWith(isLoading: false);
        log('[ChatNotifier $sessionId] Final state update. isLoading: false');
      }
    }
  }
}

// --- Chat Provider (Family) ---
// Now a family, keyed by session ID (String)
final chatProvider = StateNotifierProvider.family<ChatNotifier, ChatState, String>((ref, sessionId) {
  log('Creating or obtaining ChatNotifier for session: $sessionId');
  // Pass ref and sessionId to the notifier
  return ChatNotifier(ref, sessionId);
});
