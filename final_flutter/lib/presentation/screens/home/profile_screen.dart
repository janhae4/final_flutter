import 'dart:convert';
import 'dart:io';

import 'package:final_flutter/config/app_theme.dart';
import 'package:final_flutter/logic/auth/auth_bloc.dart';
import 'package:final_flutter/logic/auth/auth_event.dart';
import 'package:final_flutter/logic/auth/auth_state.dart';
import 'package:final_flutter/logic/settings/settings_bloc.dart';
import 'package:final_flutter/logic/settings/settings_state.dart';
import 'package:final_flutter/presentation/screens/home/settings_screen.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:final_flutter/data/models/user_model.dart';
import 'package:final_flutter/logic/auth/auth_repository.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:final_flutter/presentation/widget/profile_backupcode.dart';

class ProfileScreen extends StatefulWidget {
  final UserModel? user;
  const ProfileScreen({super.key, this.user});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool twoStepEnabled = false;
  final authRepository = AuthRepository();
  UserModel? user;

  var nameController = TextEditingController();
  var emailController = TextEditingController();
  var phoneController = TextEditingController();
  var currentPasswordController = TextEditingController();
  var newPasswordController = TextEditingController();
  var confirmPasswordController = TextEditingController();
  var otpController = TextEditingController();
  var passwordRecoveryController = TextEditingController();

  @override
  void initState() {
    super.initState();
    user = widget.user;
    twoStepEnabled = widget.user!.twoStepVerification!;
    nameController = TextEditingController(text: widget.user!.name);
    emailController = TextEditingController(text: widget.user!.email);
    phoneController = TextEditingController(text: widget.user!.phone);
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    currentPasswordController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingsBloc, SettingsState>(
      builder: (context, settingsState) {
        final isDark = settingsState.isDarkMode;
        return Scaffold(
          backgroundColor:
              isDark ? AppColors.backgroundDark : AppColors.background,
          appBar: AppBar(
            title: Text(
              'Profile',
              style: TextStyle(
                color:
                    isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: settingsState.fontSize + 2,
                fontFamily: settingsState.fontFamily,
              ),
            ),
            elevation: 0,
            backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surface,
            foregroundColor:
                isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
            centerTitle: true,
          ),
          body: BlocConsumer<AuthBloc, AuthState>(
            listener: (context, state) {
              if (state is AuthError) {
                _showErrorSnackBar(state.message);
              }
              if (state is UpdateProfile) {
                setState(() {
                  user = state.user;
                });
                twoStepEnabled = user?.twoStepVerification ?? false;
                nameController.text = user?.name ?? '';
                emailController.text = user?.email ?? '';
                phoneController.text = user?.phone ?? '';
              }
              if (state is UpdateError) {
                _showErrorSnackBar(state.message);
              }
              if (state is UpdateSuccess) {
                _showSuccessSnackBar(state.message);
              }
              if (state is QRCodeGenerated) {
                _showTwoStepVerificationDialog(
                  context,
                  state.qrCodeUrl,
                  state.entryKey,
                );
              }
              if (state is TwoFactorEnabled) {
                setState(() {
                  twoStepEnabled = true;
                });
                _showBackupCodesDialog(state.backupCodes);
              }
              if (state is TwoFactorDisabled) {
                setState(() {
                  twoStepEnabled = false;
                });
              }
              if (state is PasswordRecoverySuccess) {
                passwordRecoveryController.text = state.password;
                _showPasswordRecoverySuccessDialog(context);
              }
            },
            builder: (context, state) {
              if (widget.user == null) {
                return Center(
                  child: CircularProgressIndicator(
                    color: isDark ? AppColors.primaryDark : AppColors.primary,
                  ),
                );
              }

              if (user == null) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color:
                            isDark
                                ? AppColors.textTertiaryDark
                                : AppColors.textTertiary,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Unable to load user information',
                        style: TextStyle(
                          fontSize: settingsState.fontSize,
                          color:
                              isDark
                                  ? AppColors.textPrimaryDark
                                  : AppColors.textPrimary,
                          fontFamily: settingsState.fontFamily,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return LayoutBuilder(
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
                              ? IntrinsicHeight(
                                child: Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SizedBox(
                                      width: 300,
                                      child: _buildProfileSection(),
                                    ),
                                    SizedBox(
                                      width: 600,
                                      child: _buildSettingsSection(),
                                    ),
                                  ],
                                ),
                              )
                              : Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  _buildProfileSection(),
                                  const SizedBox(height: 20),
                                  _buildSettingsSection(),
                                ],
                              ),
                    ),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source, imageQuality: 80);

    if (pickedFile != null) {
      if (kIsWeb) {
        // Web: read as bytes
        final bytes = await pickedFile.readAsBytes();
        final fileName = pickedFile.name;

        context.read<AuthBloc>().add(
          PickImageRequestedWeb(bytes: bytes, fileName: fileName),
        );
      } else {
        // Mobile/desktop: pass File object
        final imageFile = File(pickedFile.path);
        context.read<AuthBloc>().add(PickImageRequested(imageFile));
      }
    } else {
      _showErrorSnackBar('No image selected');
    }
  }

  void _onProfileUpdatePressed() {
    final emailLocalPart = emailController.text.trim();
    final email = '$emailLocalPart@gmail.com';
    final name = nameController.text.trim();
    final phone = phoneController.text.trim();

    final emailRegex = RegExp(r"^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$");

    if (!emailRegex.hasMatch(email)) {
      _showErrorSnackBar('Please enter a valid email.');
    }

    context.read<AuthBloc>().add(UpdateRequested(name, email, phone));
    Navigator.pop(context);
  }

  void _onPasswordUpdatePressed() {
    final currentPassword = currentPasswordController.text.trim();
    final newPassword = newPasswordController.text.trim();
    final confirmPassword = confirmPasswordController.text.trim();

    if (newPassword != confirmPassword) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Passwords do not match.')));
      return;
    }
    context.read<AuthBloc>().add(
      UpdatePasswordRequested(currentPassword, newPassword),
    );
    Navigator.pop(context);
  }

