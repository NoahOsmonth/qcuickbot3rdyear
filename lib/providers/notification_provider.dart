import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../models/notification_model.dart';
import '../services/notification_service.dart';

/// Provides NotificationService instance
final notificationServiceProvider = Provider((ref) => NotificationService());

/// Provider for requesting notification permissions
final notificationPermissionProvider = FutureProvider<NotificationSettings>((ref) async {
  final messaging = FirebaseMessaging.instance;
  final settings = await messaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );
  print('User granted permission: ${settings.authorizationStatus}');
  return settings;
});

/// Stream of notifications, optionally filtered by courseId
final notificationsProvider = StreamProvider.family<List<NotificationItem>, String?>((ref, courseId) {
  final service = ref.watch(notificationServiceProvider);
  return service.subscribeNotifications(courseId: courseId);
});

/// Provides the count of unread notifications, optionally filtered by courseId.
final unreadNotificationCountProvider = Provider.family<int, String?>((ref, courseId) {
  // Watch the main notification stream
  final asyncNotifications = ref.watch(notificationsProvider(courseId));

  // Calculate and log the count when data is available
  final count = asyncNotifications.when(
    data: (notifications) {
      final unreadCount = notifications.where((n) => !n.is_read).length;
      print('unreadNotificationCountProvider($courseId): Recalculated count = $unreadCount'); // Added Log
      return unreadCount;
    },
    loading: () => 0,
    error: (_, __) => 0,
  );
  return count;
});
