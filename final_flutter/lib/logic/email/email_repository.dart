import 'dart:convert';

import 'package:final_flutter/data/models/email.dart';
import 'package:final_flutter/data/models/email_response_model.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class EmailRepository {
  final backendUrl = 'http://localhost:3000/api/email';
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<List<EmailResponseModel>> getEmails() async {
    final token = await getToken();
    final res = await http.get(
      Uri.parse(backendUrl),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (res.statusCode != 200) {
      final errorMessage = jsonDecode(res.body)['message'] ?? 'Login failed';
      throw Exception(errorMessage);
    }

    final json = jsonDecode(res.body);
    print(json);
    return json.map<EmailResponseModel>((e) => EmailResponseModel.fromJson(e)).toList();
  }

  Future<Email> getEmailDetail(String id) async {
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
    print(json);
    return Email.fromJson(json);
  }

  Future<List<EmailResponseModel>> getSent () async {
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
    return json.map<EmailResponseModel>((e) => EmailResponseModel.fromJson(e)).toList();
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
    return json.map<EmailResponseModel>((e) => EmailResponseModel.fromJson(e)).toList();
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
    return json.map<EmailResponseModel>((e) => EmailResponseModel.fromJson(e)).toList();
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
    return json.map<EmailResponseModel>((e) => EmailResponseModel.fromJson(e)).toList();
  }

  Future<void> sendEmail(Email email) async {
    final token = await getToken();
    final res = await http.post(
      Uri.parse(backendUrl),
      headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
      body: jsonEncode(email.toJson()),
    );
    if (res.statusCode != 200) {
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
}
