import 'dart:convert';
import 'dart:io';

import 'package:final_flutter/config/app_theme.dart';
import 'package:final_flutter/logic/auth/auth_bloc.dart';
import 'package:final_flutter/logic/auth/auth_event.dart';
import 'package:final_flutter/logic/auth/auth_state.dart';
import 'package:final_flutter/logic/settings/settings_bloc.dart';
import 'package:final_flutter/logic/settings/settings_state.dart';
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
        return Scaffold(
          backgroundColor: settingsState.isDarkMode ? AppColors.backgroundDark : AppColors.background,
          appBar: AppBar(
            title: Text(
              'Profile',
              style: TextStyle(
                color: settingsState.isDarkMode ? AppColors.textPrimaryDark : AppColors.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: settingsState.fontSize + 2,
                fontFamily: settingsState.fontFamily,
              ),
            ),
            elevation: 0,
            backgroundColor: settingsState.isDarkMode ? AppColors.surfaceDark : AppColors.surface,
            foregroundColor: settingsState.isDarkMode ? AppColors.textPrimaryDark : AppColors.textPrimary,
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
                    color: settingsState.isDarkMode ? AppColors.primaryDark : AppColors.primary,
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
                        color: settingsState.isDarkMode ? AppColors.textTertiaryDark : AppColors.textTertiary,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Unable to load user information',
                        style: TextStyle(
                          fontSize: settingsState.fontSize,
                          color: settingsState.isDarkMode ? AppColors.textPrimaryDark : AppColors.textPrimary,
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
                      child: isWide
                          ? IntrinsicHeight(
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 300,
                                    child: _buildProfileSection(settingsState),
                                  ),
                                  SizedBox(
                                    width: 600,
                                    child: _buildSettingsSection(settingsState),
                                  ),
                                ],
                              ),
                            )
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                _buildProfileSection(settingsState),
                                const SizedBox(height: 20),
                                _buildSettingsSection(settingsState),
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

  void _showChangePasswordDialog(BuildContext context, SettingsState settingsState) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: settingsState.isDarkMode ? AppColors.surfaceDark : AppColors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text(
              'Change Password',
              style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTextField(
                  controller: currentPasswordController,
                  label: 'Current Password',
                  isPassword: true,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: newPasswordController,
                  label: 'New Password',
                  isPassword: true,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: confirmPasswordController,
                  label: 'Confirm New Password',
                  isPassword: true,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: AppColors.textPrimary),
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
                child: const Text(
                  'Change Password',
                  style: TextStyle(color: AppColors.surface),
                ),
              ),
            ],
          ),
    );
  }

  void _showPasswordRecoveryDialog(BuildContext context, SettingsState settingsState) {
    final emailController = TextEditingController();

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: settingsState.isDarkMode ? AppColors.surfaceDark : AppColors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text(
              'Password Recovery',
              style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (user!.twoStepVerification!)
                  const Text(
                    'Enter otp',
                    style: TextStyle(color: AppColors.textPrimary),
                  ),

                const SizedBox(height: 16),
                _buildTextField(controller: otpController, label: 'OTP'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: AppColors.textPrimary),
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
                child: const Text(
                  'Send',
                  style: TextStyle(color: AppColors.surface),
                ),
              ),
            ],
          ),
    );
  }

  String _getMaskedKey(String key, {int visibleChars = 2}) {
    if (key.length <= visibleChars) return key;
    return key.substring(0, visibleChars) +
        '•' * 6 +
        key.substring(key.length - 2);
  }

  void _showPasswordRecoverySuccessDialog(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: AppColors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text(
              'Password Recovery',
              style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTextField(
                  controller: passwordRecoveryController,
                  label: 'Password',
                ),
                const SizedBox(height: 16),
                Text('Please change password intermediately!')
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: AppColors.textPrimary),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  Clipboard.setData(
                    ClipboardData(
                      text: passwordRecoveryController.text.trim(),
                    ),
                  );
                  _showCopyNotification(context, AppColors.success, "Copied!");
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Save',
                  style: TextStyle(color: AppColors.surface),
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
    final qrBytes = base64Decode(qrCodeUrl.split(',').last);
    final maskedKey = _getMaskedKey(entryKey);

    showDialog(
      context: rootContext,
      builder:
          (dialogContext) => StatefulBuilder(
            builder:
                (context, setDialogState) => AlertDialog(
                  backgroundColor: AppColors.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  contentPadding: const EdgeInsets.all(24),
                  insetPadding: const EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: 24,
                  ),
                  title: const Text(
                    'Enable Two-Step Verification',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  content: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 400),
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            '1. Download the Google Authenticator or Microsoft Authenticator app on your phone.',
                            style: TextStyle(color: AppColors.textPrimary),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            '2. Open the app and choose "Add account" → "Scan a QR code", or manually enter the key below.',
                            style: TextStyle(color: AppColors.textPrimary),
                          ),
                          const SizedBox(height: 16),
                          Center(
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              color: AppColors.surface,
                              child: Image.memory(
                                qrBytes,
                                width: 200,
                                height: 200,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: TextEditingController(text: maskedKey),
                            readOnly: true,
                            decoration: InputDecoration(
                              labelText: 'Manual Entry Key',
                              border: const OutlineInputBorder(),
                              suffixIcon: IconButton(
                                icon: const Icon(Icons.copy),
                                onPressed: () {
                                  Clipboard.setData(
                                    ClipboardData(text: entryKey),
                                  );
                                  _showCopyNotification(
                                    rootContext,
                                    AppColors.success,
                                    'Copied!',
                                  );
                                },
                              ),
                            ),
                            style: const TextStyle(letterSpacing: 2),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            '3. Enter the 6-digit code displayed in the app to verify.',
                            style: TextStyle(color: AppColors.textPrimary),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: otpController,
                            keyboardType: TextInputType.number,
                            maxLength: 6,
                            decoration: const InputDecoration(
                              labelText: 'Verification Code',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(color: AppColors.textPrimary),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        final code = otpController.text.trim();
                        if (code.isNotEmpty) {
                          _onEnableTwoStepPressed(code);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Verify',
                        style: TextStyle(color: AppColors.surface),
                      ),
                    ),
                  ],
                ),
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
                    ), // Thêm khoảng trống phía trên cho nút X
                    // Phần header
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
                        border: Border.all(color: AppColors.accent.withAlpha(30)),
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
                            icon: Icon(Icons.copy_all, color: AppColors.primary),
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
                            icon: const Icon(Icons.check, color: AppColors.surface),
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

  void _showEditProfileDialog(BuildContext context, SettingsState settingsState) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: settingsState.isDarkMode ? AppColors.surfaceDark : AppColors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text(
              'Edit Profile',
              style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
            ),
            content: SizedBox(
              width: 400,
              height: 200,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildTextField(controller: emailController, label: 'Email'),
                  const SizedBox(height: 24),
                  _buildTextField(controller: nameController, label: 'Name'),
                  const SizedBox(height: 24),
                  _buildTextField(
                    controller: phoneController,
                    label: 'Phone Number',
                  ),
                ],
              ),
            ),

            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: AppColors.textPrimary),
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
                child: const Text(
                  'Update',
                  style: TextStyle(color: AppColors.surface),
                ),
              ),
            ],
          ),
    );
  }

  void _changeProfilePicture() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (context) => Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Change Profile Picture',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 30),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildImageOption(
                      icon: Icons.camera_alt,
                      label: 'Camera',
                      color: AppColors.primary,
                      onTap: () {
                        Navigator.pop(context);
                        _pickImage(ImageSource.camera);
                      },
                    ),
                    _buildImageOption(
                      icon: Icons.photo_library,
                      label: 'Gallery',
                      color: AppColors.secondary,
                      onTap: () {
                        Navigator.pop(context);
                        _pickImage(ImageSource.gallery);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
    );
  }

  Widget _buildImageOption({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color.withAlpha((255 * 0.1).toInt()),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withAlpha((255 * 0.3).toInt())),
        ),
        child: Column(
          children: [
            Icon(icon, size: 40, color: color),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(color: color, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    bool isPassword = false,
  }) {
    if (label == 'Email') {
      controller.text = controller.text.split('@')[0];
    }
    return TextField(
      controller: controller,
      obscureText: isPassword,
      style: const TextStyle(color: AppColors.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppColors.textPrimary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: AppColors.primary.withAlpha((255 * 0.3).toInt()),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: AppColors.surfaceVariant.withAlpha((255 * 0.3).toInt()),
          ),
        ),
        filled: true,
        fillColor: AppColors.surface,
        suffixText: label == 'Email' ? '@gmail.com' : null,
      ),
    );
  }

  Widget _buildProfileSection(SettingsState settingsState) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: settingsState.isDarkMode ? AppColors.surfaceDark : AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: settingsState.isDarkMode ? AppColors.textPrimaryDark.withAlpha((255 * 0.05).toInt()) : AppColors.textPrimary.withAlpha((255 * 0.05).toInt()),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 60,
                backgroundColor: settingsState.isDarkMode ? AppColors.backgroundDark : AppColors.background,
                backgroundImage: user?.avatarUrl != null && user!.avatarUrl!.isNotEmpty
                    ? NetworkImage('https://final-flutter.onrender.com/${user!.avatarUrl!}')
                    : null,
                child: user?.avatarUrl == null || user!.avatarUrl!.isEmpty
                    ? Text(
                        user?.name?[0].toUpperCase() ?? '?',
                        style: TextStyle(
                          fontSize: settingsState.fontSize + 16,
                          fontWeight: FontWeight.bold,
                          color: settingsState.isDarkMode ? AppColors.textPrimaryDark : AppColors.textPrimary,
                          fontFamily: settingsState.fontFamily,
                        ),
                      )
                    : null,
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  decoration: BoxDecoration(
                    color: settingsState.isDarkMode ? AppColors.primaryDark : AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.camera_alt, color: AppColors.textOnPrimary),
                    onPressed: () => _changeProfilePicture(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            user?.name ?? '',
            style: TextStyle(
              fontSize: settingsState.fontSize + 4,
              fontWeight: FontWeight.bold,
              color: settingsState.isDarkMode ? AppColors.textPrimaryDark : AppColors.textPrimary,
              fontFamily: settingsState.fontFamily,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            user?.email ?? '',
            style: TextStyle(
              fontSize: settingsState.fontSize,
              color: settingsState.isDarkMode ? AppColors.textSecondaryDark : AppColors.textSecondary,
              fontFamily: settingsState.fontFamily,
            ),
          ),
          const SizedBox(height: 24),
          _buildProfileButton(
            icon: Icons.edit,
            text: 'Edit Profile',
            onPressed: () => _showEditProfileDialog(context, settingsState),
            settingsState: settingsState,
          ),
          const SizedBox(height: 12),
          _buildProfileButton(
            icon: Icons.lock,
            text: 'Change Password',
            onPressed: () => _showChangePasswordDialog(context, settingsState),
            settingsState: settingsState,
          ),
          const SizedBox(height: 12),
          _buildProfileButton(
            icon: twoStepEnabled ? Icons.security : Icons.security_outlined,
            text: twoStepEnabled ? 'Disable 2-Step' : 'Enable 2-Step',
            onPressed: () => twoStepEnabled
                ? _showDisableTwoStepDialog(context, settingsState)
                : _onGenerateQrCodePressed(),
            settingsState: settingsState,
          ),
          const SizedBox(height: 12),
          _buildProfileButton(
            icon: Icons.password,
            text: 'Password Recovery',
            onPressed: () => _showPasswordRecoveryDialog(context, settingsState),
            settingsState: settingsState,
          ),
        ],
      ),
    );
  }

  Widget _buildProfileButton({
    required IconData icon,
    required String text,
    required VoidCallback onPressed,
    required SettingsState settingsState,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(
          text,
          style: TextStyle(
            fontSize: settingsState.fontSize,
            fontFamily: settingsState.fontFamily,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: settingsState.isDarkMode ? AppColors.primaryDark : AppColors.primary,
          foregroundColor: AppColors.textOnPrimary,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsSection(SettingsState settingsState) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: settingsState.isDarkMode ? AppColors.surfaceDark : AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: settingsState.isDarkMode ? AppColors.textPrimaryDark.withAlpha((255 * 0.05).toInt()) : AppColors.textPrimary.withAlpha((255 * 0.05).toInt()),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Account Settings',
            style: TextStyle(
              fontSize: settingsState.fontSize + 4,
              fontWeight: FontWeight.bold,
              color: settingsState.isDarkMode ? AppColors.textPrimaryDark : AppColors.textPrimary,
              fontFamily: settingsState.fontFamily,
            ),
          ),
          const SizedBox(height: 24),
          _buildSettingItem(
            icon: Icons.person,
            title: 'Name',
            value: user?.name ?? '',
            onTap: () => _showEditProfileDialog(context, settingsState),
            settingsState: settingsState,
          ),
          _buildSettingItem(
            icon: Icons.email,
            title: 'Email',
            value: user?.email ?? '',
            onTap: () => _showEditProfileDialog(context, settingsState),
            settingsState: settingsState,
          ),
          _buildSettingItem(
            icon: Icons.phone,
            title: 'Phone',
            value: user?.phone ?? '',
            onTap: () => _showEditProfileDialog(context, settingsState),
            settingsState: settingsState,
          ),
          _buildSettingItem(
            icon: Icons.security,
            title: 'Two-Step Verification',
            value: twoStepEnabled ? 'Enabled' : 'Disabled',
            onTap: () => twoStepEnabled
                ? _showDisableTwoStepDialog(context, settingsState)
                : _onGenerateQrCodePressed(),
            settingsState: settingsState,
          ),
        ],
      ),
    );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    required String value,
    required VoidCallback onTap,
    required SettingsState settingsState,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: settingsState.isDarkMode ? AppColors.primaryDark.withAlpha((255 * 0.1).toInt()) : AppColors.primary.withAlpha((255 * 0.1).toInt()),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: settingsState.isDarkMode ? AppColors.primaryDark : AppColors.primary,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: settingsState.fontSize,
                      fontWeight: FontWeight.w500,
                      color: settingsState.isDarkMode ? AppColors.textPrimaryDark : AppColors.textPrimary,
                      fontFamily: settingsState.fontFamily,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: settingsState.fontSize - 2,
                      color: settingsState.isDarkMode ? AppColors.textSecondaryDark : AppColors.textSecondary,
                      fontFamily: settingsState.fontFamily,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: settingsState.isDarkMode ? AppColors.textTertiaryDark : AppColors.textTertiary,
            ),
          ],
        ),
      ),
    );
  }

  void _showDisableTwoStepDialog(BuildContext context, SettingsState settingsState) {
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
