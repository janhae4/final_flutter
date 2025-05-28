abstract class AuthEvent {}

class AppStarted extends AuthEvent {}
class LoginRequested extends AuthEvent {
  final String phone;
  final String password;
  LoginRequested(this.phone, this.password);
}
class RegisterRequested extends AuthEvent {
  final String phone;
  final String password;
  RegisterRequested(this.phone, this.password);
}
class LogoutRequested extends AuthEvent {}
