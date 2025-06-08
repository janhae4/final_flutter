import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'settings_event.dart';
import 'settings_state.dart';

class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  SettingsBloc() : super(const SettingsState()) {
    on<LoadSettingsEvent>(_onLoadSettings);
    on<ToggleDarkMode>(_onToggleDarkMode);
    on<ToggleNotifications>(
      (event, emit) =>
          emit(state.copyWith(notificationsEnabled: event.enabled)),
    );
    on<ChangeFontSize>(
      (event, emit) => emit(state.copyWith(fontSize: event.fontSize)),
    );
    on<ChangeFontFamily>(
      (event, emit) => emit(state.copyWith(fontFamily: event.fontFamily)),
    );
    on<ToggleAutoAnswer>(
      (event, emit) => emit(state.copyWith(autoAnswerEnabled: event.enabled)),
    );
    on<ChangeAutoAnswerContent>(
      (event, emit) => emit(state.copyWith(autoAnswerContent: event.content)),
    );
  }

  Future<void> _onLoadSettings(
    LoadSettingsEvent event,
    Emitter<SettingsState> emit,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final isDark = prefs.getBool('isDarkMode') ?? false;

    emit(state.copyWith(isDarkMode: isDark));
  }

  Future<void> _onToggleDarkMode(
    ToggleDarkMode event,
    Emitter<SettingsState> emit,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', event.enabled);
    emit(state.copyWith(isDarkMode: event.enabled));
  }
}
