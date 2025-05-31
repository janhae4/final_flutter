import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:final_flutter/config/app_theme.dart';
import 'package:final_flutter/logic/auth/auth_bloc.dart';
import 'package:final_flutter/logic/auth/auth_repository.dart';
import 'package:final_flutter/logic/email/email_bloc.dart';
import 'package:final_flutter/logic/email/email_repository.dart';
import 'package:final_flutter/presentation/screens/auth/splash_screen.dart';

void main() {
  final authRepository = AuthRepository();
  final emailRepository = EmailRepository();

  runApp(MyApp(
    authRepository: authRepository,
    emailRepository: emailRepository,
  ));
}

class MyApp extends StatelessWidget {
  final AuthRepository authRepository;
  final EmailRepository emailRepository;

  const MyApp({
    super.key,
    required this.authRepository,
    required this.emailRepository,
  });

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(
          create: (_) => AuthBloc(authRepository),
        ),
        BlocProvider<EmailBloc>(
          create: (_) => EmailBloc(repository: emailRepository),
        ),
        // Thêm các bloc khác ở đây nếu cần
      ],
      child: MaterialApp(
        title: 'Flutter App',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        home: const SplashScreen(),
      ),
    );
  }
}
