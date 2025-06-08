import 'package:equatable/equatable.dart';

abstract class SettingsEvent extends Equatable {
  const SettingsEvent();
  @override
  List<Object?> get props => [];
}

/// Event to toggle notifications on/off.
class ToggleNotifications extends SettingsEvent {
  final bool enabled;
  const ToggleNotifications(this.enabled);
  @override
  List<Object?> get props => [enabled];
}

/// Event to change the font size.
class ChangeFontSize extends SettingsEvent {
  final double fontSize;
  const ChangeFontSize(this.fontSize);
  @override
  List<Object?> get props => [fontSize];
}

/// Event to change the font family.
class ChangeFontFamily extends SettingsEvent {
  final String fontFamily;
  const ChangeFontFamily(this.fontFamily);
  @override
  List<Object?> get props => [fontFamily];
}

/// Event to toggle dark mode on/off.
class ToggleDarkMode extends SettingsEvent {
  final bool enabled;
  const ToggleDarkMode(this.enabled);
  @override
  List<Object?> get props => [enabled];
}

/// Event to toggle auto answer mode on/off.
class ToggleAutoAnswer extends SettingsEvent {
  final bool enabled;
  const ToggleAutoAnswer(this.enabled);
  @override
  List<Object?> get props => [enabled];
}

/// Event to change the content of auto answer.
class ChangeAutoAnswerContent extends SettingsEvent {
  final String content;
  const ChangeAutoAnswerContent(this.content);
  @override
  List<Object?> get props => [content];
}

class LoadSettingsEvent extends SettingsEvent {}