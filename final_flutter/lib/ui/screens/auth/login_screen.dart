import 'package:flutter/material.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Đăng nhập')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextField(
                decoration: InputDecoration(labelText: 'Số điện thoại'),
                keyboardType: TextInputType.phone,
              ),
              TextField(
                decoration: InputDecoration(labelText: 'Mật khẩu'),
                obscureText: true,
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushReplacementNamed(context, '/home');
                },
                child: Text('Đăng nhập'),
              ),
              TextButton(
                onPressed: () {},
                child: Text('Quên mật khẩu?'),
              ),
              TextButton(
                onPressed: () {},
                child: Text('Đăng ký'),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 