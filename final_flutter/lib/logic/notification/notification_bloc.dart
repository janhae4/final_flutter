import 'package:final_flutter/data/models/notification_model.dart';
import 'package:final_flutter/logic/notification/notfication_state.dart';
import 'package:final_flutter/logic/notification/notification_event.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class NotificationBloc extends Bloc<NotificationEvent, NotificationState> {
  NotificationBloc()
    : super(NotificationState(notifications: [], unreadCount: 0)) {
    on<AddNotification>((event, emit) {
      final updated = [event.item, ...state.notifications];
      final newState = state.copyWith(
        notifications: updated,
        unreadCount: state.unreadCount + 1,
      );


      emit(newState);
    });

    on<MarkAllAsRead>((event, emit) {
      final updated =
          state.notifications.map((e) => e.copyWith(isRead: true)).toList();
      emit(state.copyWith(notifications: updated, unreadCount: 0));
    });

    on<ResetNotifications>((event, emit) {
      emit(NotificationState(notifications: [], unreadCount: 0));
    });
  }
}
