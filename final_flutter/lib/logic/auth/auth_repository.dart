import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:final_flutter/data/models/user_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthRepository {
  final String backendUrl = 'http://localhost:3000/api/auth';

  Future<UserModel?> getCurrentUser(String token) async {
    final res = await http.get(
      Uri.parse('$backendUrl/profile'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (res.statusCode == 200) {
      final json = jsonDecode(res.body);
      return UserModel.fromJson(json['user']);
    }
    return null;
  }

  Future<UserModel> login(String phone, String password) async {
    final res = await http.post(
      Uri.parse('$backendUrl/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': phone, 'password': password}),
    );

    if (res.statusCode != 200) {
      final errorMessage = jsonDecode(res.body)['message'] ?? 'Login failed';
      throw Exception(errorMessage);
    }

    final json = jsonDecode(res.body);
    final token = json['token'];
    print(token);
    print(json['user']);
    await saveToken(token);
    return UserModel.fromJson(json['user']);
  }

  Future<UserModel> register(String phone, String password) async {
    final res = await http.post(
      Uri.parse('$backendUrl/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': phone, 'password': password}),
    );

    if (res.statusCode != 201) {
      final errorMessage = jsonDecode(res.body)['message'] ?? 'Register failed';
      throw Exception(errorMessage);
    }

    final json = jsonDecode(res.body);
    final token = json['token'];
    await saveToken(token);
    return UserModel.fromJson(json['user']);
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
  }

  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }
}
