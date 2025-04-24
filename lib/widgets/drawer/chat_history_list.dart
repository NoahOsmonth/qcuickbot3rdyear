import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/chat_message.dart'; // Assuming ChatSessionHeader is here or adjust path
import '../../models/chat_session.dart'; // Import ChatSessionHeader definition
import '../../screens/chat_screen.dart'; // For ChatSessionHeader (if needed)
import '../../theme/app_theme.dart';
import 'dart:developer'; // For log
import '../../providers/chat_history_provider.dart'; // Import chatHistoryProvider

class ChatHistoryList extends ConsumerWidget {
  final List<ChatSessionHeader> sessions;
  final String? activeSessionId;

  const ChatHistoryList({
    super.key,
    required this.sessions,
    required this.activeSessionId,
  });

  // --- Rename Dialog ---
  Future<void> _showRenameDialog(BuildContext context, WidgetRef ref, ChatSessionHeader session) async {
    final textController = TextEditingController(text: session.title);
    final formKey = GlobalKey<FormState>(); // For validation

    return showDialog<void>(
      context: context,
      barrierDismissible: true, // Allow dismissing by tapping outside
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Rename Chat'),
          content: Form( // Use a Form for potential validation
            key: formKey,
            child: TextFormField(
              controller: textController,
              autofocus: true,
              decoration: const InputDecoration(hintText: 'Enter new chat name'),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Name cannot be empty';
                }
                return null;
              },
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(dialogContext).pop(); // Close the dialog
              },
            ),
            TextButton(
              child: const Text('Rename'),
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  final newTitle = textController.text.trim();
                  if (newTitle.isNotEmpty && newTitle != session.title) {
                    ref.read(chatHistoryProvider.notifier).updateSessionTitle(session.id, newTitle);
                  }
                  Navigator.of(dialogContext).pop(); // Close the dialog
                }
              },
            ),
          ],
        );
      },
    );
  }

  // --- Delete Confirmation Dialog ---
  Future<void> _showDeleteConfirmationDialog(BuildContext context, WidgetRef ref, ChatSessionHeader session) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // User must explicitly confirm or cancel
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Delete Chat?'),
          content: Text('Are you sure you want to delete "${session.title}"? This action cannot be undone.'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(dialogContext).pop(); // Close the dialog
              },
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red), // Make delete more prominent
              child: const Text('Delete'),
              onPressed: () {
                ref.read(chatHistoryProvider.notifier).deleteSession(session.id);
                Navigator.of(dialogContext).pop(); // Close the dialog
                // No need to pop the drawer here as it was popped before showing the dialog
              },
            ),
          ],
        );
      },
    );
  }


  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyNotifier = ref.read(chatHistoryProvider.notifier);

    return Expanded( // Make the list scrollable
      child: ListView.builder(
        padding: EdgeInsets.zero, // Remove default padding
        itemCount: sessions.length,
        itemBuilder: (context, index) {
          // Display in reverse chronological order (newest first)
          final session = sessions[sessions.length - 1 - index];
          final isActive = session.id == activeSessionId;
          return ListTile(
            leading: Icon(Icons.chat_bubble_outline, color: isActive ? Theme.of(context).primaryColor : null),
            title: Text(
              session.title,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontWeight: isActive ? FontWeight.bold : FontWeight.normal),
            ),
            tileColor: isActive ? AppColors.sidebarCard.withOpacity(0.3) : null, // Highlight active chat
            onTap: () {
              if (!isActive) {
                historyNotifier.setActiveSession(session.id);
              }
              Navigator.pop(context); // Close drawer
            },
            trailing: Row(
              mainAxisSize: MainAxisSize.min, // Prevent row from taking full width
              children: [
                IconButton(
                  icon: Icon(Icons.edit_outlined, size: 20, color: Colors.grey[600]),
                  tooltip: 'Rename Chat',
                  onPressed: () {
                    Navigator.pop(context); // Close drawer first
                    _showRenameDialog(context, ref, session); // Show rename dialog
                  },
                ),
                IconButton(
                  icon: Icon(Icons.delete_outline, size: 20, color: Colors.red[400]),
                  tooltip: 'Delete Chat',
                  onPressed: () {
                    Navigator.pop(context); // Close drawer first
                    _showDeleteConfirmationDialog(context, ref, session); // Show confirmation dialog
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

