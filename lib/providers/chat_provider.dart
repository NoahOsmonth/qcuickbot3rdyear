import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'dart:developer';
import '../models/chat_message.dart';
import '../services/gemini_service.dart';
import 'chat_history_provider.dart'; // Import history provider
import '../models/chat_session.dart'; // Import ChatSessionHeader

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
      : _geminiService = ref.read(geminiServiceProvider), // Read GeminiService provider
        super(ChatState(sessionId: sessionId)); // Initial state requires sessionId

  Future<void> sendMessage(String text) async {
    if (text.isEmpty) return;

    final userMessage = ChatMessage(text: text, isUser: true);

    // Update state: add user message and set loading true
    state = state.copyWith(
      messages: [...state.messages, userMessage],
      isLoading: true,
    );

    // Update session title if it's the first user message and title is "New Chat"
    if (state.messages.where((m) => m.isUser).length == 1) {
       final historyNotifier = ref.read(chatHistoryProvider.notifier);
       // Check current title before updating
       // Use read to get the latest state directly
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
      // Use the injected GeminiService instance
      // Pass only the messages of the *current* session
      final responseText = await _geminiService.sendMessage(state.messages, text);
      final botMessage = ChatMessage(text: responseText, isUser: false);

      // Update state: add bot message and set loading false
      state = state.copyWith(
        messages: [...state.messages, botMessage],
        isLoading: false,
      );
    } catch (e) {
      log('Error sending message in session $sessionId: $e');
      final errorMessage = ChatMessage(
        text: 'Error: Could not get response.',
        isUser: false,
      );
      // Update state: add error message and set loading false
      state = state.copyWith(
        messages: [...state.messages, errorMessage],
        isLoading: false,
      );
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
