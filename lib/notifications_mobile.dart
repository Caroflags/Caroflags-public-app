import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';


class NotificationService{
  static Future<void> initializeNotifications() async {
    AwesomeNotifications().initialize(
      null,
      [
        NotificationChannel(
          channelKey: 'basic_channel',
          channelName: 'Basic notifications',
          channelDescription: 'Notification channel for basic tests',
          defaultColor: const Color.fromARGB(255, 234, 236, 93),
          ledColor: Colors.white,
        )
      ],
    );

    bool isAllowed = await AwesomeNotifications().isNotificationAllowed();
    if (!isAllowed) {
      await AwesomeNotifications().requestPermissionToSendNotifications();
    }
  }

  static Future<bool> isAllowed() async {
    return await AwesomeNotifications().isNotificationAllowed();
  }

  static Future<void> requestPermission() async {
    await AwesomeNotifications().requestPermissionToSendNotifications();
  }

  static Future<void> showNotification(int id, String title, String body) async {
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: id,
        channelKey: 'basic_channel',
        title: title,
        body: body,
      ),
    );
  }
}