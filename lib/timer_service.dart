import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'dart:io';
import 'dart:ui';

@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse notificationResponse) async {
  if (notificationResponse.actionId == 'reset' && notificationResponse.payload != null) {
    await Hive.initFlutter();
    await Hive.openBox('timer_settings');
    final timerId = notificationResponse.payload!;
    Duration duration;
    String title;
    if (timerId == 'drinks') {
      duration = const Duration(minutes: 15);
      title = 'Drinks';
    } else if (timerId == 'all_day') {
      duration = const Duration(minutes: 90);
      title = 'All Day Dining';
    } else if (timerId == 'all_season') {
      duration = const Duration(hours: 4);
      title = 'All Season Dining';
    } else {
      return;
    }
    await TimerService.startTimer(timerId, title, duration, DateTime.now().add(duration));
  }
}

class TimerService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();
  
  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    // For iOS
    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) async {
        if (response.actionId == 'reset' && response.payload != null) {
          final timerId = response.payload!;
          Duration duration;
          String title;
          if (timerId == 'drinks') {
            duration = const Duration(minutes: 15);
            title = 'Drinks';
          } else if (timerId == 'all_day') {
            duration = const Duration(minutes: 90);
            title = 'All Day Dining';
          } else if (timerId == 'all_season') {
            duration = const Duration(hours: 4);
            title = 'All Season Dining';
          } else {
            return;
          }
          await TimerService.startTimer(timerId, title, duration, DateTime.now().add(duration));
        }
      },
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );
    _initialized = true;
  }

  static int _getIdForTimer(String timerId) {
    switch (timerId) {
      case 'drinks':
        return 101;
      case 'all_day':
        return 102;
      case 'all_season':
        return 103;
      default:
        return 104;
    }
  }

  static Future<void> startTimer(String id, String title, Duration duration, DateTime endTime) async {
    if (!_initialized) await init();
    
    final box = Hive.box('timer_settings');
    box.put('timer_end_$id', endTime.millisecondsSinceEpoch);

    final bool showPersistent = box.get('enable_persistent_notification', defaultValue: true);

    if (showPersistent && Platform.isAndroid) {
      final androidPlatformChannelSpecifics = AndroidNotificationDetails(
        'timers_channel',
        'Timers',
        channelDescription: 'Ongoing timer notifications',
        importance: Importance.low,
        priority: Priority.low,
        ongoing: true,
        autoCancel: false,
        usesChronometer: true,
        chronometerCountDown: true,
        when: endTime.millisecondsSinceEpoch,
        color: const Color.fromARGB(255, 86, 160, 211), // Theme primary color roughly
      );

      final platformChannelSpecifics = NotificationDetails(
        android: androidPlatformChannelSpecifics,
      );

      await _notificationsPlugin.show(
        _getIdForTimer(id),
        '$title Timer',
        'Counting down...',
        platformChannelSpecifics,
        payload: id,
      );
    }
    
    // We should also schedule a notification for when it finishes.
    // However flutter_local_notifications requires timezone setup to schedule properly.
    // Instead, since this is a simple implementation, we can just rely on the ongoing chronometer 
    // or use Future.delayed if the app is alive. If the app is killed, the chronometer stays.
    // For a real production app, android_alarm_manager or timezone package should be used to schedule the end notification.
    // For now, we will just use Future.delayed to show the completion if the app is still open.
    Future.delayed(duration, () {
      final storedEnd = getTimerEndTime(id);
      if (storedEnd != null && storedEnd == endTime.millisecondsSinceEpoch) {
        showTimerComplete(id, title);
      }
    });
  }

  static Future<void> showTimerComplete(String id, String title) async {
    if (!_initialized) await init();
    final box = Hive.box('timer_settings');
    box.delete('timer_end_$id');
    box.delete('timer_remaining_$id');

    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'timers_done_channel',
      'Timers Completed',
      channelDescription: 'Notifications for completed timers',
      importance: Importance.max,
      priority: Priority.high,
      actions: <AndroidNotificationAction>[
        AndroidNotificationAction('reset', 'Reset Timer'),
      ],
    );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );

    await _notificationsPlugin.show(
      _getIdForTimer(id), // replace the ongoing one
      '$title Timer Finished!',
      'Your timer has ended. You can reset it now.',
      platformChannelSpecifics,
      payload: id,
    );
  }

  static Future<void> cancelTimer(String id) async {
    if (!_initialized) await init();
    final box = Hive.box('timer_settings');
    box.delete('timer_end_$id');
    box.delete('timer_remaining_$id');
    await _notificationsPlugin.cancel(_getIdForTimer(id));
  }

  static int? getTimerEndTime(String id) {
    final box = Hive.box('timer_settings');
    return box.get('timer_end_$id');
  }
}

