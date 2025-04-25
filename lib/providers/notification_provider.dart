import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/notification_model.dart';
import '../services/notification_service.dart';

/// Provides NotificationService instance
final notificationServiceProvider = Provider((ref) => NotificationService());

/// Stream of notifications, optionally filtered by courseId
final notificationsProvider = StreamProvider.family<List<NotificationItem>, String?>((ref, courseId) {
  final service = ref.watch(notificationServiceProvider);
  return service.subscribeNotifications(courseId: courseId);
});

/// Provides the count of unread notifications, optionally filtered by courseId.
final unreadNotificationCountProvider = Provider.family<int, String?>((ref, courseId) {
  // Watch the main notification stream
  final asyncNotifications = ref.watch(notificationsProvider(courseId));

  // Return the count of unread items when data is available
  return asyncNotifications.when(
    data: (notifications) => notifications.where((n) => !n.is_read).length,
    loading: () => 0, // Or handle loading state differently if needed
    error: (_, __) => 0, // Or handle error state differently if needed
  );
});
