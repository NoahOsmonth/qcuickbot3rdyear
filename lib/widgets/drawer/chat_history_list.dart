import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/chat_session.dart';
import '../../theme/app_theme.dart';
import '../../providers/chat_history_provider.dart';
// Keep for log if needed

class ChatHistoryList extends ConsumerWidget {
  // Removed sessions and activeSessionId from constructor, get from provider
  const ChatHistoryList({super.key});

  // --- Rename Dialog --- (Keep as is)
  Future<void> _showRenameDialog(BuildContext context, WidgetRef ref, ChatSessionHeader session) async {
    final textController = TextEditingController(text: session.title);
    final formKey = GlobalKey<FormState>();

    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Rename Chat'),
          content: Form(
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
                Navigator.of(dialogContext).pop();
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
                  Navigator.of(dialogContext).pop();
                }
              },
            ),
          ],
        );
      },
    );
  }

  // --- Delete Confirmation Dialog --- (Keep as is)
  Future<void> _showDeleteConfirmationDialog(BuildContext context, WidgetRef ref, ChatSessionHeader session) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Delete Chat?'),
          content: Text('Are you sure you want to delete "${session.title}"? This action cannot be undone.'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete'),
              onPressed: () {
                ref.read(chatHistoryProvider.notifier).deleteSession(session.id);
                Navigator.of(dialogContext).pop();
              },
            ),
          ],
        );
      },
    );
  }

  // --- Build List Item --- Helper function for consistency
  Widget _buildSessionTile(BuildContext context, WidgetRef ref, ChatSessionHeader session, bool isActive, bool isArchived) {
     final historyNotifier = ref.read(chatHistoryProvider.notifier);

     return ListTile(
        leading: Icon(
          // Show pin icon if pinned and not archived
          session.isPinned && !isArchived ? Icons.push_pin : Icons.chat_bubble_outline,
          color: isActive ? Theme.of(context).primaryColor : Colors.grey[600],
          size: 20,
        ),
        title: Text(
          session.title,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            color: isActive ? Theme.of(context).primaryColor : null,
          ),
        ),
        tileColor: isActive ? AppColors.sidebarCard.withOpacity(0.3) : null,
        onTap: () {
          if (!isActive && !isArchived) { // Only allow activating non-archived chats
            historyNotifier.setActiveSession(session.id);
          } else if (isArchived) {
             // Optionally unarchive and activate on tap? For now, just unarchive via menu.
             // historyNotifier.archiveSession(session.id, false);
             // historyNotifier.setActiveSession(session.id); // Needs careful state handling
          }
          // Close drawer only if activating a non-archived chat
          if (!isArchived) {
             Navigator.pop(context);
          }
        },
        trailing: PopupMenuButton<String>(
          icon: Icon(Icons.more_vert, color: Colors.grey[600], size: 20),
          tooltip: 'Chat Options',
          onSelected: (String result) {
            // Close drawer before showing dialogs
            // Navigator.pop(context); // Pop only if action requires it (dialogs)

            switch (result) {
              case 'pin':
                historyNotifier.pinSession(session.id, true);
                break;
              case 'unpin':
                historyNotifier.pinSession(session.id, false);
                break;
              case 'archive':
                historyNotifier.archiveSession(session.id, true);
                break;
              case 'unarchive':
                 // Unarchiving might need drawer context later if we don't close it
                historyNotifier.archiveSession(session.id, false);
                break;
              case 'rename':
                 Navigator.pop(context); // Close drawer for dialog
                _showRenameDialog(context, ref, session);
                break;
              case 'delete':
                 Navigator.pop(context); // Close drawer for dialog
                _showDeleteConfirmationDialog(context, ref, session);
                break;
            }
          },
          itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
            // Pin/Unpin (only for non-archived)
            if (!isArchived)
              PopupMenuItem<String>(
                value: session.isPinned ? 'unpin' : 'pin',
                child: Text(session.isPinned ? 'Unpin Chat' : 'Pin Chat'),
              ),
            // Archive/Unarchive
            PopupMenuItem<String>(
              value: isArchived ? 'unarchive' : 'archive',
              child: Text(isArchived ? 'Unarchive Chat' : 'Archive Chat'),
            ),
            const PopupMenuDivider(),
            // Rename
            PopupMenuItem<String>(
              value: 'rename',
              child: const Text('Rename'),
            ),
            // Delete
            PopupMenuItem<String>(
              value: 'delete',
              child: Text('Delete', style: TextStyle(color: Colors.red[400])),
            ),
          ],
        ),
      );
  }


  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Get state directly from the provider
    final historyState = ref.watch(chatHistoryProvider);
    final sessions = historyState.sessions; // Pinned and Active chats
    final archivedSessions = historyState.archivedSessions;
    final activeSessionId = historyState.activeSessionId;

    return Expanded(
      child: ListView( // Use a single ListView to contain both sections
        padding: EdgeInsets.zero,
        children: [
          // --- Active and Pinned Chats ---
          ListView.builder(
            shrinkWrap: true, // Important inside another ListView
            physics: const NeverScrollableScrollPhysics(), // Disable scrolling for this inner list
            itemCount: sessions.length,
            itemBuilder: (context, index) {
              // Provider now sorts pinned first
              final session = sessions[index];
              final isActive = session.id == activeSessionId;
              return _buildSessionTile(context, ref, session, isActive, false); // isArchived = false
            },
          ),

          // --- Archived Chats Section ---
          if (archivedSessions.isNotEmpty) ...[
            const Divider(height: 1, thickness: 1),
            ExpansionTile(
              title: Text(
                'Archived Chats (${archivedSessions.length})',
                style: TextStyle(color: Colors.grey[700], fontSize: 14),
              ),
              tilePadding: const EdgeInsets.symmetric(horizontal: 16.0),
              childrenPadding: EdgeInsets.zero,
              children: [
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: archivedSessions.length,
                  itemBuilder: (context, index) {
                    final session = archivedSessions[index];
                    // Archived chats cannot be active
                    return _buildSessionTile(context, ref, session, false, true); // isArchived = true
                  },
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
