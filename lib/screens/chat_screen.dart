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
    // 1. Optimize watch: Select only the activeSessionId for rebuilds
    final activeSessionId = ref.watch(chatHistoryProvider.select((s) => s.activeSessionId));
    // Still need the full sessions list for AppBar title lookup, watch separately.
    final sessions = ref.watch(chatHistoryProvider).sessions;

    log('Building ChatScreen. History Active session ID: $activeSessionId');

    // If there's no active session ID, show loading/welcome
    if (activeSessionId == null) {
      log('ChatScreen: No active session ID found. Displaying loading indicator.');
      return Scaffold(
        appBar: AppBar(title: const Text('QCUIckBot')),
        drawer: _buildDrawer(context, sessions, null), // Pass current sessions
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    // Listen for message changes in the active session to scroll (doesn't cause rebuild)
    ref.listen<ChatState>(chatProvider(activeSessionId), (previousState, newState) {
      if (previousState?.messages.length != newState.messages.length) {
        _scrollToBottom();
      }
    });

    // Get the title for the AppBar from the sessions list
    final activeSessionHeader = sessions.firstWhere(
      (s) => s.id == activeSessionId,
      orElse: () => const ChatSessionHeader(id: '', title: 'Chat', isPinned: false, isArchived: false),
    );
    final activeSessionTitle = activeSessionHeader.title;

    // Build the main Scaffold structure (AppBar, Drawer) - this part won't rebuild on chat state changes
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          activeSessionTitle,
          style: const TextStyle(fontWeight: FontWeight.bold),
          overflow: TextOverflow.ellipsis,
        ),
        elevation: 0,
        actions: [
          NotificationIconButton(), // Assuming this is optimized or doesn't change often
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            tooltip: 'New Chat',
            onPressed: () {
              ref.read(chatHistoryProvider.notifier).startNewChat(activate: true);
            },
          ),
        ],
      ),
      drawer: _buildDrawer(context, sessions, activeSessionId), // Pass sessions and active ID
      body: Container(
        color: Theme.of(context).scaffoldBackgroundColor,
        // 2. Wrap the Column in a Consumer to scope the chatProvider watch
        child: Consumer(
          builder: (context, ref, child) {
            // Watch the active chat session state *inside* the Consumer
            log('ChatScreen Consumer: Watching chatProvider for session ID: $activeSessionId');
            final chatState = ref.watch(chatProvider(activeSessionId));
            final messages = chatState.messages;
            final isLoading = chatState.isLoading;
            log('ChatScreen Consumer: Received state for session $activeSessionId. isLoading: $isLoading, Message count: ${messages.length}');

            // This Column and its children will rebuild when chatState changes
            return Column(
              children: [
                Expanded(
                  child: messages.isEmpty && !isLoading
                      ? Center(
                          child: Text(
                          'Ask me anything!',
                          style: TextStyle(
                            color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6),
                            fontSize: 16
                          ),
                        ))
                      : ListView.builder(
                          controller: _scrollController,
                          reverse: false,
                          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 16.0),
                          itemCount: messages.length + (isLoading ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (isLoading && index == messages.length) {
                              // Show thinking indicator
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
                               return const SizedBox.shrink(); // Safeguard
                            }
                            final message = messages[index];
                            final theme = Theme.of(context);

                            // Quick replies
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
                                              backgroundColor: theme.cardColor,
                                              foregroundColor: theme.textTheme.bodyMedium?.color,
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(18),
                                                side: BorderSide(color: theme.dividerColor),
                                              ),
                                              elevation: 1,
                                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                            ),
                                            onPressed: () {
                                              // Use the activeSessionId from the outer scope
                                              ref.read(chatProvider(activeSessionId).notifier).sendMessage(reply);
                                            },
                                            child: Text(reply),
                                          ))
                                      .toList(),
                                ),
                              );
                            } else {
                              // Regular message bubble
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4.0),
                                // Use index as key since message has no stable ID
                                child: AvatarBubble(key: ValueKey(index), message: message),
                              );
                            }
                          },
                        ),
                ),
                // Chat Input Bar - rebuilds only when isLoading changes within the Consumer scope
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ChatInputBar(
                    controller: _controller,
                    isLoading: isLoading, // Pass isLoading from Consumer scope
                    onSend: () {
                      // Use activeSessionId from outer scope
                      ref.read(chatProvider(activeSessionId).notifier).sendMessage(_controller.text);
                      _controller.clear();
                      _scrollToBottom();
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // --- Helper Widgets ---

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
