import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../logic/settings/settings_bloc.dart';
import '../../../logic/settings/settings_event.dart';
import '../../../logic/settings/settings_state.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final TextEditingController _autoAnswerController;

  @override
  void initState() {
    super.initState();
    final state = context.read<SettingsBloc>().state;
    _autoAnswerController = TextEditingController(text: state.autoAnswerContent);
  }

  @override
  void didUpdateWidget(covariant SettingsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    final state = context.read<SettingsBloc>().state;
    if (_autoAnswerController.text != state.autoAnswerContent) {
      _autoAnswerController.text = state.autoAnswerContent;
    }
  }

  @override
  void dispose() {
    _autoAnswerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingsBloc, SettingsState>(
      builder: (context, state) {
        // Đảm bảo controller luôn đồng bộ với state
        if (_autoAnswerController.text != state.autoAnswerContent) {
          _autoAnswerController.text = state.autoAnswerContent;
        }
        final fontFamily = state.fontFamily;
        final fontSize = state.fontSize;
        return Scaffold(
          appBar: AppBar(
            title: Text('Settings', style: Theme.of(context).appBarTheme.titleTextStyle),
            centerTitle: true,
            leading: const BackButton(),
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              SwitchListTile(
                title: Text('Enable Notifications', style: Theme.of(context).textTheme.bodyLarge),
                value: state.notificationsEnabled,
                onChanged: (val) => context.read<SettingsBloc>().add(ToggleNotifications(val)),
              ),
              const SizedBox(height: 16),
              ListTile(
                title: Text('Font Size', style: Theme.of(context).textTheme.bodyLarge),
                trailing: DropdownButton<double>(
                  value: state.fontSize,
                  items: [14, 16, 18, 20]
                      .map((size) => DropdownMenuItem(
                            value: size.toDouble(),
                            child: Text('$size', style: Theme.of(context).textTheme.bodyLarge),
                          ))
                      .toList(),
                  onChanged: (val) => context.read<SettingsBloc>().add(ChangeFontSize(val!)),
                ),
              ),
              ListTile(
                title: Text('Font Family', style: Theme.of(context).textTheme.bodyLarge),
                trailing: DropdownButton<String>(
                  value: state.fontFamily,
                  items: ['Roboto', 'Montserrat', 'NotoSans', 'Lato']
                      .map((font) => DropdownMenuItem(
                            value: font,
                            child: Text(font, style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontFamily: font)),
                          ))
                      .toList(),
                  onChanged: (val) => context.read<SettingsBloc>().add(ChangeFontFamily(val!)),
                ),
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: Text('Dark Mode', style: Theme.of(context).textTheme.bodyLarge),
                value: state.isDarkMode,
                onChanged: (val) => context.read<SettingsBloc>().add(ToggleDarkMode(val)),
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: Text('Auto Answer Mode', style: Theme.of(context).textTheme.bodyLarge),
                value: state.autoAnswerEnabled,
                onChanged: (val) => context.read<SettingsBloc>().add(ToggleAutoAnswer(val)),
              ),
              if (state.autoAnswerEnabled)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: TextField(
                    decoration: InputDecoration(
                      labelText: 'Auto Answer Content',
                      border: const OutlineInputBorder(),
                      filled: true,
                      fillColor: Theme.of(context).colorScheme.surface,
                      labelStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    minLines: 1,
                    maxLines: 3,
                    style: Theme.of(context).textTheme.bodyMedium,
                    controller: _autoAnswerController,
                    onChanged: (val) {
                      if (val != state.autoAnswerContent) {
                        context.read<SettingsBloc>().add(ChangeAutoAnswerContent(val));
                      }
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
