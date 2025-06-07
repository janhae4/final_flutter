import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'settings_event.dart';
import 'settings_state.dart';

class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  SettingsBloc() : super(const SettingsState()) {
    _loadDarkMode();
    on<ToggleNotifications>((event, emit) {
      emit(state.copyWith(notificationsEnabled: event.enabled));
    });
    on<ChangeFontSize>((event, emit) {
      emit(state.copyWith(fontSize: event.fontSize));
    });
    on<ChangeFontFamily>((event, emit) {
      emit(state.copyWith(fontFamily: event.fontFamily));
    });
    on<ToggleDarkMode>((event, emit) async {
      emit(state.copyWith(isDarkMode: event.enabled));
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isDarkMode', event.enabled);
    });
    on<ToggleAutoAnswer>((event, emit) {
      emit(state.copyWith(autoAnswerEnabled: event.enabled));
    });
    on<ChangeAutoAnswerContent>((event, emit) {
      emit(state.copyWith(autoAnswerContent: event.content));
    });
  }

  void _loadDarkMode() async {
    final prefs = await SharedPreferences.getInstance();
    final isDark = prefs.getBool('isDarkMode');
    if (isDark != null && isDark != state.isDarkMode) {
      add(ToggleDarkMode(isDark));
    }
  }
}
