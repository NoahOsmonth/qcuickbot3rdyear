import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // Import Riverpod
import '../models/notification_model.dart';
import '../providers/notification_provider.dart'; // Import provider for service access

// Convert to ConsumerStatefulWidget
class NotificationDetailScreen extends ConsumerStatefulWidget {
  final NotificationItem notification;
  const NotificationDetailScreen({super.key, required this.notification});

  @override
  ConsumerState<NotificationDetailScreen> createState() => _NotificationDetailScreenState();
}

class _NotificationDetailScreenState extends ConsumerState<NotificationDetailScreen> {

  @override
  void initState() {
    super.initState();
    // Mark as read when the screen initializes, if not already read
    _markAsReadIfNeeded();
  }

  Future<void> _markAsReadIfNeeded() async {
    // Check if the notification is not already marked as read
    if (!widget.notification.is_read) {
      try {
        // Access the service via ref and call the markAsRead method
        await ref.read(notificationServiceProvider).markNotificationAsRead(widget.notification.id);
        // Invalidate the notifications stream provider to trigger immediate refresh
        ref.invalidate(notificationsProvider(widget.notification.courseId));
        // Optional: Add feedback or error handling here
      } catch (e) {
        // Handle potential errors during the update
        print("Error marking notification as read: $e");
        // Optionally show a snackbar or dialog to the user
        if (mounted) { // Check if the widget is still in the tree
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to mark notification as read.')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.notification.title)), // Use widget.notification
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(widget.notification.body), // Use widget.notification
      ),
      // Removed the FloatingActionButton
    );
  }
}