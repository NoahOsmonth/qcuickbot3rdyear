import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/notification_provider.dart';
import 'notification_detail_screen.dart';

/// Screen to list real-time notifications, optionally filtered by courseId
class NotificationScreen extends ConsumerWidget {
  final String? courseId;
  const NotificationScreen({super.key, this.courseId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // final asyncNotifs = ref.watch(notificationsProvider(courseId)); // Moved down
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'), // Add const
      ),
      // Wrap body content in a Consumer
      body: Consumer(
        builder: (context, ref, child) {
          final asyncNotifs = ref.watch(notificationsProvider(courseId));
          return asyncNotifs.when(
            data: (notifs) {
              if (notifs.isEmpty) {
                return const Center(child: Text('No notifications')); // Add const
              }
              return ListView.builder(
                itemCount: notifs.length,
                itemBuilder: (context, index) {
                  final notif = notifs[index];
                  return ListTile(
                    title: Text(notif.title),
                    subtitle: Text(
                      notif.createdAt.toLocal().toString(),
                      style: const TextStyle(fontSize: 12), // Add const
                    ),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => NotificationDetailScreen(notification: notif),
                        ),
                      );
                    },
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()), // Add const
            error: (err, _) => Center(child: Text('Error: $err')),
          );
        },
      ),
    );
  }
}
