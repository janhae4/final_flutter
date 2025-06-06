import 'package:final_flutter/data/models/label_model.dart';
import 'package:final_flutter/data/models/user_model.dart';

abstract class AuthState {}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class Authenticated extends AuthState {}

class Unauthenticated extends AuthState {}

class AuthError extends AuthState {
  final String message;
  AuthError(this.message);
}

class UpdateError extends AuthState {
  final String message;
  UpdateError(this.message);
}

class UpdateSuccess extends AuthState {
  final String message;
  UpdateSuccess(this.message);
}

class UpdateProfile extends AuthState {
  final UserModel user;
  UpdateProfile(this.user);
}

class TwoFactorRequired extends AuthState {
  final String tempToken;
  TwoFactorRequired(this.tempToken);
}

class QRCodeGenerated extends AuthState {
  final String qrCodeUrl;
  final String entryKey;
  QRCodeGenerated(this.qrCodeUrl, this.entryKey);
}

class TwoFactorDisabled extends AuthState {}

class TwoFactorEnabled extends AuthState {
  final List<String> backupCodes;
  TwoFactorEnabled(this.backupCodes);
}

class ImageUploaded extends AuthState {
  final String imageUrl;
  ImageUploaded(this.imageUrl);
}

class LoadProfileSuccess extends AuthState {
  final UserModel user;
  LoadProfileSuccess(this.user);
}

class LoadLabelsSuccess extends AuthState {
  final List<LabelModel> labels;
  LoadLabelsSuccess(this.labels);
}
