import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../logic/settings/settings_bloc.dart';
import '../../../logic/settings/settings_event.dart';
import '../../../logic/settings/settings_state.dart';
import '../../../config/app_theme.dart';

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
    _autoAnswerController = TextEditingController(
      text: state.autoAnswerContent,
    );
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
        if (_autoAnswerController.text != state.autoAnswerContent) {
          _autoAnswerController.text = state.autoAnswerContent;
        }

        return Scaffold(
          backgroundColor:
              state.isDarkMode
                  ? AppColors.backgroundDark
                  : AppColors.background,
          appBar: AppBar(
            title: Text(
              'Settings',
              style: TextStyle(
                color:
                    state.isDarkMode
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            elevation: 0,
            backgroundColor:
                state.isDarkMode ? AppColors.surfaceDark : AppColors.surface,
            foregroundColor:
                state.isDarkMode
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimary,
            centerTitle: true,
          ),
          body: LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 1000;
              return SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: MediaQuery.of(context).size.height - 100,
                  ),
                  child:
                      isWide
                          ? Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 400,
                                child: _buildGeneralSettingsSection(state),
                              ),
                              const SizedBox(width: 20),
                              SizedBox(
                                width: 400,
                                child: _buildAppearanceSettingsSection(state),
                              ),
                            ],
                          )
                          : Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              _buildGeneralSettingsSection(state),
                              const SizedBox(height: 20),
                              _buildAppearanceSettingsSection(state),
                            ],
                          ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildGeneralSettingsSection(SettingsState state) {
    return Container(
      decoration: BoxDecoration(
        color: state.isDarkMode ? AppColors.surfaceDark : AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: (state.isDarkMode
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimary)
                .withAlpha((255 * 0.05).toInt()),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.primary,
                  AppColors.primaryDark.withOpacity(0.8),
                ],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: const Text(
              'General Settings',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.surface,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildSettingsTile(
                  icon: Icons.notifications_outlined,
                  title: 'Notifications',
                  subtitle: 'Enable push notifications',
                  color: AppColors.secondary,
                  trailing: Switch(
                    value: state.notificationsEnabled,
                    onChanged:
                        (val) => context.read<SettingsBloc>().add(
                          ToggleNotifications(val),
                        ),
                    activeColor: AppColors.secondary,
                  ),
                  state: state,
                ),
                _buildDivider(state),
                _buildSettingsTile(
                  icon: Icons.dark_mode_outlined,
                  title: 'Dark Mode',
                  subtitle: 'Toggle dark theme',
                  color:
                      state.isDarkMode
                          ? AppColors.accent
                          : AppColors.surfaceVariant,
                  trailing: Switch(
                    value: context.watch<SettingsBloc>().state.isDarkMode,
                    onChanged:
                        (val) => context.read<SettingsBloc>().add(
                          ToggleDarkMode(val),
                        ),
                    activeColor: AppColors.accent,
                  ),
                  state: state,
                ),
                _buildDivider(state),
                _buildAutoAnswerSection(state),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppearanceSettingsSection(SettingsState state) {
    return Container(
      decoration: BoxDecoration(
        color: state.isDarkMode ? AppColors.surfaceDark : AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: (state.isDarkMode
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimary)
                .withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.secondary, AppColors.secondaryDark],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: const Text(
              'Appearance',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.surface,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildFontSizeSection(state),
                _buildDivider(state),
                _buildFontFamilySection(state),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    Widget? trailing,
    required SettingsState state,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color, size: 24),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color:
              state.isDarkMode
                  ? AppColors.textPrimaryDark
                  : AppColors.textPrimary,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color:
              state.isDarkMode
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondary,
          fontSize: 12,
        ),
      ),
      trailing: trailing,
    );
  }

  Widget _buildFontSizeSection(SettingsState state) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(
          Icons.format_size,
          color: AppColors.primary,
          size: 24,
        ),
      ),
      title: Text(
        'Font Size',
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color:
              state.isDarkMode
                  ? AppColors.textPrimaryDark
                  : AppColors.textPrimary,
        ),
      ),
      subtitle: Text(
        'Current: ${state.fontSize.toInt()}px',
        style: TextStyle(
          color:
              state.isDarkMode
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondary,
          fontSize: 12,
        ),
      ),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.primary.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: DropdownButton<double>(
          value: state.fontSize,
          underline: const SizedBox(),
          icon: const Icon(Icons.arrow_drop_down, color: AppColors.primary),
          items:
              [14, 16, 18, 20, 22, 24]
                  .map(
                    (size) => DropdownMenuItem(
                      value: size.toDouble(),
                      child: Text(
                        '${size}px',
                        style: TextStyle(
                          color:
                              state.isDarkMode
                                  ? AppColors.textPrimaryDark
                                  : AppColors.textPrimary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  )
                  .toList(),
          onChanged:
              (val) => context.read<SettingsBloc>().add(ChangeFontSize(val!)),
        ),
      ),
    );
  }

  Widget _buildFontFamilySection(SettingsState state) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.secondary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(
          Icons.font_download,
          color: AppColors.secondary,
          size: 24,
        ),
      ),
      title: Text(
        'Font Family',
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color:
              state.isDarkMode
                  ? AppColors.textPrimaryDark
                  : AppColors.textPrimary,
        ),
      ),
      subtitle: Text(
        'Current: ${state.fontFamily}',
        style: TextStyle(
          color:
              state.isDarkMode
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondary,
          fontSize: 12,
        ),
      ),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.secondary.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: DropdownButton<String>(
          value: state.fontFamily,
          underline: const SizedBox(),
          icon: const Icon(Icons.arrow_drop_down, color: AppColors.secondary),
          items:
              ['Roboto', 'Montserrat', 'NotoSans', 'Lato', 'Poppins', 'Inter']
                  .map(
                    (font) => DropdownMenuItem(
                      value: font,
                      child: Text(
                        font,
                        style: TextStyle(
                          fontFamily: font,
                          color:
                              state.isDarkMode
                                  ? AppColors.textPrimaryDark
                                  : AppColors.textPrimary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  )
                  .toList(),
          onChanged:
              (val) => context.read<SettingsBloc>().add(ChangeFontFamily(val!)),
        ),
      ),
    );
  }

  Widget _buildAutoAnswerSection(SettingsState state) {
    return Column(
      children: [
        _buildSettingsTile(
          icon: Icons.auto_awesome_outlined,
          title: 'Auto Answer Mode',
          subtitle: 'Automatically respond to messages',
          color: AppColors.accent,
          trailing: Switch(
            value: state.autoAnswerEnabled,
            onChanged:
                (val) =>
                    context.read<SettingsBloc>().add(ToggleAutoAnswer(val)),
            activeColor: AppColors.accent,
          ),
          state: state,
        ),
        if (state.autoAnswerEnabled) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.accent.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.accent.withOpacity(0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.message_outlined,
                      color: AppColors.accent,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Auto Answer Content',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color:
                            state.isDarkMode
                                ? AppColors.textPrimaryDark
                                : AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _autoAnswerController,
                  decoration: InputDecoration(
                    hintText: 'Enter your auto-reply message...',
                    hintStyle: TextStyle(
                      color:
                          state.isDarkMode
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondary,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: AppColors.accent.withOpacity(0.3),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(
                        color: AppColors.accent,
                        width: 2,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: (state.isDarkMode
                                ? AppColors.borderDark
                                : AppColors.surfaceVariant)
                            .withOpacity(0.3),
                      ),
                    ),
                    filled: true,
                    fillColor:
                        state.isDarkMode
                            ? AppColors.surfaceVariantDark
                            : AppColors.surface,
                    contentPadding: const EdgeInsets.all(12),
                  ),
                  minLines: 2,
                  maxLines: 4,
                  style: TextStyle(
                    color:
                        state.isDarkMode
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimary,
                  ),
                  onChanged: (val) {
                    if (val != state.autoAnswerContent) {
                      context.read<SettingsBloc>().add(
                        ChangeAutoAnswerContent(val),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildDivider(SettingsState state) {
    return Divider(
      height: 1,
      color: state.isDarkMode ? AppColors.dividerDark : AppColors.divider,
      indent: 16,
      endIndent: 16,
    );
  }
}
