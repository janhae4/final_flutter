import 'package:final_flutter/data/models/email.dart';
import 'package:final_flutter/data/models/email_response_model.dart';
import 'package:final_flutter/data/models/notification_model.dart';
import 'package:final_flutter/logic/email/email_event.dart';
import 'package:final_flutter/logic/email/email_repository.dart';
import 'package:final_flutter/logic/email/email_state.dart';
import 'package:final_flutter/logic/notification/notification_bloc.dart';
import 'package:final_flutter/logic/notification/notification_event.dart';
import 'package:final_flutter/service/notification_service.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:final_flutter/logic/settings/settings_bloc.dart';
import 'package:final_flutter/logic/auth/auth_bloc.dart';
import 'package:final_flutter/logic/auth/auth_state.dart';

class EmailBloc extends Bloc<EmailEvent, EmailState> {
  final EmailRepository _emailRepository;
  final NotificationBloc _notificationBloc;
  final NotificationService _notificationService = NotificationService();
  final SettingsBloc settingsBloc;
  final AuthBloc authBloc;

  EmailBloc({
    required EmailRepository emailRepository,
    required NotificationBloc notificationBloc,
    required this.settingsBloc,
    required this.authBloc,
  }) : _emailRepository = emailRepository,
       _notificationBloc = notificationBloc,
       super(EmailInitial()) {
    on<EmailConnectSocket>(_onConnectSocket);
    on<LoadEmails>(_onLoadEmails);
    on<LoadEmailDetail>(_onLoadEmailDetail);
    on<SendEmail>(_onSendEmail);
    on<RefreshEmails>(_onRefreshEmails);
    on<ChangeTab>(_onChangeTab);
    on<DeleteEmail>(_onDeleteEmail);
    on<RestoreEmail>(_onRestoreEmail);
    on<ToggleStarEmail>(_onToggleStarEmail);
    on<MarkEmailAsRead>(_onMarkEmailAsRead);
    on<NewEmailReceived>(_onNewEmailReceived);
  }

  Future<void> _onConnectSocket(
    EmailConnectSocket event,
    Emitter<EmailState> emit,
  ) async {
    try {
      emit(EmailLoading());
      await _emailRepository.connectSocket((EmailResponseModel newEmail) {
        print('New email received: $newEmail');
        print('New email received: ${newEmail.id}');
        add(NewEmailReceived(newEmail));
      });

      final emails = await _getEmailsForCurrentTab(0);
      emit(EmailLoaded(emails: emails));
    } catch (e) {
      emit(EmailError(e.toString()));
    }
  }

  Future<void> _onLoadEmails(LoadEmails event, Emitter<EmailState> emit) async {
    try {
      emit(EmailLoading());
      final emails = await _getEmailsForCurrentTab(event.tab);
      emit(EmailLoaded(emails: emails, currentTab: event.tab));
    } catch (e) {
      emit(EmailError(e.toString()));
    }
  }

  Future<void> _onLoadEmailDetail(
    LoadEmailDetail event,
    Emitter<EmailState> emit,
  ) async {
    try {
      emit(EmailLoading());
      final email = await _emailRepository.getEmailDetail(event.id);

      await _emailRepository.markRead(event.id);
      await _notificationService.markAsRead(event.id);

      emit(EmailDetailLoaded(email: email));
    } catch (e) {
      emit(EmailError(e.toString()));
    }
  }

  Future<void> _onSendEmail(SendEmail event, Emitter<EmailState> emit) async {
    try {
      emit(EmailLoading());
      await _emailRepository.sendEmail(event.email);
      final emails = await _getEmailsForCurrentTab(0);
      emit(EmailLoaded(emails: emails));
    } catch (e) {
      emit(EmailError(e.toString()));
    }
  }

  Future<void> _onRefreshEmails(
    RefreshEmails event,
    Emitter<EmailState> emit,
  ) async {
    final currentState = state;
    if (currentState is EmailLoaded) {
      emit(currentState.copyWith(isRefreshing: true));
      try {
        final emails = await _getEmailsForCurrentTab(currentState.currentTab);
        emit(currentState.copyWith(emails: emails, isRefreshing: false));
      } catch (e) {
        emit(EmailError(e.toString()));
      }
    }
  }

