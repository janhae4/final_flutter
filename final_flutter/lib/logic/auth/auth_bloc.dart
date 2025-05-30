import 'package:final_flutter/logic/auth/auth_event.dart';
import 'package:final_flutter/logic/auth/auth_repository.dart';
import 'package:final_flutter/logic/auth/auth_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository repository;

  AuthBloc(this.repository) : super(AuthInitial()) {
    on<AppStarted>((event, emit) async {
      final token = await repository.getToken();

      if (token == null) {
        emit(Unauthenticated());
        return;
      }

      try {
        final user = await repository.getCurrentUser(token);
        if (user != null) {
          emit(Authenticated());
        } else {
          emit(Unauthenticated());
        }
      } catch (e) {
        emit(Unauthenticated());
      }
    });

    on<LoadProfile>((event, emit) async {
      emit(AuthLoading());
      try {
        final token = await repository.getToken();
        final user = await repository.getCurrentUser(token!);
        emit(LoadProfileSuccess(user!));
      } catch (e) {
        emit(Unauthenticated());
      }
    });

    on<LoginRequested>((event, emit) async {
      emit(AuthLoading());
      try {
        final res = await repository.login(event.phone, event.password);
        if (res.requires2FA) {
          emit(TwoFactorRequired(res.tempToken!));
        } else {
          emit(Authenticated());
        }
      } catch (e) {
        emit(AuthError(e.toString()));
        emit(Unauthenticated());
      }
    });

    on<SubmitTwoFactor>((event, emit) async {
      emit(AuthLoading());
      try {
        await repository.verifyTwoFactorCode(event.code, event.token);
        emit(Authenticated());
      } catch (e) {
        emit(AuthError(e.toString()));
        emit(Unauthenticated());
      }
    });

    on<GenerateQrCode>((event, emit) async {
      emit(AuthLoading());
      try {
        final response = await repository.generateQr();
        emit(QRCodeGenerated(response['qrCode']!, response['secretKey']!));
      } catch (e) {
        emit(AuthError(e.toString()));
        emit(Unauthenticated());
      }
    });

    on<EnableTwoFactor>((event, emit) async {
      emit(AuthLoading());
      try {
        final res = await repository.enable2FA(event.code);
        emit(UpdateSuccess('2FA enabled successfully'));
        emit(TwoFactorEnabled(res));
      } catch (e) {
        emit(AuthError(e.toString()));
        emit(Unauthenticated());
      }
    });

    on<DisableTwoFactor>((event, emit) async {
      emit(AuthLoading());
      try {
        await repository.disable2FA(event.password, event.code);
        emit(UpdateSuccess('2FA disabled successfully'));
        emit(TwoFactorDisabled());
      } catch (e) {
        emit(AuthError(e.toString()));
        emit(Unauthenticated());
      }
    });

    on<RegisterRequested>((event, emit) async {
      emit(AuthLoading());
      try {
        await repository.register(event.name, event.phone, event.password);
        emit(Authenticated());
      } catch (e) {
        emit(AuthError(e.toString()));
        emit(Unauthenticated());
      }
    });

    on<LogoutRequested>((event, emit) async {
      await repository.logout();
      emit(Unauthenticated());
    });

    on<UpdateRequested>((event, emit) async {
      try {
        final user = await repository.updateProfile(
          event.name,
          event.phone,
          event.email,
        );
        emit(UpdateSuccess('Profile updated successfully'));
        emit(UpdateProfile(user));
      } catch (e) {
        emit(UpdateError(e.toString()));
      }
    });

    on<UpdatePasswordRequested>((event, emit) async {
      try {
        final message = await repository.updatePassword(
          event.oldPassword,
          event.newPassword,
        );
        emit(UpdateSuccess(message));
      } catch (e) {
        emit(UpdateError(e.toString()));
      }
    });

    on<PickImageRequested>((event, emit) async {
      try {
        var user = await repository.uploadImageToBackend(event.imageFile);
        emit(UpdateSuccess('Image uploaded successfully'));
        emit(UpdateProfile(user));
      } catch (e) {
        emit(UpdateError(e.toString()));
      }
    });

    on<PickImageRequestedWeb>((event, emit) async {
      try {
        var user = await repository.uploadImageToBackendWeb(
          event.bytes,
          event.fileName,
        );
        emit(UpdateSuccess('Image uploaded successfully'));
        emit(UpdateProfile(user));
      } catch (e) {
        emit(UpdateError(e.toString()));
      }
    });
  }
}
