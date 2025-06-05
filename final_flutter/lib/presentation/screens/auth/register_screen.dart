import 'package:final_flutter/presentation/screens/auth/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:final_flutter/logic/auth/auth_bloc.dart';
import 'package:final_flutter/logic/auth/auth_event.dart';
import 'package:final_flutter/logic/auth/auth_state.dart';
import 'package:final_flutter/presentation/screens/home/home_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final phoneController = TextEditingController();
  final passwordController = TextEditingController();
  final nameController = TextEditingController();
  void _onRegisterPressed() {
    final phone = phoneController.text.trim();
    final name = nameController.text.trim();
    final password = passwordController.text.trim();

    if (phone.length != 10 || !RegExp(r'^\d{10}$').hasMatch(phone)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Phone number must be 10 digits.')),
      );
      return;
    }
    context.read<AuthBloc>().add(RegisterRequested(name, phone, password));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFB6C1),
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
                  child: Container(
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
                ),
                // Username
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    hintText: 'Username',
                    prefixIcon:
                        const Icon(Icons.person, color: Colors.pinkAccent),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding:
                        const EdgeInsets.symmetric(vertical: 18.0),
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
                const SizedBox(height: 16),
                // Phone
                TextField(
                  controller: phoneController,
                  decoration: InputDecoration(
                    hintText: 'Phone',
                    prefixIcon: const Icon(Icons.phone, color: Colors.pinkAccent),
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
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(10),
                  ],
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
                    contentPadding:
                        const EdgeInsets.symmetric(vertical: 18.0),
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
                const SizedBox(height: 16),
                // Confirm Password
                TextField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    hintText: 'Confirm Password',
                    prefixIcon:
                        const Icon(Icons.lock_outline, color: Colors.pinkAccent),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding:
                        const EdgeInsets.symmetric(vertical: 18.0),
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
                // Sign Up Button
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
                    onPressed: _onRegisterPressed,
                    child: const Text(
                      'SIGN UP',
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
                // Sign In Link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "Already have an account?",
                      style: TextStyle(color: Colors.white, fontSize: 15),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (_) => const LoginScreen()),
                        );
                      },
                      child: const Text(
                        'SIGN IN NOW',
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