  Future<void> _onChangeTab(ChangeTab event, Emitter<EmailState> emit) async {
    final currentState = state;
    if (currentState is EmailLoaded) {
      final emails = await _getEmailsForCurrentTab(event.index);
      emit(currentState.copyWith(currentTab: event.index, emails: emails));
    }
  }

  Future<void> _onDeleteEmail(
    DeleteEmail event,
    Emitter<EmailState> emit,
  ) async {
    final currentState = state;
    await _emailRepository.moveToTrash(event.id);
    if (currentState is EmailLoaded) {
      final emails = await _getEmailsForCurrentTab(currentState.currentTab);
      emit(currentState.copyWith(emails: emails));
    }
  }

  Future<void> _onRestoreEmail(
    RestoreEmail event,
    Emitter<EmailState> emit,
  ) async {
    final currentState = state;
    await _emailRepository.restoreFromTrash(event.id);
    if (currentState is EmailLoaded) {
      final emails = await _getEmailsForCurrentTab(currentState.currentTab);
      emit(currentState.copyWith(emails: emails));
    }
  }

  Future<void> _onToggleStarEmail(
    ToggleStarEmail event,
    Emitter<EmailState> emit,
  ) async {
    final currentState = state;
    await _emailRepository.toggleStar(event.id);
    if (currentState is EmailLoaded) {
      final emails = await _getEmailsForCurrentTab(currentState.currentTab);
      emit(currentState.copyWith(emails: emails));
    }
  }

  Future<void> _onMarkEmailAsRead(
    MarkEmailAsRead event,
    Emitter<EmailState> emit,
  ) async {
    final currentState = state;
    await _emailRepository.markRead(event.id);
    await _notificationService.markAsRead(event.id);

    if (currentState is EmailLoaded) {
      final emails = await _getEmailsForCurrentTab(currentState.currentTab);
      emit(currentState.copyWith(emails: emails));
    }
  }

  Future<void> _onNewEmailReceived(
    NewEmailReceived event,
    Emitter<EmailState> emit,
  ) async {
    final currentState = state;

    await _notificationService.showEmailNotification(
      sender: event.email.sender ?? 'Unknown',
      subject: event.email.subject ?? 'No Subject',
      receivedTime: event.email.createdAt ?? DateTime.now(),
      emailId: event.email.id,
    );

    _notificationBloc.add(
      AddNotification(
        NotificationItem(
          id: event.email.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
          sender: event.email.sender ?? 'Unknown',
          subject: event.email.subject ?? 'No Subject',
          time: event.email.createdAt ?? DateTime.now(),
          isRead: false,
        ),
      ),
    );

    // AUTO ANSWER LOGIC
    final settingsState = settingsBloc.state;
    if (settingsState.autoAnswerEnabled && event.email.sender != null) {
      // Lấy email người dùng hiện tại
      String? myEmail;
      final authState = authBloc.state;
      if (authState is LoadProfileSuccess) {
        myEmail = authState.user.email;
      }
      if (myEmail != null) {
        final autoAnswerEmail = Email(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          sender: myEmail,
          to: [event.email.sender!],
          cc: [],
          bcc: [],
          subject: 'Re: ${event.email.subject ?? ''}',
          content: [settingsState.autoAnswerContent],
          plainTextContent: settingsState.autoAnswerContent,
          time: DateTime.now(),
          attachments: [],
          labels: [],
        );
        await _emailRepository.sendEmail(autoAnswerEmail);
      }
    }

    if (currentState is EmailLoaded && currentState.currentTab == 0) {
      final updatedList = [event.email, ...currentState.emails];
      emit(currentState.copyWith(emails: updatedList));
    }
  }

  Future<List<EmailResponseModel>> _getEmailsForCurrentTab(int tabIndex) async {
    switch (tabIndex) {
      case 0:
        return await _emailRepository.getEmails();
      case 1:
        return await _emailRepository.getStarred();
      case 2:
        return await _emailRepository.getSent();
      case 3:
        return await _emailRepository.getDrafts();
      case 4:
        return await _emailRepository.getTrash();
      default:
        return await _emailRepository.getEmails();
    }
  }

  @override
  Future<void> close() {
    _emailRepository.dispose();
    return super.close();
  }
}
