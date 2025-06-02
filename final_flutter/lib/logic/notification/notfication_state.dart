import 'package:final_flutter/data/models/notification_model.dart';

class NotificationState {
  final List<NotificationItem> notifications;
  final int unreadCount;

  NotificationState({required this.notifications, required this.unreadCount});

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is NotificationState &&
        other.notifications.length == notifications.length &&
        other.unreadCount == unreadCount;
  }

  @override
  int get hashCode => notifications.hashCode ^ unreadCount.hashCode;

  NotificationState copyWith({
    List<NotificationItem>? notifications,
    int? unreadCount,
  }) {
    return NotificationState(
      notifications: notifications ?? this.notifications,
      unreadCount: unreadCount ?? this.unreadCount,
    );
  }
}