import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/notification_provider.dart';

/// A notification icon button showing real-time notification count and navigates to notification screen.
class NotificationIconButton extends ConsumerWidget {
  final String? courseId;
  const NotificationIconButton({super.key, this.courseId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the unread count provider directly
    final count = ref.watch(unreadNotificationCountProvider(courseId));

    // Build the IconButton using the unread count
    return IconButton(
      icon: Stack(
        clipBehavior: Clip.none,
            children: [
              const Icon(Icons.notifications, color: Colors.white),
              if (count > 0)
                Positioned(
                  right: -2,
                  top: -2,
                  child: Container(
                    padding: const EdgeInsets.all(1),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 12,
                      minHeight: 12,
                    ),
                    child: Text(
                      count > 99 ? '99+' : '$count',
                      style: const TextStyle(color: Colors.white, fontSize: 8),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
      onPressed: () => Navigator.pushNamed(context, '/notifications'),
    );
    // Removed the .when() structure as unreadNotificationCountProvider returns int
  }
}
