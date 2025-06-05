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

class _LoginScreenState extends State<LoginScreen> {
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();

  void _onLoginPressed() {
    final phone = usernameController.text.trim();
    final password = passwordController.text.trim();
    context.read<AuthBloc>().add(LoginRequested(phone, password));
  }

  void _showOtpDialog(String token) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return AlertDialog(
          title: const Text('Two-Factor Authentication'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Enter the verification code from your Authenticator app or backup code:',
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _otpController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                decoration: const InputDecoration(
                  labelText: 'OTP Code',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final otpCode = _otpController.text.trim();
                if (otpCode.isNotEmpty) {
                  context.read<AuthBloc>().add(SubmitTwoFactor(otpCode, token));
                  Navigator.of(context).pop();
                }
              },
              child: const Text('Verify'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFB6C1), // pastel pink
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo
                Padding(
                  padding: const EdgeInsets.only(bottom: 32.0),
                  child: Column(
                    children: [
                      // Hiển thị logo từ assets
                      Container(
                        width: 250,
                        height: 300,
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(70),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(70),
                          child: Image.asset(
                            'assets/images/logo_hh.png',
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Username
                TextField(
                  controller: usernameController,
                  decoration: InputDecoration(
                    hintText: 'Username',
                    prefixIcon: const Icon(Icons.person, color: Colors.pinkAccent),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(vertical: 18.0),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(50), // bo tròn hơn
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(50),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(50),
                      borderSide: const BorderSide(
                        color: Colors.pinkAccent,
                        width: 2,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Password
                TextField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    hintText: 'Password',
                    prefixIcon: const Icon(Icons.lock, color: Colors.pinkAccent),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(vertical: 18.0),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(50),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(50),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(50),
                      borderSide: const BorderSide(
                        color: Colors.pinkAccent,
                        width: 2,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // Sign In Button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.pinkAccent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      elevation: 0,
                    ),
                    onPressed: _onLoginPressed,
                    child: const Text(
                      'SIGN IN',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // Sign Up Link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "Don't have an account?",
                      style: TextStyle(color: Colors.white, fontSize: 15),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const RegisterScreen()),
                        );
                      },
                      child: const Text(
                        'SIGN UP NOW',
                        style: TextStyle(
                          color: Colors.pinkAccent,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
