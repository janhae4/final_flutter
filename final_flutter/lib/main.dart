import 'package:final_flutter/presentation/screens/auth/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:final_flutter/logic/auth/auth_bloc.dart';
import 'package:final_flutter/logic/auth/auth_repository.dart';

void main() {
  final authRepository = AuthRepository();

  runApp(MyApp(authRepository: authRepository));
}

class MyApp extends StatelessWidget {
  final AuthRepository authRepository;

  const MyApp({Key? key, required this.authRepository}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider<AuthBloc>(
      create: (_) => AuthBloc(authRepository),
      child: MaterialApp(
        title: 'Email Simulation App',
        theme: ThemeData(primarySwatch: Colors.blue),
        home: const SplashScreen(), // màn đầu tiên
      ),
    );
  }
}
