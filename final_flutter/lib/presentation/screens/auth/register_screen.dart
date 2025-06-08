import 'package:final_flutter/config/app_theme.dart';
import 'package:final_flutter/presentation/screens/auth/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:final_flutter/logic/auth/auth_bloc.dart';
import 'package:final_flutter/logic/auth/auth_event.dart';
import 'package:final_flutter/logic/auth/auth_state.dart';
import 'package:final_flutter/logic/settings/settings_bloc.dart';
import 'package:final_flutter/logic/settings/settings_state.dart';
import 'package:final_flutter/presentation/screens/home/home_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with TickerProviderStateMixin {
  final phoneController = TextEditingController();
  final passwordController = TextEditingController();
  final nameController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _pulseController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _pulseAnimation;

  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOutBack),
    );

    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _fadeController.forward();
    _slideController.forward();
    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _pulseController.dispose();
    phoneController.dispose();
    passwordController.dispose();
    nameController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  void _onRegisterPressed() {
    final phone = phoneController.text.trim();
    final name = nameController.text.trim();
    final password = passwordController.text.trim();
    final confirmPassword = confirmPasswordController.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.surface.withAlpha((255 * 0.2).toInt()),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.error_outline_rounded,
                  color: AppColors.surface,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Please enter your full name',
                  style: TextStyle(
                    color: AppColors.surface,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: AppColors.accent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          margin: const EdgeInsets.all(16),
          elevation: 8,
        ),
      );
      return;
    }

    if (phone.length != 10 || !RegExp(r'^\d{10}$').hasMatch(phone)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.surface.withAlpha((255 * 0.2).toInt()),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.error_outline_rounded,
                  color: AppColors.surface,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Phone number must be 10 digits',
                  style: TextStyle(
                    color: AppColors.surface,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: AppColors.accent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          margin: const EdgeInsets.all(16),
          elevation: 8,
        ),
      );
      return;
    }

    if (password != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.surface.withAlpha((255 * 0.2).toInt()),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.error_outline_rounded,
                  color: AppColors.surface,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Passwords do not match',
                  style: TextStyle(
                    color: AppColors.surface,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: AppColors.accent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          margin: const EdgeInsets.all(16),
          elevation: 8,
        ),
      );
      return;
    }

    context.read<AuthBloc>().add(RegisterRequested(name, phone, password));
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingsBloc, SettingsState>(
      builder: (context, settingsState) {
        final isDark = settingsState.isDarkMode;
        final backgroundColor =
            isDark ? AppColors.backgroundDark : AppColors.background;
        final surfaceColor = isDark ? AppColors.surfaceDark : AppColors.surface;

        return Scaffold(
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  backgroundColor,
                  backgroundColor.withAlpha((255 * 0.8).toInt()),
                  (isDark ? AppColors.primaryDark : AppColors.primary)
                      .withAlpha((255 * 0.05).toInt()),
                ],
              ),
            ),
            child: SafeArea(
              child: BlocConsumer<AuthBloc, AuthState>(
                listener: (context, state) {
                  if (state is Authenticated) {
                    Navigator.pushReplacement(
                      context,
                      PageRouteBuilder(
                        pageBuilder:
                            (context, animation, secondaryAnimation) =>
                                const HomeScreen(),
                        transitionsBuilder: (
                          context,
                          animation,
                          secondaryAnimation,
                          child,
                        ) {
                          return SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(1.0, 0.0),
                              end: Offset.zero,
                            ).animate(
                              CurvedAnimation(
                                parent: animation,
                                curve: Curves.easeOutCubic,
                              ),
                            ),
                            child: child,
                          );
                        },
                      ),
                    );
                  } else if (state is AuthError) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: AppColors.surface.withAlpha((255 * 0.2).toInt()),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.error_outline_rounded,
                                color: AppColors.surface,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                state.message,
                                style: const TextStyle(
                                  color: AppColors.surface,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                        backgroundColor: AppColors.accent,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        margin: const EdgeInsets.all(16),
                        elevation: 8,
                      ),
                    );
                  }
                },
                builder: (context, state) {
                  return SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        children: [
                          const SizedBox(height: 40),
                          // Hero Section
                          FadeTransition(
                            opacity: _fadeAnimation,
                            child: SlideTransition(
                              position: _slideAnimation,
                              child: Column(
                                children: [
                                  // Logo/Icon
                                  ScaleTransition(
                                    scale: _pulseAnimation,
                                    child: Container(
                                      width: 100,
                                      height: 100,
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            isDark
                                                ? AppColors.primaryDark
                                                : AppColors.primary,
                                            (isDark
                                                    ? AppColors.primaryDark
                                                    : AppColors.primary)
                                                .withAlpha((255 * 0.7).toInt()),
                                          ],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                        borderRadius: BorderRadius.circular(28),
                                        boxShadow: [
                                          BoxShadow(
                                            color: (isDark
                                                    ? AppColors.primaryDark
                                                    : AppColors.primary)
                                                .withAlpha((255 * 0.3).toInt()),
                                            blurRadius: 20,
                                            offset: const Offset(0, 8),
                                          ),
                                        ],
                                      ),
                                      child: const Icon(
                                        Icons.person_add_rounded,
                                        size: 50,
                                        color: AppColors.surface,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 32),
                                  // Welcome Text
                                  Text(
                                    'Create Account',
                                    style: TextStyle(
                                      fontSize: settingsState.fontSize + 18,
                                      fontWeight: FontWeight.bold,
                                      color:
                                          isDark
                                              ? AppColors.textPrimaryDark
                                              : AppColors.textPrimary,
                                      fontFamily: settingsState.fontFamily,
                                      height: 1.2,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Sign up to get started',
                                    style: TextStyle(
                                      fontSize: settingsState.fontSize + 2,
                                      color:
                                          isDark
                                              ? AppColors.textSecondaryDark
                                              : AppColors.textSecondary,
                                      fontFamily: settingsState.fontFamily,
                                      height: 1.4,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 40),
                          // Form Section
                          FadeTransition(
                            opacity: _fadeAnimation,
                            child: SlideTransition(
                              position: _slideAnimation,
                              child: Container(
                                padding: const EdgeInsets.all(28),
                                decoration: BoxDecoration(
                                  color: surfaceColor,
                                  borderRadius: BorderRadius.circular(24),
                                  border: Border.all(
                                    color: (isDark
                                            ? AppColors.primaryDark
                                            : AppColors.primary)
                                        .withAlpha((255 * 0.1).toInt()),
                                    width: 1,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: (isDark
                                              ? Colors.black
                                              : AppColors.textPrimary)
                                          .withAlpha((255 * 0.08).toInt()),
                                      blurRadius: 30,
                                      offset: const Offset(0, 12),
                                    ),
                                    BoxShadow(
                                      color: (isDark
                                              ? AppColors.primaryDark
                                              : AppColors.primary)
                                          .withAlpha((255 * 0.05).toInt()),
                                      blurRadius: 60,
                                      offset: const Offset(0, 20),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  children: [
                                    _buildModernTextField(
                                      controller: nameController,
                                      label: 'Full Name',
                                      hint: 'Enter your full name',
                                      prefixIcon: Icons.person_rounded,
                                      settingsState: settingsState,
                                    ),
                                    const SizedBox(height: 20),
                                    _buildModernTextField(
                                      controller: phoneController,
                                      label: 'Phone Number',
                                      hint: 'Enter your phone number',
                                      prefixIcon: Icons.phone_rounded,
                                      settingsState: settingsState,
                                    ),
                                    const SizedBox(height: 20),
                                    _buildModernTextField(
                                      controller: passwordController,
                                      label: 'Password',
                                      hint: 'Enter your password',
                                      prefixIcon: Icons.lock_rounded,
                                      isPassword: true,
                                      isPasswordVisible: _isPasswordVisible,
                                      onTogglePassword: () {
                                        setState(() {
                                          _isPasswordVisible = !_isPasswordVisible;
                                        });
                                      },
                                      settingsState: settingsState,
                                    ),
                                    const SizedBox(height: 20),
                                    _buildModernTextField(
                                      controller: confirmPasswordController,
                                      label: 'Confirm Password',
                                      hint: 'Confirm your password',
                                      prefixIcon: Icons.lock_rounded,
                                      isPassword: true,
                                      isPasswordVisible: _isConfirmPasswordVisible,
                                      onTogglePassword: () {
                                        setState(() {
                                          _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                                        });
                                      },
                                      settingsState: settingsState,
                                    ),
                                    const SizedBox(height: 32),
                                    if (state is AuthLoading)
                                      Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 20,
                                        ),
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              (isDark
                                                      ? AppColors.primaryDark
                                                      : AppColors.primary)
                                                  .withAlpha((255 * 0.8).toInt()),
                                              (isDark
                                                      ? AppColors.primaryDark
                                                      : AppColors.primary)
                                                  .withAlpha((255 * 0.6).toInt()),
                                            ],
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            const SizedBox(
                                              width: 20,
                                              height: 20,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                valueColor:
                                                    AlwaysStoppedAnimation(
                                                      AppColors.surface,
                                                    ),
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Text(
                                              'Creating account...',
                                              style: TextStyle(
                                                color: AppColors.surface,
                                                fontSize:
                                                    settingsState.fontSize,
                                                fontWeight: FontWeight.w600,
                                                fontFamily:
                                                    settingsState.fontFamily,
                                              ),
                                            ),
                                          ],
                                        ),
                                      )
                                    else
                                      _buildModernButton(
                                        onPressed: _onRegisterPressed,
                                        text: 'Sign Up',
                                        settingsState: settingsState,
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 32),
                          // Login Section
                          FadeTransition(
                            opacity: _fadeAnimation,
                            child: _buildLoginSection(settingsState),
                          ),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildModernTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData prefixIcon,
    bool isPassword = false,
    bool isPasswordVisible = false,
    VoidCallback? onTogglePassword,
    required SettingsState settingsState,
  }) {
    final isDark = settingsState.isDarkMode;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: settingsState.fontSize - 1,
            fontWeight: FontWeight.w600,
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
            fontFamily: settingsState.fontFamily,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: (isDark ? AppColors.primaryDark : AppColors.primary)
                  .withAlpha((255 * 0.2).toInt()),
            ),
            gradient: LinearGradient(
              colors: [
                (isDark ? AppColors.primaryDark : AppColors.primary)
                    .withAlpha((255 * 0.03).toInt()),
                (isDark ? AppColors.primaryDark : AppColors.primary)
                    .withAlpha((255 * 0.01).toInt()),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: TextField(
            controller: controller,
            obscureText: isPassword && !isPasswordVisible,
            style: TextStyle(
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
              fontSize: settingsState.fontSize,
              fontFamily: settingsState.fontFamily,
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                color:
                    isDark
                        ? AppColors.textSecondaryDark.withAlpha((255 * 0.6).toInt())
                        : AppColors.textSecondary.withAlpha((255 * 0.6).toInt()),
                fontSize: settingsState.fontSize - 1,
                fontFamily: settingsState.fontFamily,
              ),
              prefixIcon: Container(
                margin: const EdgeInsets.only(left: 12, right: 8),
                child: Icon(
                  prefixIcon,
                  color: isDark ? AppColors.primaryDark : AppColors.primary,
                  size: 22,
                ),
              ),
              suffixIcon:
                  isPassword
                      ? IconButton(
                        icon: Icon(
                          isPasswordVisible
                              ? Icons.visibility_off_rounded
                              : Icons.visibility_rounded,
                          color:
                              isDark
                                  ? AppColors.textSecondaryDark
                                  : AppColors.textSecondary,
                          size: 20,
                        ),
                        onPressed: onTogglePassword,
                      )
                      : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 18,
              ),
              filled: true,
              fillColor: Colors.transparent,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildModernButton({
    required VoidCallback onPressed,
    required String text,
    required SettingsState settingsState,
  }) {
    final isDark = settingsState.isDarkMode;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            isDark ? AppColors.primaryDark : AppColors.primary,
            (isDark ? AppColors.primaryDark : AppColors.primary).withAlpha(
              (255 * 0.8).toInt(),
            ),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: (isDark ? AppColors.primaryDark : AppColors.primary)
                .withAlpha((255 * 0.3).toInt()),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: settingsState.fontSize + 1,
            fontWeight: FontWeight.w600,
            color: AppColors.surface,
            fontFamily: settingsState.fontFamily,
          ),
        ),
      ),
    );
  }

  Widget _buildLoginSection(SettingsState settingsState) {
    final isDark = settingsState.isDarkMode;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: (isDark ? AppColors.surfaceDark : AppColors.surface).withAlpha(
          (255 * 0.5).toInt(),
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: (isDark ? AppColors.primaryDark : AppColors.primary)
              .withAlpha((255 * 0.1).toInt()),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Already have an account? ',
            style: TextStyle(
              fontSize: settingsState.fontSize,
              color:
                  isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondary,
              fontFamily: settingsState.fontFamily,
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pushReplacement(
                context,
                PageRouteBuilder(
                  pageBuilder:
                      (context, animation, secondaryAnimation) =>
                          const LoginScreen(),
                  transitionsBuilder: (
                    context,
                    animation,
                    secondaryAnimation,
                    child,
                  ) {
                    return SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(-1.0, 0.0),
                        end: Offset.zero,
                      ).animate(
                        CurvedAnimation(
                          parent: animation,
                          curve: Curves.easeOutCubic,
                        ),
                      ),
                      child: child,
                    );
                  },
                ),
              );
            },
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            ),
            child: Text(
              'Sign In',
              style: TextStyle(
                fontSize: settingsState.fontSize,
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.primaryDark : AppColors.primary,
                fontFamily: settingsState.fontFamily,
              ),
            ),
          ),
        ],
      ),
    );
  }
}