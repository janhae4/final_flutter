import 'package:final_flutter/data/models/email.dart';
import 'package:final_flutter/data/models/email_response_model.dart';
import 'package:final_flutter/logic/email/email_event.dart';
import 'package:final_flutter/logic/email/email_repository.dart';
import 'package:final_flutter/logic/email/email_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class EmailBloc extends Bloc<EmailEvent, EmailState> {
  final EmailRepository repository;

  EmailBloc({required this.repository}) : super(EmailInitial()) {
    on<LoadEmails>(_onLoadEmails);
    on<LoadEmailDetail>(_onLoadEmailDetail);
    on<SendEmail>(_onSendEmail);
    on<RefreshEmails>(_onRefreshEmails);
    on<ChangeTab>(_onChangeTab);
    // on<SearchEmails>(_onSearchEmails);
    on<DeleteEmail>(_onDeleteEmail);
    on<RestoreEmail>(_onRestoreEmail);
    on<ToggleStarEmail>(_onToggleStarEmail);
    on<MarkEmailAsRead>(_onMarkEmailAsRead);
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
      final email = await repository.getEmailDetail(event.id);
      emit(EmailDetailLoaded(email: email));
    } catch (e) {
      emit(EmailError(e.toString()));
    }
  }

  Future<void> _onSendEmail(SendEmail event, Emitter<EmailState> emit) async {
    try {
      emit(EmailLoading());
      await repository.sendEmail(event.email);
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
        await _getEmailsForCurrentTab(currentState.currentTab);
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

  // Future<void> _onSearchEmails(SearchEmails event, Emitter<EmailState> emit) {
  //   final currentState = state;
  //   if (currentState is EmailLoaded) {
  //     final filteredEmails = _filterEmails(
  //       _getEmailsForCurrentTab(currentState.currentTab),
  //       event.query,
  //     );
  //     emit(currentState.copyWith(
  //       emails: filteredEmails,
  //       searchQuery: event.query,
  //     ));
  //   }
  // }

  Future<void> _onDeleteEmail(
    DeleteEmail event,
    Emitter<EmailState> emit,
  ) async {
    final currentState = state;
    await repository.moveToTrash(event.id);
    if (currentState is EmailLoaded) {
      final emails = _getEmailsForCurrentTab(currentState.currentTab);
      emit(currentState.copyWith(emails: await emails));
    }
  }

  Future<void> _onRestoreEmail(
    RestoreEmail event,
    Emitter<EmailState> emit,
  ) async {
    final currentState = state;
    await repository.restoreFromTrash(event.id);
    if (currentState is EmailLoaded) {
      final emails = _getEmailsForCurrentTab(currentState.currentTab);
      emit(currentState.copyWith(emails: await emails));
    }
  }

  Future<void> _onToggleStarEmail(
    ToggleStarEmail event,
    Emitter<EmailState> emit,
  ) async {
    final currentState = state;
    await repository.toggleStar(event.id);
    if (currentState is EmailLoaded) {
      final emails = _getEmailsForCurrentTab(currentState.currentTab);
      emit(currentState.copyWith(emails: await emails));
    }
  }

  Future<void> _onMarkEmailAsRead(
    MarkEmailAsRead event,
    Emitter<EmailState> emit,
  ) async {
    final currentState = state;
    await repository.markRead(event.id);
    if (currentState is EmailLoaded) {
      final emails = _getEmailsForCurrentTab(currentState.currentTab);
      emit(currentState.copyWith(emails: await emails));
    }
  }

  Future<List<EmailResponseModel>> _getEmailsForCurrentTab(int tabIndex) async {
    switch (tabIndex) {
      case 0:
        return await repository.getEmails();
      case 1:
        return await repository.getStarred();
      case 2:
        return await repository.getSent();
      case 3:
        return await repository.getDrafts();
      case 4:
        return await repository.getTrash();
      default:
        return await repository.getEmails();
    }
  }

  // List<Email> _filterEmails(List<Email> emails, String query) {
  //   if (query.isEmpty) return emails;
  //   return emails.where((email) {
  //     return email.subject.toLowerCase().contains(query.toLowerCase()) ||
  //         email.sender.toLowerCase().contains(query.toLowerCase()) ||
  //         email.content.toLowerCase().contains(query.toLowerCase());
  //   }).toList();
  // }
}
