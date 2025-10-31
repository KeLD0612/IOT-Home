import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';

class NotificationService {
  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    try {
      await _notifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTap,
      );

      // Request permissions
      await _requestPermissions();

      _initialized = true;
      print('✅ NotificationService: Initialized');
    } catch (e) {
      print('❌ NotificationService Init Error: $e');
      _initialized = false;
    }
  }

  Future<void> _requestPermissions() async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      // Android notifications don't have a unified requestPermissions API in
      // flutter_local_notifications. On Android 13+ (SDK 33) the
      // POST_NOTIFICATIONS runtime permission is required. Handle that with
      // permission_handler or platform code if you need to request it.
      print(
        'Android platform detected — ensure POST_NOTIFICATIONS permission on Android 13+ if needed',
      );
    }

    if (defaultTargetPlatform == TargetPlatform.iOS) {
      final IOSFlutterLocalNotificationsPlugin? iosPlugin = _notifications
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >();

      if (iosPlugin != null) {
        try {
          final bool? granted = await iosPlugin.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
          print('iOS notification permission: $granted');
        } catch (e) {
          print('⚠️ iOS notification permission error: $e');
        }
      }
    }
  }

  void _onNotificationTap(NotificationResponse response) {
    print('🔔 Notification tapped: ${response.payload}');
    // Handle notification tap here
  }

  Future<void> showNotification({
    required String title,
    required String body,
    String? payload,
    NotificationPriority priority = NotificationPriority.high,
  }) async {
    if (!_initialized) {
      print('⚠️ NotificationService not initialized');
      return;
    }

    try {
      final androidDetails = AndroidNotificationDetails(
        'smart_home_channel',
        'Smart Home Alerts',
        channelDescription: 'Notifications for smart home events',
        importance: _getAndroidImportance(priority),
        priority: _getAndroidPriority(priority),
        playSound: true,
        enableVibration: true,
        icon: '@mipmap/ic_launcher',
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      final details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      // Use a larger, more unique id for notifications
      final int id = DateTime.now().millisecondsSinceEpoch.remainder(100000);

      await _notifications.show(id, title, body, details, payload: payload);

      print('🔔 Notification sent: $title');
    } catch (e) {
      print('❌ Notification Error: $e');
    }
  }

  Importance _getAndroidImportance(NotificationPriority priority) {
    switch (priority) {
      case NotificationPriority.low:
        return Importance.low;
      case NotificationPriority.normal:
        return Importance.defaultImportance;
      case NotificationPriority.high:
        return Importance.high;
      case NotificationPriority.max:
        return Importance.max;
    }
  }

  Priority _getAndroidPriority(NotificationPriority priority) {
    switch (priority) {
      case NotificationPriority.low:
        return Priority.low;
      case NotificationPriority.normal:
        return Priority.defaultPriority;
      case NotificationPriority.high:
        return Priority.high;
      case NotificationPriority.max:
        return Priority.max;
    }
  }

  Future<void> showGasAlert(int gasValue) async {
    await showNotification(
      title: '⚠️ Cảnh báo Gas!',
      body: 'Phát hiện nồng độ gas cao: $gasValue ppm',
      payload: 'gas_alert',
      priority: NotificationPriority.max,
    );
  }

  Future<void> showRainAlert() async {
    await showNotification(
      title: '🌧️ Cảnh báo mưa!',
      body: 'Đang có mưa, cửa trần đã tự động đóng',
      payload: 'rain_alert',
    );
  }

  Future<void> showLowSoilMoistureAlert() async {
    await showNotification(
      title: '🌱 Cảnh báo độ ẩm đất',
      body: 'Độ ẩm đất thấp, cần tưới cây',
      payload: 'soil_alert',
    );
  }

  Future<void> showHighDustAlert(int dustValue) async {
    await showNotification(
      title: '🫁 Cảnh báo bụi mịn',
      body: 'Nồng độ bụi cao: $dustValue. Máy phun sương đã bật',
      payload: 'dust_alert',
    );
  }

  Future<void> showMotionDetectedAlert() async {
    await showNotification(
      title: '🚶 Phát hiện chuyển động',
      body: 'Có người di chuyển trong khu vực giám sát',
      payload: 'motion_alert',
      priority: NotificationPriority.normal,
    );
  }

  Future<void> cancelAll() async {
    try {
      await _notifications.cancelAll();
      print('🔕 All notifications cancelled');
    } catch (e) {
      print('❌ Cancel notifications error: $e');
    }
  }

  Future<void> cancel(int id) async {
    try {
      await _notifications.cancel(id);
      print('🔕 Notification $id cancelled');
    } catch (e) {
      print('❌ Cancel notification error: $e');
    }
  }
}

enum NotificationPriority { low, normal, high, max }
