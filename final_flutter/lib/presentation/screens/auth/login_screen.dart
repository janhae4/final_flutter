import 'package:final_flutter/config/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:final_flutter/logic/auth/auth_bloc.dart';
import 'package:final_flutter/logic/auth/auth_event.dart';
import 'package:final_flutter/logic/auth/auth_state.dart';
import 'package:final_flutter/logic/settings/settings_bloc.dart';
import 'package:final_flutter/logic/settings/settings_state.dart';
import 'package:final_flutter/presentation/screens/auth/register_screen.dart';
import 'package:final_flutter/presentation/screens/home/home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();

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
    usernameController.dispose();
    passwordController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  void _onLoginPressed() {
    final phone = usernameController.text.trim();
    final password = passwordController.text.trim();
    context.read<AuthBloc>().add(LoginRequested(phone, password));
  }

  void _showOtpDialog(String token) {
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: AppColors.textPrimary.withAlpha((255 * 0.7).toInt()),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) {
        return ScaleTransition(
          scale: Tween<double>(begin: 0.8, end: 1.0).animate(
            CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
          ),
          child: AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            backgroundColor: AppColors.surface,
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primary, AppColors.primaryDark],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.security,
                    color: AppColors.surface,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Two-Factor Authentication',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Enter the 6-digit verification code from your Authenticator app:',
                  style: TextStyle(color: AppColors.textTertiary, fontSize: 14),
                ),
                const SizedBox(height: 20),
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.textTertiary.withAlpha(
                          (255 * 0.1).toInt(),
                        ),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _otpController,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 8,
                    ),
                    decoration: InputDecoration(
                      counterText: '',
                      hintText: '000000',
                      hintStyle: TextStyle(
                        color: AppColors.textTertiary.withAlpha(
                          (255 * 0.5).toInt(),
                        ),
                      ),
                      filled: true,
                      fillColor: AppColors.textTertiary.withAlpha(
                        (255 * 0.1).toInt(),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: const BorderSide(
                          color: AppColors.primary,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: AppColors.textTertiary),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.primaryDark],
                  ),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: ElevatedButton(
                  onPressed: () {
                    final otpCode = _otpController.text.trim();
                    if (otpCode.isNotEmpty) {
                      context.read<AuthBloc>().add(
                        SubmitTwoFactor(otpCode, token),
                      );
                      Navigator.of(context).pop();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  child: const Text(
                    'Verify',
                    style: TextStyle(
                      color: AppColors.surface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
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
                        pageBuilder:
                            (context, animation, secondaryAnimation) =>
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
                  } else if (state is TwoFactorRequired) {
                    _showOtpDialog(state.tempToken);
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
                                    'Welcome Back!',
                                    style: TextStyle(
                                      fontSize: settingsState.fontSize + 16,
                                      fontWeight: FontWeight.bold,
                                      color: settingsState.isDarkMode ? AppColors.textPrimaryDark : AppColors.textPrimary,
                                      fontFamily: settingsState.fontFamily,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Sign in to continue',
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
                                    controller: usernameController,
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
                                  const SizedBox(height: 24),
                                  if (state is AuthLoading)
                                    Center(
                                      child: CircularProgressIndicator(
                                        color: settingsState.isDarkMode ? AppColors.primaryDark : AppColors.primary,
                                      ),
                                    )
                                  else
                                    _buildLoginButton(settingsState),
                                  const SizedBox(height: 16),
                                  _buildRegisterButton(settingsState),
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

  Widget _buildLoginButton(SettingsState settingsState) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _onLoginPressed,
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
          'Sign In',
          style: TextStyle(
            fontSize: settingsState.fontSize,
            fontWeight: FontWeight.w600,
            fontFamily: settingsState.fontFamily,
          ),
        ),
      ),
    );
  }

  Widget _buildRegisterButton(SettingsState settingsState) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Don\'t have an account? ',
          style: TextStyle(
            fontSize: settingsState.fontSize,
            color: settingsState.isDarkMode ? AppColors.textSecondaryDark : AppColors.textSecondary,
            fontFamily: settingsState.fontFamily,
          ),
        ),
        TextButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const RegisterScreen()),
            );
          },
          child: Text(
            'Sign Up',
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
