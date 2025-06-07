import 'package:equatable/equatable.dart';

class SettingsState extends Equatable {
  final bool notificationsEnabled;
  final bool isDarkMode;
  final bool autoAnswerEnabled;
  final String autoAnswerContent;
  final double fontSize;
  final String fontFamily;

  const SettingsState({
    this.notificationsEnabled = true,
    this.isDarkMode = false,
    this.autoAnswerEnabled = false,
    this.autoAnswerContent = "I'm currently unavailable. I will reply soon.",
    this.fontSize = 16,
    this.fontFamily = 'Roboto',
  });

  SettingsState copyWith({
    bool? notificationsEnabled,
    bool? isDarkMode,
    bool? autoAnswerEnabled,
    String? autoAnswerContent,
    double? fontSize,
    String? fontFamily,
  }) {
    return SettingsState(
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      isDarkMode: isDarkMode ?? this.isDarkMode,
      autoAnswerEnabled: autoAnswerEnabled ?? this.autoAnswerEnabled,
      autoAnswerContent: autoAnswerContent ?? this.autoAnswerContent,
      fontSize: fontSize ?? this.fontSize,
      fontFamily: fontFamily ?? this.fontFamily,
    );
  }

  @override
  List<Object?> get props => [
    notificationsEnabled,
    isDarkMode,
    autoAnswerEnabled,
    autoAnswerContent,
    fontSize,
    fontFamily,
  ];
}
