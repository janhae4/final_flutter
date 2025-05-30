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
  Future<void> logout() async {
    _token = null;
    _user = null;
  }

  @override
  Future<void> saveToken(String token) async {
    _token = token;
  }
} 