import 'package:final_flutter/data/models/notification_model.dart';

abstract class NotificationEvent {}

class AddNotification extends NotificationEvent {
  final NotificationItem item;
  AddNotification(this.item);
}

class MarkAllAsRead extends NotificationEvent {}
class ResetNotifications extends NotificationEvent {}
