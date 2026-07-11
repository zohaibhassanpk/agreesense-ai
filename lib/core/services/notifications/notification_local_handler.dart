import 'dart:io';
import '../logger/logger_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationLocalHandler {
  NotificationLocalHandler({
    void Function(Map<String, dynamic> data)? onNotificationTapped,
  }) : _onNotificationTapped = onNotificationTapped;

  final void Function(Map<String, dynamic> data)? _onNotificationTapped;
  final LoggerService _logger = LoggerService(
    className: 'NotificationLocalHandler',
  );
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  /// Initialize local notifications and create channels.
  Future<void> initialize() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _plugin.initialize(
      settings: const InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      ),
      onDidReceiveNotificationResponse: _onTap,
    );

    if (Platform.isAndroid) {
      await _createChannels();
    }
  }

  Future<void> _createChannels() async {
    const channels = [
      AndroidNotificationChannel(
        'high_importance_channel',
        'High Importance Notifications',
        description: 'This channel is used for important notifications.',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
      ),
      AndroidNotificationChannel(
        'default_channel',
        'Default Notifications',
        description: 'This channel is used for regular notifications.',
        importance: Importance.defaultImportance,
      ),
    ];

    for (final channel in channels) {
      await _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(channel);
    }
  }

  /// Display a local notification.
  Future<void> show({
    required String title,
    required String body,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'high_importance_channel',
      'High Importance Notifications',
      channelDescription: 'This channel is used for important notifications.',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    await _plugin.show(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: title,
      body: body,
      notificationDetails: const NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      ),
      payload: payload,
    );
  }

  void _onTap(NotificationResponse response) {
    _logger.info(
      'Local notification tapped: ${response.payload}',
      tag: '[Notification][Local]',
    );
    if (response.payload != null) {
      _onNotificationTapped?.call({'payload': response.payload});
    }
  }
}
