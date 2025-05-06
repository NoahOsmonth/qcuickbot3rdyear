import 'package:flutter/material.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/chat_session.dart';
import '../../theme/app_theme.dart';
import '../../providers/chat_history_provider.dart';
// Keep for log if needed

// Convert to ConsumerStatefulWidget to manage local state for pagination
class ChatHistoryList extends ConsumerStatefulWidget {
  const ChatHistoryList({super.key});

  @override
  ConsumerState<ChatHistoryList> createState() => _ChatHistoryListState();
}

class _ChatHistoryListState extends ConsumerState<ChatHistoryList> {
  // State variable to control how many items are displayed initially
  int _displayCount = 7; // Show initial 7 items
  final int _increment = 7; // Load 7 more items at a time

  // --- Rename Dialog --- (Keep as is, but context/ref access changes slightly)
  Future<void> _showRenameDialog(ChatSessionHeader session) async {
    // Access context and ref from the State
    final textController = TextEditingController(text: session.title);
    final formKey = GlobalKey<FormState>();

    return showDialog<void>(
      context: context, // Use state's context
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
                    // Use state's ref
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
  Future<void> _showDeleteConfirmationDialog(ChatSessionHeader session) async {
    // Access context and ref from the State
    return showDialog<void>(
      context: context, // Use state's context
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
                // Use state's ref
                ref.read(chatHistoryProvider.notifier).deleteSession(session.id);
                Navigator.of(dialogContext).pop();
              },
            ),
          ],
        );
      },
    );
  }

  // --- Build List Item --- Helper function for consistency (Keep as is)
  // Helper function now uses state's context and ref implicitly
  Widget _buildSessionTile(ChatSessionHeader session, bool isActive, bool isArchived) {
     final historyNotifier = ref.read(chatHistoryProvider.notifier); // Use state's ref

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
                _showRenameDialog(session); // Pass only session
               break;
             case 'delete':
                Navigator.pop(context); // Close drawer for dialog
                _showDeleteConfirmationDialog(session); // Pass only session
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
  @override
  Widget build(BuildContext context) { // ref is now accessed via `this.ref`
    // Get state directly from the provider using the state's ref
    final historyState = ref.watch(chatHistoryProvider);
    final sessions = historyState.sessions; // Pinned and Active chats
    final archivedSessions = historyState.archivedSessions;
    final activeSessionId = historyState.activeSessionId;
    final bool hasArchived = archivedSessions.isNotEmpty;

    // Calculate total item count for the single ListView
    int totalItemCount = sessions.length;
    if (hasArchived) {
      totalItemCount += 1; // Divider
      totalItemCount += 1; // Header
      totalItemCount += archivedSessions.length; // Archived items
    }

    // Determine the number of items to actually build in the ListView
    final bool hasMoreItems = totalItemCount > _displayCount;
    // If there are more items, add 1 to itemCount for the "Show More" button
    final int listViewItemCount = hasMoreItems ? _displayCount + 1 : totalItemCount;

    return Expanded(
      child: ListView.builder(
        padding: EdgeInsets.zero, // Keep padding zero
        itemCount: listViewItemCount, // Use the calculated count
        itemBuilder: (context, index) {

          // --- Handle "Show More" Button ---
          if (hasMoreItems && index == _displayCount) {
            return TextButton(
              child: const Text('Show More'),
              onPressed: () {
                setState(() {
                  // Increase display count, ensuring not to exceed total
                  _displayCount = (_displayCount + _increment).clamp(0, totalItemCount);
                });
              },
            );
          }

          // --- Render List Items (Sessions, Divider, Header) ---
          // Calculate item index boundaries (same as before)
          final int activeCount = sessions.length;
          // Indices only relevant if archived sessions exist
          final int dividerIndex = hasArchived ? activeCount : -1;
          final int headerIndex = hasArchived ? activeCount + 1 : -1;
          final int archivedStartIndex = hasArchived ? activeCount + 2 : -1;

          // --- Render Active/Pinned Sessions ---
          if (index < activeCount) {
            final session = sessions[index];
            final isActive = session.id == activeSessionId;
            // Pass isArchived: false
            // Call helper without context/ref args
            return _buildSessionTile(session, isActive, false);
          }
          // --- Render Divider (if needed) ---
          else if (hasArchived && index == dividerIndex) {
            return const Divider(height: 1, thickness: 1);
          }
          // --- Render Archived Header (if needed) ---
          else if (hasArchived && index == headerIndex) {
            // Replace ExpansionTile with simple ListTile for header
            return ListTile(
              title: Text(
                'Archived Chats (${archivedSessions.length})',
                style: TextStyle(
                    color: Colors.grey[700],
                    fontSize: 14,
                    fontWeight: FontWeight.w500), // Slightly bolder header
              ),
              dense: true, // Make header less tall
              visualDensity: VisualDensity.compact,
              // Optional: Add horizontal padding to match original ExpansionTile padding
              contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 0),
            );
          }
          // --- Render Archived Sessions (if needed) ---
          else if (hasArchived && index >= archivedStartIndex) {
            // Calculate the index within the archivedSessions list
            final archivedItemIndex = index - archivedStartIndex;
             // Add a bounds check for safety
            if (archivedItemIndex >= 0 && archivedItemIndex < archivedSessions.length) {
              final session = archivedSessions[archivedItemIndex];
              // Archived sessions are never 'active' in the main view sense
              // Pass isArchived: true
              // Call helper without context/ref args
              return _buildSessionTile(session, false, true);
            } else {
               // Log error or return empty space if index is out of bounds
               print("Error: Archived index out of bounds: $index");
               return const SizedBox.shrink();
            }
          }
          // --- Fallback (should not be reached with correct itemCount) ---
          else {
            print("Error: Unexpected index in ChatHistoryList builder: $index");
            return const SizedBox.shrink();
          }
        },
      ),
    );
  }
}
