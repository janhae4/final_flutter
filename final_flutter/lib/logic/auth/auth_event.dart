import 'dart:io';
import 'dart:typed_data';


abstract class AuthEvent {}

class AppStarted extends AuthEvent {}

class LoginRequested extends AuthEvent {
  final String phone;
  final String password;
  LoginRequested(this.phone, this.password);
}

class SubmitTwoFactor extends AuthEvent {
  final String code;
  final String token;
  SubmitTwoFactor(this.code, this.token);
}

class EnableTwoFactor extends AuthEvent {
  final String code;
  EnableTwoFactor(this.code);
}

class GenerateQrCode extends AuthEvent {}

class DisableTwoFactor extends AuthEvent {
  final String password;
  final String code;
  DisableTwoFactor(this.password, this.code);
}

class RegisterRequested extends AuthEvent {
  final String phone;
  final String password;
  final String name;
  RegisterRequested(this.name, this.phone, this.password);
}

class UpdateRequested extends AuthEvent {
  final String name;
  final String email;
  final String phone;
  UpdateRequested(this.name, this.email, this.phone);
}

class PickImageRequested extends AuthEvent {
  final File imageFile;
  PickImageRequested(this.imageFile);
}

class PickImageRequestedWeb extends AuthEvent {
  final Uint8List bytes;
  final String fileName;
  PickImageRequestedWeb({required this.bytes, required this.fileName});
}

class UpdatePasswordRequested extends AuthEvent {
  final String oldPassword;
  final String newPassword;
  UpdatePasswordRequested(this.oldPassword, this.newPassword);
}

class LoadProfile extends AuthEvent {}

class LogoutRequested extends AuthEvent {}

class AddLabel extends AuthEvent {
  final String label;
  AddLabel(this.label);
}

class RemoveLabel extends AuthEvent {
  final String label;
  RemoveLabel(this.label);
}

class DeleteLabel extends AuthEvent {
  final String label;
  DeleteLabel(this.label);
}

class UpdateLabel extends AuthEvent {
  final String id;
  final String label;
  UpdateLabel(this.id, this.label);
}

class LoadLabels extends AuthEvent {}

class PasswordRecovery extends AuthEvent {
  final String? otp;
  PasswordRecovery(this.otp);
}