  void _onEnableTwoStepPressed(String code) {
    context.read<AuthBloc>().add(EnableTwoFactor(code));
    Navigator.pop(context);
  }

  void _onGenerateQrCodePressed() async {
    context.read<AuthBloc>().add(GenerateQrCode());
  }

  void _onDisableTwoStepPressed(String password, String code) {
    context.read<AuthBloc>().add(DisableTwoFactor(password, code));
    Navigator.pop(context);
  }

  void _showChangePasswordDialog() {
    final settingsState = context.read<SettingsBloc>().state;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: settingsState.isDarkMode ? AppColors.surfaceDark : AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          'Change Password',
          style: TextStyle(
            color: settingsState.isDarkMode ? AppColors.textPrimaryDark : AppColors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: settingsState.fontSize + 2,
            fontFamily: settingsState.fontFamily,
          ),
        ),
        content: SizedBox(
          width: 400,
          height: 300,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildTextField(
                controller: currentPasswordController,
                label: 'Current Password',
                settingsState: settingsState,
                isPassword: true,
              ),
              const SizedBox(height: 24),
              _buildTextField(
                controller: newPasswordController,
                label: 'New Password',
                settingsState: settingsState,
                isPassword: true,
              ),
              const SizedBox(height: 24),
              _buildTextField(
                controller: confirmPasswordController,
                label: 'Confirm Password',
                settingsState: settingsState,
                isPassword: true,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: settingsState.isDarkMode ? AppColors.textPrimaryDark : AppColors.textPrimary,
                fontSize: settingsState.fontSize,
                fontFamily: settingsState.fontFamily,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              _onPasswordUpdatePressed();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Update',
              style: TextStyle(
                color: AppColors.surface,
                fontSize: settingsState.fontSize,
                fontFamily: settingsState.fontFamily,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showPasswordRecoveryDialog() {
    final settingsState = context.read<SettingsBloc>().state;
    final emailController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: settingsState.isDarkMode ? AppColors.surfaceDark : AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          'Password Recovery',
          style: TextStyle(
            color: settingsState.isDarkMode ? AppColors.textPrimaryDark : AppColors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: settingsState.fontSize + 2,
            fontFamily: settingsState.fontFamily,
          ),
        ),
        content: SizedBox(
          width: 400,
          height: 150,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (user!.twoStepVerification!)
                Text(
                  'Enter otp',
                  style: TextStyle(
                    color: settingsState.isDarkMode ? AppColors.textPrimaryDark : AppColors.textPrimary,
                    fontSize: settingsState.fontSize,
                    fontFamily: settingsState.fontFamily,
                  ),
                ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: otpController,
                label: 'OTP',
                settingsState: settingsState,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: settingsState.isDarkMode ? AppColors.textPrimaryDark : AppColors.textPrimary,
                fontSize: settingsState.fontSize,
                fontFamily: settingsState.fontFamily,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<AuthBloc>().add(
                PasswordRecovery(otpController.text.trim()),
              );
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.secondary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Send',
              style: TextStyle(
                color: AppColors.surface,
                fontSize: settingsState.fontSize,
                fontFamily: settingsState.fontFamily,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showPasswordRecoverySuccessDialog(BuildContext context) {
    final settingsState = context.read<SettingsBloc>().state;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: settingsState.isDarkMode ? AppColors.surfaceDark : AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          'Password Recovery',
          style: TextStyle(
            color: settingsState.isDarkMode ? AppColors.textPrimaryDark : AppColors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: settingsState.fontSize + 2,
            fontFamily: settingsState.fontFamily,
          ),
        ),
        content: SizedBox(
          width: 400,
          height: 150,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Your new password is:',
                style: TextStyle(
                  color: settingsState.isDarkMode ? AppColors.textPrimaryDark : AppColors.textPrimary,
                  fontSize: settingsState.fontSize,
                  fontFamily: settingsState.fontFamily,
                ),
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: passwordRecoveryController,
                label: 'New Password',
                settingsState: settingsState,
                isPassword: true,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Close',
              style: TextStyle(
                color: settingsState.isDarkMode ? AppColors.textPrimaryDark : AppColors.textPrimary,
                fontSize: settingsState.fontSize,
                fontFamily: settingsState.fontFamily,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showTwoStepVerificationDialog(
    BuildContext rootContext,
    String qrCodeUrl,
    String entryKey,
  ) {
    final settingsState = context.read<SettingsBloc>().state;
    showDialog(
      context: rootContext,
      builder: (context) => AlertDialog(
        backgroundColor: settingsState.isDarkMode ? AppColors.surfaceDark : AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          'Two-Step Verification',
          style: TextStyle(
            color: settingsState.isDarkMode ? AppColors.textPrimaryDark : AppColors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: settingsState.fontSize + 2,
            fontFamily: settingsState.fontFamily,
          ),
        ),
        content: SizedBox(
          width: 400,
          height: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              QrImageView(
                data: qrCodeUrl,
                version: QrVersions.auto,
                size: 200.0,
                backgroundColor: AppColors.surface,
              ),
              const SizedBox(height: 16),
              Text(
                'Scan this QR code with your authenticator app',
                style: TextStyle(
                  color: settingsState.isDarkMode ? AppColors.textPrimaryDark : AppColors.textPrimary,
                  fontSize: settingsState.fontSize,
                  fontFamily: settingsState.fontFamily,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: otpController,
                label: 'Enter Code',
                settingsState: settingsState,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: settingsState.isDarkMode ? AppColors.textPrimaryDark : AppColors.textPrimary,
                fontSize: settingsState.fontSize,
                fontFamily: settingsState.fontFamily,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              _onEnableTwoStepPressed(otpController.text);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Enable',
              style: TextStyle(
                color: AppColors.surface,
                fontSize: settingsState.fontSize,
                fontFamily: settingsState.fontFamily,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _copyAllCodes(List<String> codes) async {
    final allCodes = codes
        .asMap()
        .entries
        .map((entry) => '${entry.key + 1}. ${entry.value}')
        .join('\n');

    await Clipboard.setData(ClipboardData(text: allCodes));

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Đã copy tất cả ${codes.length} backup codes'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _showBackupCodesDialog(List<String> backupCodes) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 16,
          child: Stack(
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.surface,
                      AppColors.primary.withAlpha((255 * 0.8).toInt()),
                    ],
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(
                      height: 24,
                    ),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withAlpha(
                                  (255 * 0.3).toInt(),
                                ),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.security,
                            color: AppColors.primary,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Backup Codes',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF2D3748),
                                ),
                              ),
                              Text(
                                'Please store securely',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: const Color(0xFF718096),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Warning box
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withAlpha(10),
                        border: Border.all(
                          color: AppColors.accent.withAlpha(30),
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.warning_amber_rounded,
                            color: AppColors.accent,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Never share your backup codes with anyone. Each code is used once!',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColors.primary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    Container(
                      constraints: const BoxConstraints(maxHeight: 300),
                      child: GridView.builder(
                        shrinkWrap: true,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 3.5,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                            ),
                        itemCount: backupCodes.length,
                        itemBuilder: (context, index) {
                          return BackupCodeItem(
                            code: backupCodes[index],
                            index: index + 1,
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 24),

                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _copyAllCodes(backupCodes),
                            icon: Icon(
                              Icons.copy_all,
                              color: AppColors.primary,
                            ),
                            label: Text(
                              'Copy all',
                              style: TextStyle(color: AppColors.primary),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(
                                color: AppColors.primary.withAlpha(100),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: const Icon(
                              Icons.check,
                              color: AppColors.surface,
                            ),
                            label: const Text(
                              'Saved',
                              style: TextStyle(color: AppColors.surface),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 3,
                              shadowColor: AppColors.primary.withAlpha(30),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              Positioned(
                right: 8,
                top: 8,
                child: IconButton(
                  icon: const Icon(Icons.close, color: AppColors.surface),
                  onPressed: () => Navigator.of(context).pop(),
                  tooltip: 'Close',
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showCopyNotification(
    BuildContext context,
    Color color,
    String message,
  ) {
    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder:
          (context) => Positioned(
            bottom: 0,
            left: 20,
            right: 20,
            child: Material(
              color: Colors.transparent,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  message.trim(),
                  style: TextStyle(color: AppColors.surface),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
    );

    overlay.insert(overlayEntry);

    Future.delayed(const Duration(seconds: 2), () {
      overlayEntry.remove();
    });
  }

  void _showEditProfileDialog() {
    final settingsState = context.read<SettingsBloc>().state;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: settingsState.isDarkMode ? AppColors.surfaceDark : AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          'Edit Profile',
          style: TextStyle(
            color: settingsState.isDarkMode ? AppColors.textPrimaryDark : AppColors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: settingsState.fontSize + 2,
            fontFamily: settingsState.fontFamily,
          ),
        ),
        content: SizedBox(
          width: 400,
          height: 200,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildTextField(
                controller: emailController,
                label: 'Email',
                settingsState: settingsState,
              ),
              const SizedBox(height: 24),
              _buildTextField(
                controller: nameController,
                label: 'Name',
                settingsState: settingsState,
              ),
              const SizedBox(height: 24),
              _buildTextField(
                controller: phoneController,
                label: 'Phone Number',
                settingsState: settingsState,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: settingsState.isDarkMode ? AppColors.textPrimaryDark : AppColors.textPrimary,
                fontSize: settingsState.fontSize,
                fontFamily: settingsState.fontFamily,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              _onProfileUpdatePressed();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Update',
              style: TextStyle(
                color: AppColors.surface,
                fontSize: settingsState.fontSize,
                fontFamily: settingsState.fontFamily,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required SettingsState settingsState,
    bool isPassword = false,
  }) {
    if (label == 'Email') {
      controller.text = controller.text.split('@')[0];
    }
    return TextField(
      controller: controller,
      obscureText: isPassword,
      style: TextStyle(
        color: settingsState.isDarkMode ? AppColors.textPrimaryDark : AppColors.textPrimary,
        fontSize: settingsState.fontSize,
        fontFamily: settingsState.fontFamily,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: settingsState.isDarkMode ? AppColors.textSecondaryDark : AppColors.textSecondary,
          fontSize: settingsState.fontSize,
          fontFamily: settingsState.fontFamily,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: settingsState.isDarkMode ? AppColors.borderDark : AppColors.border,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: AppColors.primary,
          ),
        ),
        filled: true,
        fillColor: settingsState.isDarkMode ? AppColors.surfaceDark : AppColors.surface,
        suffixText: label == 'Email' ? '@gmail.com' : null,
      ),
    );
  }

  void _changeProfilePicture() {
    final settingsState = context.read<SettingsBloc>().state;
    showModalBottomSheet(
      context: context,
      backgroundColor: settingsState.isDarkMode ? AppColors.surfaceDark : AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: settingsState.isDarkMode ? AppColors.surfaceVariantDark : AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Change Profile Picture',
              style: TextStyle(
                fontSize: settingsState.fontSize + 2,
                fontWeight: FontWeight.bold,
                color: settingsState.isDarkMode ? AppColors.textPrimaryDark : AppColors.textPrimary,
                fontFamily: settingsState.fontFamily,
              ),
            ),
            const SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildImageSourceButton(
                  icon: Icons.camera_alt,
                  label: 'Camera',
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.camera);
                  },
                  settingsState: settingsState,
                ),
                _buildImageSourceButton(
                  icon: Icons.photo_library,
                  label: 'Gallery',
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.gallery);
                  },
                  settingsState: settingsState,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageSourceButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required SettingsState settingsState,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: BoxDecoration(
          color: settingsState.isDarkMode ? AppColors.surfaceVariantDark : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 32,
              color: settingsState.isDarkMode ? AppColors.textPrimaryDark : AppColors.textPrimary,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: settingsState.isDarkMode ? AppColors.textPrimaryDark : AppColors.textPrimary,
                fontSize: settingsState.fontSize,
                fontFamily: settingsState.fontFamily,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileSection() {
    return BlocBuilder<SettingsBloc, SettingsState>(
      builder: (context, settingsState) {
        final isDark = settingsState.isDarkMode;
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                isDark ? AppColors.primaryDark : AppColors.primary,
                isDark
                    ? AppColors.primaryDark.withAlpha((255 * 0.8).toInt())
                    : AppColors.primaryDark.withAlpha((255 * 0.8).toInt()),
              ],
            ),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(12),
              bottomLeft: Radius.circular(12),
            ),
            boxShadow: [
              BoxShadow(
                color: (isDark ? AppColors.primaryDark : AppColors.primary)
                    .withAlpha((255 * 0.3).toInt()),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.surface, width: 4),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.textPrimary.withAlpha(
                              (255 * 0.1).toInt(),
                            ),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: CircleAvatar(
                        radius: 50,
                        backgroundColor: AppColors.surface,
                        backgroundImage:
                            (user != null &&
                                    user?.avatarUrl != null &&
                                    user!.avatarUrl!.isNotEmpty)
                                ? NetworkImage(
                                  'https://final-flutter.onrender.com/${user!.avatarUrl!}',
                                )
                                : null,
                        child:
                            (user == null ||
                                    user!.avatarUrl == null ||
                                    user!.avatarUrl!.isEmpty)
                                ? const Icon(
                                  Icons.person,
                                  size: 50,
                                  color: AppColors.primary,
                                )
                                : null,
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: _changeProfilePicture,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: AppColors.secondary,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.border,
                                blurRadius: 4,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.camera_alt,
                            color: AppColors.surface,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  user?.email ?? '',
                  style: TextStyle(
                    fontSize: settingsState.fontSize,
                    color:AppColors.textOnPrimary,
                    fontFamily: settingsState.fontFamily,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  user?.name ?? '',
                  style: TextStyle(
                    fontSize: settingsState.fontSize + 4,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textOnPrimary,
                    fontFamily: settingsState.fontFamily,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  user?.phone ?? 'Phone Number',
                  style: TextStyle(
                    fontSize: settingsState.fontSize + 4,
                    color: AppColors.surfaceVariant,
                    fontFamily: settingsState.fontFamily,
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: _showEditProfileDialog,
                  icon: const Icon(Icons.edit, color: AppColors.primary),
                  label: const Text(
                    'Edit Profile',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.surface,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                    elevation: 0,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSettingsSection() {
    return BlocBuilder<SettingsBloc, SettingsState>(
      builder: (context, settingsState) {
        final isDark = settingsState.isDarkMode;
        return Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : AppColors.surface,
            borderRadius: BorderRadius.only(
              topRight: Radius.circular(12),
              bottomRight: Radius.circular(12),
            ),
            boxShadow: [
              BoxShadow(
                color: (isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimary)
                    .withAlpha((255 * 0.05).toInt()),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  'Security Settings',
                  style: TextStyle(
                    fontSize: settingsState.fontSize + 2,
                    fontWeight: FontWeight.bold,
                    color:
                        isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimary,
                    fontFamily: settingsState.fontFamily,
                  ),
                ),
              ),
              _buildSettingsTile(
                icon: Icons.lock_outline,
                title: 'Change Password',
                subtitle: 'Update your current password',
                color: AppColors.primary,
                onTap: _showChangePasswordDialog,
              ),
              _buildDivider(),
              _buildSettingsTile(
                icon: Icons.key_outlined,
                title: 'Password Recovery',
                subtitle: 'Recover your password',
                color: AppColors.secondary,
                onTap: _showPasswordRecoveryDialog,
              ),
              _buildDivider(),
              _buildTwoStepTile(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return BlocBuilder<SettingsBloc, SettingsState>(
      builder: (context, settingsState) {
        final isDark = settingsState.isDarkMode;
        return ListTile(
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color),
          ),
          title: Text(
            title,
            style: TextStyle(
              fontSize: settingsState.fontSize,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
              fontFamily: settingsState.fontFamily,
            ),
          ),
          subtitle: Text(
            subtitle,
            style: TextStyle(
              fontSize: settingsState.fontSize - 2,
              color:
                  isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondary,
              fontFamily: settingsState.fontFamily,
            ),
          ),
          trailing: const Icon(Icons.chevron_right),
          onTap: onTap,
        );
      },
    );
  }

  void _showDisableTwoStepDialog(BuildContext context) {
    final otpController = TextEditingController();
    final passwordController = TextEditingController();

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text(
              'Disable Two-Factor Authentication',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            content: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'To disable 2FA, please enter your current 6-digit code from the authenticator app and your account password.',
                    style: TextStyle(color: AppColors.surfaceVariant),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: otpController,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    decoration: const InputDecoration(
                      labelText: 'OTP Code',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Password',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  final otp = otpController.text.trim();
                  final password = passwordController.text.trim();

                  if (otp.length == 6 && password.isNotEmpty) {
                    _onDisableTwoStepPressed(password, otp);
                  } else {
                    _showCopyNotification(
                      context,
                      AppColors.accentDark,
                      'Invalid OTP or password.',
                    );
                  }
                },
                child: const Text('Disable'),
              ),
            ],
          ),
    );
  }

  Widget _buildTwoStepTile() {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: (twoStepEnabled
                  ? AppColors.secondary
                  : AppColors.surfaceVariant)
              .withAlpha((255 * 0.1).toInt()),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          Icons.security,
          color:
              twoStepEnabled ? AppColors.secondary : AppColors.surfaceVariant,
          size: 24,
        ),
      ),
      title: const Text(
        'Two-Step Verification',
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
      subtitle: Text(
        twoStepEnabled
            ? 'Enabled - You have added extra security to your account'
            : 'Add extra security to your account',
        style: const TextStyle(color: AppColors.textPrimary, fontSize: 12),
      ),
      trailing: Switch(
        value: twoStepEnabled,
        onChanged:
            (value) => {
              if (value)
                _onGenerateQrCodePressed()
              else
                _showDisableTwoStepDialog(context),
            },
        activeColor: AppColors.secondary,
        inactiveThumbColor: AppColors.surfaceVariant,
      ),
    );
  }

  Widget _buildDivider() {
    return BlocBuilder<SettingsBloc, SettingsState>(
      builder: (context, settingsState) {
        final isDark = settingsState.isDarkMode;
        return Divider(
          color: isDark ? AppColors.dividerDark : AppColors.divider,
          thickness: 1,
          height: 1,
        );
      },
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.secondary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.accent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}
