import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';

import '../utils/supabase_client.dart';
import '../models/notification_model.dart';

/// Service to subscribe to real-time notifications via Supabase.
class NotificationService {
  final _supabase = supabase;

  /// Streams notifications for the current user, optionally filtered by courseId.
  Stream<List<NotificationItem>> subscribeNotifications({String? courseId}) {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return const Stream.empty();

    // Create a StreamController to manage the notification stream
    final controller = StreamController<List<NotificationItem>>();

    // Initial fetch of notifications
    _fetchNotifications(userId, courseId).then((notifications) {
      if (!controller.isClosed) {
        controller.add(notifications);
      }
    });

    // Subscribe to real-time changes
    final channel = _supabase.channel('public:notifications');
    channel
      .onPostgresChanges(
        event: PostgresChangeEvent.insert,
        schema: 'public',
        table: 'notifications',
        callback: (payload) {
          // Fetch latest notifications when changes occur
          _fetchNotifications(userId, courseId).then((notifications) {
            if (!controller.isClosed) {
              controller.add(notifications);
            }
          });
        },
      )
      .onPostgresChanges( // Listen for updates (e.g., is_read changes)
        event: PostgresChangeEvent.update,
        schema: 'public',
        table: 'notifications',
        callback: (payload) {
          print('NotificationService: Received UPDATE event. Payload: ${payload.newRecord}'); // Add log
          // Refetch notifications on update
          _fetchNotifications(userId, courseId).then((notifications) {
             print('NotificationService: Refetched after UPDATE. Count: ${notifications.length}, Unread: ${notifications.where((n) => !n.is_read).length}'); // Add log with unread count
            if (!controller.isClosed) {
              controller.add(notifications);
            }
          });
        },
      )
      .onPostgresChanges(
        event: PostgresChangeEvent.delete,
        schema: 'public',
        table: 'notifications',
        callback: (payload) {
          // Refetch notifications on delete
          _fetchNotifications(userId, courseId).then((notifications) {
            if (!controller.isClosed) {
              controller.add(notifications);
            }
          });
        },
      )
      .subscribe();

    // Clean up when the stream is cancelled
    controller.onCancel = () {
      channel.unsubscribe();
      controller.close();
    };

    return controller.stream;
  }

  /// Helper method to fetch notifications
  Future<List<NotificationItem>> _fetchNotifications(String userId, String? courseId) async {
    var query = _supabase
        .from('notifications')
        .select()
        .eq('user_id', userId);
    
    if (courseId != null) {
      query = query.eq('course_id', courseId);
    }

    final data = await query.order('created_at', ascending: false);
    return data.map((map) => NotificationItem.fromMap(map)).toList();
  }

  /// Marks a specific notification as read in the database.
  Future<void> markNotificationAsRead(String notificationId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return; // Or throw error

    try {
      await _supabase
          .from('notifications')
          .update({'is_read': true})
          .eq('id', notificationId)
          .eq('user_id', userId); // Ensure user can only update their own
    } catch (e) {
      // Handle or log error appropriately
      print('Error marking notification as read: $e');
      rethrow;
    }
  }
}
