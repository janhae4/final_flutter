import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  late FlutterLocalNotificationsPlugin _notificationsPlugin;
  late AndroidNotificationChannel _channel;
  int _unreadCount = 0;
  final ValueNotifier<int> unreadCountNotifier = ValueNotifier<int>(0);

  Future<void> initialize() async {
    _notificationsPlugin = FlutterLocalNotificationsPlugin();

    _channel = const AndroidNotificationChannel(
      'email_channel',
      'Email Notifications',
      description: 'Notifications for new emails',
      importance: Importance.high,
      playSound: true,
      showBadge: true,
      enableVibration: true,
    );

    // Fixed: Use built-in Android email icon
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@android:drawable/ic_dialog_email');

    final DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
          notificationCategories: [
            DarwinNotificationCategory(
              'email_category',
              actions: <DarwinNotificationAction>[
                DarwinNotificationAction.plain(
                  'id_1',
                  'Mark as read',
                  options: <DarwinNotificationActionOption>{
                    DarwinNotificationActionOption.foreground,
                  },
                ),
              ],
            ),
          ],
        );

    final InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Ho_Chi_Minh'));

    await _notificationsPlugin.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(_channel);
  }

  void _onNotificationTap(NotificationResponse response) {
    if (response.payload != null) {
      print('Notification tapped with payload: ${response.payload}');
      // Navigator.push(context, EmailDetailScreen(emailId: response.payload));
    }
  }

  Future<void> showEmailNotification({
    required String sender,
    required String subject,
    required DateTime receivedTime,
    String? emailId,
  }) async {
    _unreadCount++;
    unreadCountNotifier.value = _unreadCount;

    final androidDetails = AndroidNotificationDetails(
      _channel.id,
      _channel.name,
      channelDescription: _channel.description,
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      when: receivedTime.millisecondsSinceEpoch,
      styleInformation: MessagingStyleInformation(
        Person(
          name: 'Email',
          // Fixed: Remove the icon or use a proper drawable resource
          // icon: const BitmapFilePathAndroidIcon('@mipmap/ic_launcher'),
        ),
        groupConversation: true,
        conversationTitle: 'New email',
      ),
      groupKey: 'email_group',
      setAsGroupSummary: true,
    );

    // Cấu hình thông báo iOS
    final iosDetails = DarwinNotificationDetails(
      threadIdentifier: 'email_thread',
      categoryIdentifier: 'email_category',
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      badgeNumber: _unreadCount,
    );

    // Hiển thị thông báo
    await _notificationsPlugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000, // ID duy nhất
      'New email from $sender',
      _truncateSubject(subject),
      NotificationDetails(android: androidDetails, iOS: iosDetails),
      payload: emailId,
    );

    await _updateBadgeCount();
  }

  String _truncateSubject(String subject) {
    return subject.length > 50 ? '${subject.substring(0, 50)}...' : subject;
  }

  Future<void> _updateBadgeCount() async {
    _notificationsPlugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();

    _notificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
  }

  Future<void> clearAllNotifications() async {
    await _notificationsPlugin.cancelAll();
    _unreadCount = 0;
    unreadCountNotifier.value = _unreadCount;
    await _updateBadgeCount();
  }

  Future<void> markAsRead(String emailId) async {
    if (_unreadCount > 0) {
      _unreadCount--;
      unreadCountNotifier.value = _unreadCount;
      await _updateBadgeCount();
    }
    // TODO: Có thể cancel notification cụ thể nếu cần
  }

  Future<void> resetBadgeCount() async {
    _unreadCount = 0;
    unreadCountNotifier.value = 0;
    await _updateBadgeCount();
  }
}