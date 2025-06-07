import 'package:final_flutter/data/models/email.dart';
import 'package:final_flutter/data/models/email_response_model.dart';

class EmailThread {
  final Email email;
  final List<EmailResponseModel>? replies;
  EmailThread({required this.email, this.replies});
}
