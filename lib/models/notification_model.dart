// Model for notifications
class NotificationItem {
  final String id;
  final String userId;
  final String? courseId;
  final String title;
  final String body;
  final DateTime createdAt;
  final bool is_read; // Added is_read field

  NotificationItem({
    required this.id,
    required this.userId,
    this.courseId,
    required this.title,
    required this.body,
    required this.createdAt,
    required this.is_read, // Added to constructor
  });

  factory NotificationItem.fromMap(Map<String, dynamic> map) => NotificationItem(
        id: map['id'] as String,
        userId: map['user_id'] as String,
        courseId: map['course_id'] as String?,
        title: map['title'] as String,
        body: map['body'] as String,
        createdAt: DateTime.parse(map['created_at'] as String),
        is_read: map['is_read'] as bool, // Added parsing for is_read
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'user_id': userId,
        'course_id': courseId,
        'title': title,
        'body': body,
        'created_at': createdAt.toIso8601String(),
        'is_read': is_read, // Added is_read to map
      };
}