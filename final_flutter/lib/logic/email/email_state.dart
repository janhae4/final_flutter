import 'package:final_flutter/data/models/email.dart';
import 'package:final_flutter/data/models/email_response_model.dart';
abstract class EmailState {}

class EmailInitial extends EmailState {}

class EmailLoading extends EmailState {}

class EmailLoaded extends EmailState {
  final List<EmailResponseModel> emails;
  final int currentTab;
  final bool isRefreshing;
  final String searchQuery;

  EmailLoaded({
    required this.emails,
    this.currentTab = 0,
    this.isRefreshing = false,
    this.searchQuery = '',
  });

  EmailLoaded copyWith({
    List<EmailResponseModel>? emails,
    int? currentTab,
    bool? isRefreshing,
    String? searchQuery,
  }) {
    return EmailLoaded(
      emails: emails ?? this.emails,
      currentTab: currentTab ?? this.currentTab,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

class EmailDetailLoaded extends EmailState {
  final Email email;
  EmailDetailLoaded({required this.email});
}

class EmailError extends EmailState {
  final String message;
  EmailError(this.message);
}
