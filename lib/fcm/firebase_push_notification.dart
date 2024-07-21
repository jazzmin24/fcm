
import 'dart:convert';
import 'dart:developer';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:url_launcher/url_launcher.dart';

Future<void> handelBackgroundMessage(RemoteMessage message) async {
  log('Title: ${message.notification?.title}');
  log('Body: ${message.notification?.body}');
  log('payload: ${message.data}');
}

class FirebaseApi {
  static final _firebaseMessaging = FirebaseMessaging.instance;

  static final _androidChannel = const AndroidNotificationChannel(
    "High_importance_channel",
    "High Importance Notifications",
    description: "This channel is used for important channel ",
    importance: Importance.defaultImportance,
  );

  static final _localNotifications = FlutterLocalNotificationsPlugin();

  static void handelMessage(RemoteMessage? message) async {
    if (message == null) return;

    print("working");
    print(message.notification!.body);
    if (!await launchUrl(Uri.parse(message.notification!.body as String))) {
      throw Exception('Could not launch ${message.notification!.body}');
    }
  }

  static Future initLocalNotifications() async {
    const iOS = DarwinInitializationSettings();
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: android, iOS: iOS);
    await _localNotifications.initialize(
      settings,
      onDidReceiveNotificationResponse: (details) {
        final message = RemoteMessage.fromMap(
          jsonDecode(details.payload as String),
        );
        handelMessage(message);
      },
    );

    final platform = _localNotifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await platform?.createNotificationChannel(_androidChannel);
  }

  static Future initPushNotifications() async {
    await FirebaseMessaging.instance
        .setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
    FirebaseMessaging.instance.getInitialMessage().then(handelMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(handelMessage);
    FirebaseMessaging.onBackgroundMessage(handelBackgroundMessage);
    FirebaseMessaging.onMessage.listen((event) {
      final notification = event.notification;
      if (notification == null) return;

      _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            _androidChannel.id,
            _androidChannel.name,
            channelDescription: _androidChannel.description,
            icon: '@mipmap/ic_launcher',
          ),
        ),
        payload: jsonEncode(
          event.toMap(),
        ),
      );
    });
  }

  static Future<void> initNotifications() async {
    await _firebaseMessaging.requestPermission();

    final fCMToken = await _firebaseMessaging.getToken();
    log("Fcm Token : $fCMToken");
    initPushNotifications();
    initLocalNotifications();
  }
}