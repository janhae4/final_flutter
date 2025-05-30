import 'package:final_flutter/data/models/user_model.dart';

class LoginResult {
  final UserModel? user;
  final String? tempToken;
  final bool requires2FA;

  LoginResult({this.user, this.tempToken, this.requires2FA = false});
}