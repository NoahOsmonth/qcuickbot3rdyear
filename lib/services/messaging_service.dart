import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class MessagingService {
  static final MessagingService _instance = MessagingService._internal();
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  
  factory MessagingService() {
    return _instance;
  }

  MessagingService._internal();

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'high_importance_channel',
    'High Importance Notifications',
    description: 'This channel is used for important notifications.',
    importance: Importance.high,
  );

  Future<void> initialize() async {
    // Request permission for notifications
    await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Initialize local notifications
    await _initializeLocalNotifications();

    // Set up foreground message handler
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Set up notification tap handlers
    await _setupInteractedMessage();
  }

  Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings();
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse details) {
        _handleNotificationTap(details);
      },
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);
  }

  void _handleForegroundMessage(RemoteMessage message) async {
    print('Received a message in the foreground: ${message.messageId}');
    
    if (message.notification != null) {
      await _localNotifications.show(
        message.notification.hashCode,
        message.notification?.title,
        message.notification?.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            _channel.id,
            _channel.name,
            channelDescription: _channel.description,
            icon: '@mipmap/ic_launcher',
          ),
          iOS: const DarwinNotificationDetails(),
        ),
        payload: message.data.toString(),
      );
    }
  }

  Future<void> _setupInteractedMessage() async {
    // Get any messages that caused the application to open
    RemoteMessage? initialMessage = await _firebaseMessaging.getInitialMessage();
    if (initialMessage != null) {
      _handleMessageTap(initialMessage);
    }

    // Handle messages when app is in background
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageTap);
  }

  void _handleMessageTap(RemoteMessage message) {
    // TODO: Handle navigation based on message data
    print('Message tapped: ${message.messageId}');
    if (message.data['type'] == 'chat') {
      // Navigate to chat screen with data from message
      // You'll need to implement this based on your navigation setup
    }
  }

  void _handleNotificationTap(NotificationResponse details) {
    // TODO: Handle navigation based on notification tap
    print('Notification tapped: ${details.payload}');
    // Implement navigation logic here
  }

  // Get the FCM token
  Future<String?> getToken() async {
    return await _firebaseMessaging.getToken();
  }
}
