import 'dart:convert';

import 'package:final_flutter/data/models/email.dart';
import 'package:final_flutter/data/models/email_response_model.dart';
import 'package:final_flutter/data/models/email_thread.dart';
import 'package:final_flutter/data/models/label_model.dart';
import 'package:final_flutter/logic/email/email_event.dart';
import 'package:final_flutter/service/socket_service.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class EmailRepository {
  final backendUrl = 'http://localhost:3000/api/email';
  final _socketService = EmailSocketService();

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }
  Future<List<EmailResponseModel>> getSpam() async {
  final token = await getToken();
  final res = await http.get(
    Uri.parse('$backendUrl/spam'),
    headers: {'Authorization': 'Bearer $token'},
    );
  if (res.statusCode != 200) {
    final errorMessage = jsonDecode(res.body)['message'] ?? 'Get spam emails failed';
    throw Exception(errorMessage);
    }

  final json = jsonDecode(res.body);
  return json
      .map<EmailResponseModel>((e) => EmailResponseModel.fromJson(e))
      .toList();
  }
  Future<void> connectSocket(Function(EmailResponseModel) onNewEmail) async {
    final token = await getToken();
    _socketService.initSocket(token!);
    _socketService.listenForEmails(onNewEmail);
  }

  Future<List<EmailResponseModel>> getEmails() async {
    final token = await getToken();
    final res = await http.get(
      Uri.parse(backendUrl),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (res.statusCode != 200) {
      print(123123123);
      final errorMessage = jsonDecode(res.body)['message'] ?? 'Login failed';
      throw Exception(errorMessage);
    }

    final json = jsonDecode(res.body);
    return json
        .map<EmailResponseModel>((e) => EmailResponseModel.fromJson(e))
        .toList();
  }

  Future<EmailThread> getEmailDetail(String id) async {
    final token = await getToken();
    final res = await http.get(
      Uri.parse('$backendUrl/$id'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (res.statusCode != 200) {
      final errorMessage = jsonDecode(res.body)['message'] ?? 'Login failed';
      throw Exception(errorMessage);
    }

    final json = jsonDecode(res.body);
    return EmailThread(
      email: Email.fromJson(json['email']),
      replies:
          (json['thread'] as List)
              .map((e) => EmailResponseModel.fromJson(e))
              .toList(),
    );
  }

  Future<List<EmailResponseModel>> getSent() async {
    final token = await getToken();
    final res = await http.get(
      Uri.parse('$backendUrl/sent'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (res.statusCode != 200) {
      final errorMessage = jsonDecode(res.body)['message'] ?? 'Login failed';
      throw Exception(errorMessage);
    }

    final json = jsonDecode(res.body);
    return json
        .map<EmailResponseModel>((e) => EmailResponseModel.fromJson(e))
        .toList();
  }

  Future<List<EmailResponseModel>> getDrafts() async {
    final token = await getToken();
    final res = await http.get(
      Uri.parse('$backendUrl/drafts'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (res.statusCode != 200) {
      final errorMessage = jsonDecode(res.body)['message'] ?? 'Login failed';
      throw Exception(errorMessage);
    }

    final json = jsonDecode(res.body);
    return json
        .map<EmailResponseModel>((e) => EmailResponseModel.fromJson(e))
        .toList();
  }

  Future<List<EmailResponseModel>> getTrash() async {
    final token = await getToken();
    final res = await http.get(
      Uri.parse('$backendUrl/trash'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (res.statusCode != 200) {
      final errorMessage = jsonDecode(res.body)['message'] ?? 'Login failed';
      throw Exception(errorMessage);
    }

    final json = jsonDecode(res.body);
    return json
        .map<EmailResponseModel>((e) => EmailResponseModel.fromJson(e))
        .toList();
  }

  Future<List<EmailResponseModel>> getStarred() async {
    final token = await getToken();
    final res = await http.get(
      Uri.parse('$backendUrl/starred'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (res.statusCode != 200) {
      final errorMessage = jsonDecode(res.body)['message'] ?? 'Login failed';
      throw Exception(errorMessage);
    }

    final json = jsonDecode(res.body);
    return json
        .map<EmailResponseModel>((e) => EmailResponseModel.fromJson(e))
        .toList();
  }

  Future<void> sendEmail(Email email) async {
    final token = await getToken();
    final res = await http.post(
      Uri.parse(backendUrl),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(email.toJson()),
    );
    if (res.statusCode != 201) {
      print("SEND EMAIL ERROR");
      final errorMessage = jsonDecode(res.body)['message'] ?? 'Login failed';
      throw Exception(errorMessage);
    }
  }

  Future<void> deleteEmail(String id) async {
    final token = await getToken();
    final res = await http.delete(
      Uri.parse('$backendUrl/$id'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (res.statusCode != 200) {
      final errorMessage = jsonDecode(res.body)['message'] ?? 'Login failed';
      throw Exception(errorMessage);
    }
  }

  Future<void> toggleStar(String id) async {
    final token = await getToken();
    final res = await http.post(
      Uri.parse('$backendUrl/$id/star'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (res.statusCode != 200) {
      final errorMessage = jsonDecode(res.body)['message'] ?? 'Login failed';
      throw Exception(errorMessage);
    }
  }

  Future<void> markRead(String id) async {
    final token = await getToken();
    final res = await http.post(
      Uri.parse('$backendUrl/$id/read'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (res.statusCode != 200) {
      final errorMessage = jsonDecode(res.body)['message'] ?? 'Login failed';
      throw Exception(errorMessage);
    }
  }

  Future<void> moveToTrash(String id) async {
    final token = await getToken();
    final res = await http.post(
      Uri.parse('$backendUrl/$id/trash'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (res.statusCode != 200) {
      final errorMessage = jsonDecode(res.body)['message'] ?? 'Login failed';
      throw Exception(errorMessage);
    }
  }

  Future<void> restoreFromTrash(String id) async {
    final token = await getToken();
    final res = await http.post(
      Uri.parse('$backendUrl/$id/restore'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (res.statusCode != 200) {
      final errorMessage = jsonDecode(res.body)['message'] ?? 'Login failed';
      throw Exception(errorMessage);
    }
  }

  Future<List<EmailResponseModel>> searchEmails(SearchEmail event) async {
    final token = await getToken();

    final uri = Uri.parse('$backendUrl/search').replace(
      queryParameters: {
        if (event.query != null && event.query!.isNotEmpty)
          'query': event.query,
        if (event.from != null && event.from!.isNotEmpty) 'from': event.from,
        if (event.to != null && event.to!.isNotEmpty) 'to': event.to,
        if (event.subject != null && event.subject!.isNotEmpty)
          'subject': event.subject,
        if (event.keyword != null && event.keyword!.isNotEmpty)
          'keyword': event.keyword,
        if (event.fromDate != null)
          'fromDate': event.fromDate!.toIso8601String(),
        if (event.toDate != null) 'toDate': event.toDate!.toIso8601String(),
        if (event.hasAttachments != null)
          'hasAttachments': event.hasAttachments.toString(),
      },
    );

    final res = await http.get(
      uri,
      headers: {'Authorization': 'Bearer $token'},
    );

    if (res.statusCode != 200) {
      final errorMessage = jsonDecode(res.body)['message'] ?? 'Search failed';
      throw Exception(errorMessage);
    }

    final json = jsonDecode(res.body);
    return json
        .map<EmailResponseModel>((e) => EmailResponseModel.fromJson(e))
        .toList();
  }

  Future<List<EmailResponseModel>> getEmailsByLabel(String label) async {
    final token = await getToken();
    final res = await http.get(
      Uri.parse('$backendUrl/labels/$label'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (res.statusCode != 200) {
      final errorMessage =
          jsonDecode(res.body)['message'] ?? 'Get emails by label failed';
      throw Exception(errorMessage);
    }

    final json = jsonDecode(res.body);
    return json
        .map<EmailResponseModel>((e) => EmailResponseModel.fromJson(e))
        .toList();
  }

  Future<void> addLabelToEmail(String emailId, LabelModel label) async {
    final token = await getToken();
    final res = await http.post(
      Uri.parse('$backendUrl/$emailId/labels'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'label': label.toJson()}),
    );
    if (res.statusCode != 200) {
      final errorMessage =
          jsonDecode(res.body)['message'] ?? 'Add label to email failed';
      throw Exception(errorMessage);
    }
  }

  Future<void> removeLabelFromEmail(String emailId, LabelModel label) async {
    final token = await getToken();
    final res = await http.delete(
      Uri.parse('$backendUrl/$emailId/labels/${label.id}'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (res.statusCode != 200) {
      final errorMessage =
          jsonDecode(res.body)['message'] ?? 'Remove label from email failed';
      throw Exception(errorMessage);
    }
  }

  Future<void> saveDraft(Email email) async {
    final token = await getToken();
    final res = await http.post(
      Uri.parse('$backendUrl/drafts'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(email.toJson()),
    );
    if (res.statusCode != 201) {
      final errorMessage =
          jsonDecode(res.body)['message'] ?? 'Save draft failed';
      throw Exception(errorMessage);
    }
  }

  Future<void> deleteDraft(String id) async {
    final token = await getToken();
    final res = await http.delete(
      Uri.parse('$backendUrl/drafts/$id'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (res.statusCode != 200) {
      final errorMessage =
          jsonDecode(res.body)['message'] ?? 'Delete draft failed';
      throw Exception(errorMessage);
    }
  }

  void dispose() {
    _socketService.dispose();
  }
}
