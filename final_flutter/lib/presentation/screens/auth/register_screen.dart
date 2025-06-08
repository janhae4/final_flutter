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
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  bool _isPasswordVisible = false;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeIn));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
    );

    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    phoneController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  void _onRegisterPressed() {
    final phone = phoneController.text.trim();
    final name = nameController.text.trim();
    final password = passwordController.text.trim();
    final confirmPassword = confirmPasswordController.text.trim();

    if (phone.length != 10 || !RegExp(r'^\d{10}$').hasMatch(phone)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Phone number must be 10 digits.')),
      );
      return;
    }
    if (password != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match.')),
      );
      return;
    }
    context.read<AuthBloc>().add(RegisterRequested(name, phone, password));
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingsBloc, SettingsState>(
      builder: (context, settingsState) {
        return Scaffold(
          body: Container(
            decoration: BoxDecoration(
              color: settingsState.isDarkMode ? AppColors.backgroundDark : AppColors.background,
            ),
            child: SafeArea(
              child: BlocConsumer<AuthBloc, AuthState>(
                listener: (context, state) {
                  if (state is Authenticated) {
                    Navigator.pushReplacement(
                      context,
                      PageRouteBuilder(
                        pageBuilder: (context, animation, secondaryAnimation) =>
                            const HomeScreen(),
                        transitionsBuilder: (
                          context,
                          animation,
                          secondaryAnimation,
                          child,
                        ) {
                          return FadeTransition(opacity: animation, child: child);
                        },
                      ),
                    );
                  } else if (state is AuthError) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Row(
                          children: [
                            const Icon(
                              Icons.error_outline,
                              color: AppColors.surface,
                            ),
                            const SizedBox(width: 8),
                            Expanded(child: Text(state.message)),
                          ],
                        ),
                        backgroundColor: AppColors.accent,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        margin: const EdgeInsets.all(16),
                      ),
                    );
                  }
                },
                builder: (context, state) {
                  return SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 40),
                          FadeTransition(
                            opacity: _fadeAnimation,
                            child: SlideTransition(
                              position: _slideAnimation,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Create Account',
                                    style: TextStyle(
                                      fontSize: settingsState.fontSize + 16,
                                      fontWeight: FontWeight.bold,
                                      color: settingsState.isDarkMode ? AppColors.textPrimaryDark : AppColors.textPrimary,
                                      fontFamily: settingsState.fontFamily,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Sign up to get started',
                                    style: TextStyle(
                                      fontSize: settingsState.fontSize,
                                      color: settingsState.isDarkMode ? AppColors.textSecondaryDark : AppColors.textSecondary,
                                      fontFamily: settingsState.fontFamily,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 40),
                          FadeTransition(
                            opacity: _fadeAnimation,
                            child: SlideTransition(
                              position: _slideAnimation,
                              child: Column(
                                children: [
                                  _buildTextField(
                                    controller: nameController,
                                    label: 'Full Name',
                                    prefixIcon: Icons.person,
                                    settingsState: settingsState,
                                  ),
                                  const SizedBox(height: 16),
                                  _buildTextField(
                                    controller: phoneController,
                                    label: 'Phone Number',
                                    prefixIcon: Icons.phone,
                                    settingsState: settingsState,
                                  ),
                                  const SizedBox(height: 16),
                                  _buildTextField(
                                    controller: passwordController,
                                    label: 'Password',
                                    prefixIcon: Icons.lock,
                                    isPassword: true,
                                    settingsState: settingsState,
                                  ),
                                  const SizedBox(height: 16),
                                  _buildTextField(
                                    controller: confirmPasswordController,
                                    label: 'Confirm Password',
                                    prefixIcon: Icons.lock,
                                    isPassword: true,
                                    settingsState: settingsState,
                                  ),
                                  const SizedBox(height: 24),
                                  if (state is AuthLoading)
                                    Center(
                                      child: CircularProgressIndicator(
                                        color: settingsState.isDarkMode ? AppColors.primaryDark : AppColors.primary,
                                      ),
                                    )
                                  else
                                    _buildRegisterButton(settingsState),
                                  const SizedBox(height: 16),
                                  _buildLoginButton(settingsState),
                                ],
                              ),
                            ),
                          ),
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData prefixIcon,
    bool isPassword = false,
    required SettingsState settingsState,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: settingsState.isDarkMode ? AppColors.surfaceDark : AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: settingsState.isDarkMode ? AppColors.textPrimaryDark.withAlpha((255 * 0.05).toInt()) : AppColors.textPrimary.withAlpha((255 * 0.05).toInt()),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword && !_isPasswordVisible,
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
          prefixIcon: Icon(
            prefixIcon,
            color: settingsState.isDarkMode ? AppColors.primaryDark : AppColors.primary,
          ),
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(
                    _isPasswordVisible ? Icons.visibility_off : Icons.visibility,
                    color: settingsState.isDarkMode ? AppColors.textSecondaryDark : AppColors.textSecondary,
                  ),
                  onPressed: () {
                    setState(() {
                      _isPasswordVisible = !_isPasswordVisible;
                    });
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: settingsState.isDarkMode ? AppColors.surfaceDark : AppColors.surface,
        ),
      ),
    );
  }

  Widget _buildRegisterButton(SettingsState settingsState) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _onRegisterPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: settingsState.isDarkMode ? AppColors.primaryDark : AppColors.primary,
          foregroundColor: AppColors.textOnPrimary,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
        child: Text(
          'Sign Up',
          style: TextStyle(
            fontSize: settingsState.fontSize,
            fontWeight: FontWeight.w600,
            fontFamily: settingsState.fontFamily,
          ),
        ),
      ),
    );
  }

  Widget _buildLoginButton(SettingsState settingsState) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Already have an account? ',
          style: TextStyle(
            fontSize: settingsState.fontSize,
            color: settingsState.isDarkMode ? AppColors.textSecondaryDark : AppColors.textSecondary,
            fontFamily: settingsState.fontFamily,
          ),
        ),
        TextButton(
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const LoginScreen()),
            );
          },
          child: Text(
            'Sign In',
            style: TextStyle(
              fontSize: settingsState.fontSize,
              fontWeight: FontWeight.w600,
              color: settingsState.isDarkMode ? AppColors.primaryDark : AppColors.primary,
              fontFamily: settingsState.fontFamily,
            ),
          ),
        ),
      ],
    );
  }
}
