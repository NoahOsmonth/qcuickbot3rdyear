import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'dart:developer';
import '../models/chat_message.dart';
import '../services/gemini_service.dart';
import 'chat_history_provider.dart';
import '../models/chat_session.dart';
import '../utils/supabase_client.dart';

// Provider for GeminiService (assuming it's defined elsewhere)
// If not, define or import GeminiService here
final geminiServiceProvider = Provider<GeminiService>((ref) => GeminiService());

// --- Single Chat Session State ---
@immutable // Good practice for state classes
class ChatState {
  final List<ChatMessage> messages;
  final bool isLoading;
  final String sessionId; // Keep track of which session this state belongs to

  const ChatState({
    required this.sessionId,
    this.messages = const [],
    this.isLoading = false,
  });

  ChatState copyWith({
    List<ChatMessage>? messages,
    bool? isLoading,
    // sessionId should not change
  }) {
    return ChatState(
      sessionId: sessionId, // Keep the original sessionId
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

// --- Single Chat Session Notifier ---
// Needs the session ID it's responsible for
class ChatNotifier extends StateNotifier<ChatState> {
  final Ref ref;
  final String sessionId;
  final GeminiService _geminiService;

  ChatNotifier(this.ref, this.sessionId)
      : _geminiService = ref.read(geminiServiceProvider),
        super(ChatState(sessionId: sessionId)) {
    // Load existing messages for this session
    _loadMessages();
  }

  Future<void> _loadMessages() async {
    final user = supabase.auth.currentUser;
    if (user == null) {
      log('[Chat] No user logged in, skipping message loading for session: $sessionId');
      return;
    }

    try {
      final response = await supabase
          .from('chat_messages')
          .select()
          .eq('session_id', sessionId)
          .eq('user_id', user.id)
          .order('created_at');

      log('[Chat] Loaded ${response.length} messages for session: $sessionId');

      final messages = response.map((data) => ChatMessage(
            text: data['content'],
            isUser: data['is_user'],
          )).toList();

      state = state.copyWith(messages: messages);
    } catch (e) {
      log('[Chat] Error loading messages for session $sessionId: $e');
    }
  }

  Future<void> _saveMessage(ChatMessage message) async {
    final user = supabase.auth.currentUser;
    if (user == null) {
      log('[Chat] No user logged in, skipping message save for session: $sessionId');
      return;
    }

    try {
      await supabase.from('chat_messages').insert({
        'session_id': sessionId,
        'user_id': user.id,
        'content': message.text,
        'is_user': message.isUser,
        'created_at': DateTime.now().toIso8601String(),
      });
      log('[Chat] Saved ${message.isUser ? "user" : "bot"} message in session: $sessionId');
    } catch (e) {
      log('[Chat] Error saving message in session $sessionId: $e');
    }
  }

  Future<void> sendMessage(String text) async {
    if (text.isEmpty) return;

    final userMessage = ChatMessage(text: text, isUser: true);

    // Update state and save user message
    state = state.copyWith(
      messages: [...state.messages, userMessage],
      isLoading: true,
    );
    await _saveMessage(userMessage);

    // Update session title if it's the first user message
    if (state.messages.where((m) => m.isUser).length == 1) {
      final historyNotifier = ref.read(chatHistoryProvider.notifier);
      final historyState = ref.read(chatHistoryProvider);
      final currentSession = historyState.sessions.firstWhere(
        (s) => s.id == sessionId,
        orElse: () => ChatSessionHeader(id: '', title: ''),
      );
      if (currentSession.id.isNotEmpty && currentSession.title == 'New Chat') {
        historyNotifier.updateSessionTitle(sessionId, text);
      }
    }

    try {
      final responseText = await _geminiService.sendMessage(state.messages, text);
      final botMessage = ChatMessage(text: responseText, isUser: false);

      // Update state and save bot message
      state = state.copyWith(
        messages: [...state.messages, botMessage],
        isLoading: false,
      );
      await _saveMessage(botMessage);
    } catch (e) {
      log('[Chat] Error sending message in session $sessionId: $e');
      final errorMessage = ChatMessage(
        text: 'Error: Could not get response.',
        isUser: false,
      );
      state = state.copyWith(
        messages: [...state.messages, errorMessage],
        isLoading: false,
      );
      await _saveMessage(errorMessage); // Save error message too
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
