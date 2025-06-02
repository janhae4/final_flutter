import 'package:final_flutter/data/models/email.dart';
import 'package:final_flutter/data/models/email_response_model.dart';

abstract class EmailEvent {}

class LoadEmails extends EmailEvent {
  final int tab;
  LoadEmails(this.tab);
}

class LoadEmailDetail extends EmailEvent {
  final String id;
  LoadEmailDetail(this.id);
}

class RefreshEmails extends EmailEvent {}

class SendEmail extends EmailEvent {
  final Email email;
  SendEmail(this.email);
}

class ChangeTab extends EmailEvent {
  final int index;
  ChangeTab(this.index);
}

class SearchEmails extends EmailEvent {
  final String query;
  SearchEmails(this.query);
}

class DeleteEmail extends EmailEvent {
  final String id;
  DeleteEmail(this.id);
}

class RestoreEmail extends EmailEvent {
  final String id;
  RestoreEmail(this.id);
}

class ToggleStarEmail extends EmailEvent {
  final String id;
  ToggleStarEmail(this.id);
}

class MarkEmailAsRead extends EmailEvent {
  final String id;
  final bool isRead;
  MarkEmailAsRead(this.id, this.isRead);
}

class DeleteEmails extends EmailEvent {
  final List<String> emailIds;
  DeleteEmails(this.emailIds);
}

class ToggleStarEmails extends EmailEvent {
  final List<String> emailIds;
  ToggleStarEmails(this.emailIds);
}

class MarkEmailsAsRead extends EmailEvent {
  final List<String> emailIds;
  final bool isRead;
  MarkEmailsAsRead(this.emailIds, this.isRead);
}

class EmailReceived extends EmailEvent {
  final Email email;
  EmailReceived(this.email);
}

class NewEmailReceived extends EmailEvent {
  final EmailResponseModel email;
  NewEmailReceived(this.email);
}

class EmailConnectSocket extends EmailEvent {}