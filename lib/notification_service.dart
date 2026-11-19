import 'dart:ui' show Color;

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// All plugin-specific code lives here. If you upgrade flutter_local_notifications
/// and the API changes, this is the only file you should have to touch.
class NotificationService {
  final _plugin = FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    tzdata.initializeTimeZones();
    const android = AndroidInitializationSettings('@drawable/ic_stat_logo');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _plugin.initialize(
      settings: const InitializationSettings(android: android, iOS: ios),
    );
  }

  Future<bool> requestPermission() async {
    final a = await _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
    final i = await _plugin
        .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);
    return a ?? i ?? true;
  }

  static const _details = NotificationDetails(
    android: AndroidNotificationDetails(
      'maintenance',
      'Maintenance reminders',
      channelDescription: 'Service reminders for your motorcycle',
      importance: Importance.high,
      priority: Priority.high,
      icon: 'ic_stat_logo', // white logo in the status bar
      color: Color(0xFFE4572E), // terracotta accent behind it
      largeIcon: DrawableResourceAndroidBitmap('ic_notif_large'), // full-color logo
    ),
    iOS: DarwinNotificationDetails(),
  );

  Future<void> cancelAll() => _plugin.cancelAll();

  /// Schedules at an absolute moment (we convert to UTC so the device's
  /// time zone name is never needed; the instant is still correct locally).
  Future<void> schedule({
    required int id,
    required String title,
    required String body,
    required DateTime when,
    bool weekly = false,
  }) async {
    try {
      await _plugin.zonedSchedule(
        id: id,
        title: title,
        body: body,
        scheduledDate: tz.TZDateTime.from(when, tz.UTC),
        notificationDetails: _details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: weekly ? DateTimeComponents.dayOfWeekAndTime : null,
      );
    } catch (e) {
      debugPrint('Could not schedule notification $id: $e');
    }
  }
}
