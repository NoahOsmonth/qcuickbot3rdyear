import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/chat_message.dart';
import '../widgets/avatar_bubble.dart';
import '../widgets/chat_input_bar.dart';
import '../services/gemini_service.dart'; // Keep for geminiServiceProvider
import '../theme/app_theme.dart';
import 'dart:developer';
import '../widgets/drawer/chat_history_list.dart';
import '../widgets/drawer/drawer_header.dart';
import '../widgets/drawer/settings_tile.dart';
import '../providers/chat_provider.dart'; // Import chat provider
import '../providers/chat_history_provider.dart'; // Import history provider
import '../models/chat_session.dart'; // Import session header model
import '../widgets/notification_icon_button.dart';

// Keep Gemini Service Provider here or move to a dedicated services/providers file
final geminiServiceProvider = Provider<GeminiService>((ref) => GeminiService());

// --- UI Widget ---
class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    // Debounce or delay slightly to ensure layout is complete
    Future.delayed(const Duration(milliseconds: 50), () {
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
    // Get active session ID and the list of all sessions
    final historyState = ref.watch(chatHistoryProvider);
    final activeSessionId = historyState.activeSessionId;
    final sessions = historyState.sessions;

    log('Building ChatScreen. Active session: $activeSessionId');

    // If there's no active session (e.g., during init or error), handle gracefully
    if (activeSessionId == null) {
      log('No active session ID found. Displaying loading or empty state.');
      return Scaffold(
        appBar: AppBar(title: const Text('QCUIckBot')),
        drawer: _buildDrawer(context, sessions, null), // Pass null for activeSessionId
        body: const Center(child: CircularProgressIndicator()), // Or a welcome message
      );
    }

    // Watch the *specific* provider for the active session
    final chatState = ref.watch(chatProvider(activeSessionId));
    final messages = chatState.messages;
    final isLoading = chatState.isLoading;

    // Listen for changes in the active session's messages to scroll
    ref.listen<ChatState>(chatProvider(activeSessionId), (previousState, newState) {
      if (previousState?.messages.length != newState.messages.length) {
        _scrollToBottom();
      }
    });

    // Get the title for the AppBar from the history state
    // Ensure orElse provides a default ChatSessionHeader with all required fields
    final activeSessionHeader = sessions.firstWhere(
      (s) => s.id == activeSessionId,
      orElse: () => const ChatSessionHeader(id: '', title: 'Chat', isPinned: false, isArchived: false), // Provide defaults
    );
    final activeSessionTitle = activeSessionHeader.title;


    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          activeSessionTitle, // Use dynamic title
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          overflow: TextOverflow.ellipsis, // Handle long titles
        ),
        elevation: 0,
        actions: [
          NotificationIconButton(),
          IconButton(
            icon: const Icon(Icons.add_circle_outline, color: Colors.white),
            tooltip: 'New Chat',
            onPressed: () {
              ref.read(chatHistoryProvider.notifier).startNewChat(activate: true);
              // No need to pop drawer here as it's in the AppBar
            },
          ),
        ],
      ),
      drawer: _buildDrawer(context, sessions, activeSessionId), // Pass sessions and active ID
      body: Container(
        color: AppColors.mainBackground,
        child: Column(
          children: [
            // Removed 'Today' text for simplicity with history
            // Padding(
            //   padding: const EdgeInsets.only(top: 12.0, bottom: 8.0),
            //   child: Text(
            //     'Today',
            //     style: TextStyle(
            //       color: Colors.grey[600],
            //       fontWeight: FontWeight.w500,
            //     ),
            //   ),
            // ),
            Expanded(
              child: messages.isEmpty && !isLoading
                  ? Center(
                      child: Text(
                      'Ask me anything!',
                      style: TextStyle(color: Colors.grey[600], fontSize: 16),
                    ))
                  : ListView.builder(
                      controller: _scrollController,
                      reverse: false, // Keep false for natural chat flow
                      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 16.0), // Add vertical padding
                      itemCount: messages.length + (isLoading ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (isLoading && index == messages.length) {
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
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
                        if (index >= messages.length) {
                           // Should not happen with the check above, but safeguard
                           return const SizedBox.shrink();
                        }
                        final message = messages[index];

                        // Quick replies logic remains the same
                        if (message.type == MessageType.quickReplies &&
                            message.quickReplies != null) {
                          return Padding(
                            padding: const EdgeInsets.only(
                              left: 50.0, top: 4.0, bottom: 4.0),
                            child: Wrap(
                              spacing: 8.0,
                              runSpacing: 4.0,
                              children: message.quickReplies!
                                  .map((reply) => ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.botBubble,
                                          foregroundColor: AppColors.bubbleText,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(18),
                                            side: BorderSide(color: AppColors.sidebarCard),
                                          ),
                                          elevation: 1,
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                        ),
                                        onPressed: () {
                                          // Send reply using the *active* session's notifier
                                          ref.read(chatProvider(activeSessionId).notifier).sendMessage(reply);
                                        },
                                        child: Text(reply),
                                      ))
                                  .toList(),
                            ),
                          );
                        } else {
                          return AvatarBubble(message: message);
                        }
                      },
                    ),
            ),
            ChatInputBar(
              controller: _controller,
              onSend: () {
                final text = _controller.text;
                if (text.isNotEmpty) {
                  _controller.clear();
                  // Send message using the *active* session's notifier
                  ref.read(chatProvider(activeSessionId).notifier).sendMessage(text);
                }
              },
              isLoading: isLoading,
            ),
          ],
        ),
      ),
    );
  }

  // Helper method to build the drawer UI
  Widget _buildDrawer(BuildContext context, List<ChatSessionHeader> sessions, String? activeSessionId) {
    // final historyNotifier = ref.read(chatHistoryProvider.notifier); // Moved to ChatHistoryList

    return Drawer(
      child: Column( // Use Column for layout flexibility
        children: [
          // Use the extracted DrawerHeaderWidget
          const DrawerHeaderWidget(),
          const Divider(height: 1, thickness: 1),
          // Use the extracted ChatHistoryList widget (no parameters needed)
          const ChatHistoryList(),
          const Divider(height: 1, thickness: 1),
          // Use the extracted SettingsTile widget
          const SettingsTile(),
        ],
      ),
    );
  }
}
