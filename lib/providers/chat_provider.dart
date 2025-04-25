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
    if (_isInitialized) return;

    final user = supabase.auth.currentUser;
    if (user == null) {
      log('[Chat] No user logged in, skipping message loading for session: $sessionId');
      return;
    }

    try {
      log('[Chat] Starting to load messages for session: $sessionId');
      final response = await supabase
          .from('chat_messages')
          .select()
          .eq('session_id', sessionId)
          .eq('user_id', user.id)
          .order('created_at');

      if (!mounted) return;

      final messages = response.map((data) => ChatMessage(
            text: data['content'],
            isUser: data['is_user'],
          )).toList();

      log('[Chat] Successfully loaded ${messages.length} messages for session: $sessionId');
      
      state = state.copyWith(messages: messages);
      _isInitialized = true;
    } catch (e) {
      log('[Chat] Error loading messages for session $sessionId: $e');
      _isInitialized = false;
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

    // Update state with user message
    state = state.copyWith(
      messages: [...state.messages, userMessage],
      isLoading: true,
    );  

    // Save user message
    await _saveMessage(userMessage);
    log('[Chat] User message sent and saved in session: $sessionId');

    // Update session title if it's the first user message
    if (state.messages.where((m) => m.isUser).length == 1) {
      final historyNotifier = ref.read(chatHistoryProvider.notifier);
      final historyState = ref.read(chatHistoryProvider);
      // Check both active and archived lists for the session
      final currentSession = historyState.sessions.firstWhere(
        (s) => s.id == sessionId,
        orElse: () => historyState.archivedSessions.firstWhere(
          (s) => s.id == sessionId,
          // Provide default values including the new fields
          orElse: () => const ChatSessionHeader(id: '', title: '', isPinned: false, isArchived: false),
        ),
      );
      if (currentSession.id.isNotEmpty && currentSession.title == 'New Chat') {
        await historyNotifier.updateSessionTitle(sessionId, text);
        log('[Chat] Updated session title for first message: $sessionId');
      }
    }

    try {
      final responseText = await _geminiService.sendMessage(state.messages, text);
      final botMessage = ChatMessage(text: responseText, isUser: false);

      // Update state with bot message
      if (mounted) {
        state = state.copyWith(
          messages: [...state.messages, botMessage],
          isLoading: false,
        );
      }

      // Save bot message
      await _saveMessage(botMessage);
      log('[Chat] Bot response saved in session: $sessionId');
    } catch (e, stackTrace) {
      log('[Chat] Error in session $sessionId: $e');
      log('[Chat] Stack trace: $stackTrace');
      
      final errorMessage = ChatMessage(
        text: 'Error: Could not get response.',
        isUser: false,
      );
      
      if (mounted) {
        state = state.copyWith(
          messages: [...state.messages, errorMessage],
          isLoading: false,
        );
      }
      
      await _saveMessage(errorMessage);
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
