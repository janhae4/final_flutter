import 'auth_repository.dart';
import 'package:final_flutter/data/models/user_model.dart';

class MockAuthRepository extends AuthRepository {
  String? _token;
  UserModel? _user;

  @override
  Future<String?> getToken() async {
    return _token;
  }

  @override
  Future<UserModel?> getCurrentUser(String token) async {
    if (_token == token && _user != null) {
      return _user;
    }
    return null;
  }

  @override
  Future<UserModel> login(String phone, String password) async {
    _token = 'mock_token';
    _user = UserModel(uid: '1', phone: phone);
    return _user!;
  }

  @override
  Future<UserModel> register(String phone, String password) async {
    _token = 'mock_token';
    _user = UserModel(uid: '2', phone: phone);
    return _user!;
  }

  @override
  Future<void> logout() async {
    _token = null;
    _user = null;
  }

  @override
  Future<void> saveToken(String token) async {
    _token = token;
  }
} 