import 'package:final_flutter/config/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:final_flutter/logic/auth/auth_bloc.dart';
import 'package:final_flutter/logic/auth/auth_event.dart';
import 'package:final_flutter/logic/auth/auth_state.dart';
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
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(color: AppColors.surface),
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
              return FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        const SizedBox(height: 60),

                        // Logo và Title
                        Hero(
                          tag: 'app_logo',
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppColors.primary,
                                  AppColors.primary.withAlpha(
                                    (255 * 0.8).toInt(),
                                  ),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(25),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.textPrimary.withAlpha(
                                    (255 * 0.1).toInt(),
                                  ),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.lock_person_outlined,
                              size: 60,
                              color: AppColors.surface,
                            ),
                          ),
                        ),

                        const SizedBox(height: 8),

                        const Text(
                          'Welcome Back',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryDark,
                          ),
                        ),

                        const SizedBox(height: 8),

                        Text(
                          'Sign in to continue',
                          style: TextStyle(
                            fontSize: 16,
                            color: AppColors.textPrimary.withAlpha(
                              (255 * 0.8).toInt(),
                            ),
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Form Container
                        Container(
                          padding: const EdgeInsets.all(32),
                          constraints: const BoxConstraints(maxWidth: 600),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(25),
                            border: Border.all(
                              color: AppColors.textTertiary.withAlpha(
                                (255 * 0.1).toInt(),
                              ),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.textPrimary.withAlpha(
                                  (255 * 0.05).toInt(),
                                ),
                                blurRadius: 30,
                                offset: const Offset(0, 15),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
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
                                  controller: usernameController,
                                  keyboardType: TextInputType.phone,
                                  style: const TextStyle(fontSize: 16),
                                  decoration: InputDecoration(
                                    labelText: 'Phone or Email',
                                    labelStyle: TextStyle(
                                      color: AppColors.textTertiary.withAlpha(
                                        (255 * 0.5).toInt(),),
                                    ),
                                    prefixIcon: const Icon(
                                      Icons.person_outline,
                                      color: AppColors.primaryLight,
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
                                        color: AppColors.primaryLight,
                                        width: 2,
                                      ),
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 20),

                              // Password Field
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
                                  controller: passwordController,
                                  obscureText: !_isPasswordVisible,
                                  style: const TextStyle(fontSize: 16),
                                  decoration: InputDecoration(
                                    labelText: 'Password',
                                    labelStyle: TextStyle(
                                      color: AppColors.textTertiary.withAlpha(
                                        (255 * 0.5).toInt(),),
                                    ),
                                    prefixIcon: const Icon(
                                      Icons.lock_outline,
                                      color: AppColors.primary,
                                    ),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _isPasswordVisible
                                            ? Icons.visibility
                                            : Icons.visibility_off,
                                        color: AppColors.textTertiary.withAlpha(
                                          (255 * 0.5).toInt(),
                                        ),
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _isPasswordVisible =
                                              !_isPasswordVisible;
                                        });
                                      },
                                    ),
                                    filled: true,
                                    fillColor: AppColors.textTertiary.withAlpha(
                                      (255 * 0.01).toInt(),
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

                              const SizedBox(height: 32),

                              // Login Button
                              SizedBox(
                                width: double.infinity,
                                height: 56,
                                child:
                                    state is AuthLoading
                                        ? Container(
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [
                                                AppColors.primary,
                                                AppColors.primary.withAlpha(
                                                  (255 * 0.9).toInt(),
                                                ),
                                              ],
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              28,
                                            ),
                                          ),
                                          child: const Center(
                                            child: CircularProgressIndicator(
                                              valueColor:
                                                  AlwaysStoppedAnimation<Color>(
                                                    AppColors.surface,
                                                  ),
                                            ),
                                          ),
                                        )
                                        : Container(
                                          decoration: BoxDecoration(
                                            gradient: const LinearGradient(
                                              colors: [
                                                AppColors.primary,
                                                AppColors.primaryDark,
                                              ],
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              28,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: const Color(
                                                  0xFF667eea,
                                                ).withAlpha(
                                                  (255 * 0.3).toInt(),
                                                ),
                                                blurRadius: 15,
                                                offset: const Offset(0, 8),
                                              ),
                                            ],
                                          ),
                                          child: ElevatedButton(
                                            onPressed: _onLoginPressed,
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  Colors.transparent,
                                              shadowColor: Colors.transparent,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(28),
                                              ),
                                            ),
                                            child: const Text(
                                              'Sign In',
                                              style: TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.w600,
                                                color: AppColors.surface,
                                              ),
                                            ),
                                          ),
                                        ),
                              ),

                              const SizedBox(height: 20),
                            ],
                          ),
                        ),

                        const SizedBox(height: 32),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "Don't have an account? ",
                              style: TextStyle(
                                color: AppColors.textPrimary.withAlpha(
                                  (255 * 0.8).toInt(),
                                ),
                                fontSize: 16,
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  PageRouteBuilder(
                                    pageBuilder:
                                        (
                                          context,
                                          animation,
                                          secondaryAnimation,
                                        ) => const RegisterScreen(),
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
                                        ).animate(animation),
                                        child: child,
                                      );
                                    },
                                  ),
                                );
                              },
                              child: const Text(
                                'Sign Up',
                                style: TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  decoration: TextDecoration.underline,
                                  decorationColor: AppColors.textPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 50),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
