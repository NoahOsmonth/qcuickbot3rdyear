import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/chat_message.dart';
import '../widgets/avatar_bubble.dart';
import '../widgets/chat_input_bar.dart';
import '../services/gemini_service.dart';
import '../theme/app_theme.dart';
import 'dart:developer';

// --- State Definition ---
@immutable // Good practice for state classes
class ChatState {
  final List<ChatMessage> messages;
  final bool isLoading;

  const ChatState({this.messages = const [], this.isLoading = false});

  ChatState copyWith({List<ChatMessage>? messages, bool? isLoading}) {
    return ChatState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

// --- State Notifier ---
class ChatNotifier extends StateNotifier<ChatState> {
  final Ref ref;
  // Store the GeminiService instance obtained via ref
  final GeminiService _geminiService;

  // Pass ref to the constructor and read the GeminiService provider
  ChatNotifier(this.ref)
    : _geminiService = ref.read(geminiServiceProvider),
      super(const ChatState()); // Initial state

  Future<void> sendMessage(String text) async {
    if (text.isEmpty) return;

    final userMessage = ChatMessage(text: text, isUser: true);

    // Update state: add user message and set loading true
    state = state.copyWith(
      messages: [...state.messages, userMessage],
      isLoading: true,
    );

    try {
      // Use the injected GeminiService instance
      final responseText = await _geminiService.sendMessage(text);
      final botMessage = ChatMessage(text: responseText, isUser: false);

      // Update state: add bot message and set loading false
      state = state.copyWith(
        messages: [...state.messages, botMessage],
        isLoading: false,
      );
    } catch (e) {
      log('Error sending message: $e');
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

// --- Provider Definition ---
final chatProvider = StateNotifierProvider<ChatNotifier, ChatState>((ref) {
  return ChatNotifier(ref);
});

// --- UI Widget ---
// Change StatefulWidget to ConsumerStatefulWidget
class ChatScreen extends ConsumerStatefulWidget {
  @override
  // Change State to ConsumerState
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

// Change State to ConsumerState<ChatScreen>
class _ChatScreenState extends ConsumerState<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // Remove local state variables for messages and loading
  // List<ChatMessage> _messages = [];
  // bool _isLoading = false;

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Watch the provider to get the current state
    final chatState = ref.watch(chatProvider);
    final messages = chatState.messages;
    final isLoading = chatState.isLoading;

    // Listen to changes in the chat state, specifically the messages list
    ref.listen<ChatState>(chatProvider, (previousState, newState) {
      // Check if the number of messages has changed
      if (previousState?.messages.length != newState.messages.length) {
        // Schedule scroll after the frame renders
        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
      }
    });

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          'QCUIckBot',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        elevation: 0,
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: AppColors.sidebarCard),
              child: Text(
                'QCUIckBot',
                style: TextStyle(color: Colors.white, fontSize: 24),
              ),
            ),
            ListTile(
              leading: Icon(Icons.chat),
              title: Text('Home'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: Icon(Icons.settings),
              title: Text('Settings'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/settings');
              },
            ),
          ],
        ),
      ),
      body: Container(
        color: AppColors.mainBackground,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 12.0, bottom: 8.0),
              child: Text(
                'Today',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                reverse: false,
                padding: EdgeInsets.symmetric(horizontal: 8.0),
                itemCount:
                    messages.length +
                    (isLoading ? 1 : 0), // Add 1 for loading indicator
                itemBuilder: (context, index) {
                  if (isLoading && index == messages.length) {
                    // Show loading indicator at the bottom using AvatarBubble
                    return Center(
                      child: Padding(
                        padding: EdgeInsets.all(8.0),
                        // Create a dummy bot message for the thinking indicator
                        child: AvatarBubble(
                          message: ChatMessage(
                            text: '...',
                            isUser: false,
                            type: MessageType.text,
                          ),
                          isThinking: true,
                        ),
                      ),
                    );
                  }
                  final message = messages[index];

                  // Check if the message type is quickReplies
                  if (message.type == MessageType.quickReplies &&
                      message.quickReplies != null) {
                    // Render the quick reply buttons
                    return Padding(
                      padding: const EdgeInsets.only(
                        left: 50.0,
                        top: 4.0,
                        bottom: 4.0,
                      ), // Indent replies slightly
                      child: Wrap(
                        // Use Wrap for better spacing if buttons overflow
                        spacing: 8.0, // Horizontal space between buttons
                        runSpacing: 4.0, // Vertical space if they wrap
                        children:
                            message.quickReplies!
                                .map(
                                  (reply) => ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      // Define button style (consider moving to theme)
                                      backgroundColor: AppColors.botBubble,
                                      foregroundColor: AppColors.bubbleText,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(18),
                                        side: BorderSide(
                                          color: AppColors.sidebarCard,
                                        ),
                                      ),
                                      elevation: 1,
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 8,
                                      ),
                                    ),
                                    onPressed: () {
                                      // Send the reply using the notifier
                                      ref
                                          .read(chatProvider.notifier)
                                          .sendMessage(reply);
                                    },
                                    child: Text(reply),
                                  ),
                                )
                                .toList(),
                      ),
                    );
                  } else {
                    // Otherwise, render the standard AvatarBubble for text messages
                    return AvatarBubble(message: message);
                  }
                },
              ),
            ),
            ChatInputBar(
              controller: _controller,
              onSend: () {
                final text = _controller.text;
                _controller.clear();
                // Read the notifier and call the method to send message
                ref.read(chatProvider.notifier).sendMessage(text);
                // No need to call _scrollToBottom here, build method handles it
              },
              isLoading: isLoading, // Pass the isLoading state here
            ),
          ],
        ),
      ),
    );
  }
}
