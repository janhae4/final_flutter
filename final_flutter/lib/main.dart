import 'package:final_flutter/logic/notification/notification_bloc.dart';
import 'package:final_flutter/service/notification_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:final_flutter/config/app_theme.dart';
import 'package:final_flutter/logic/auth/auth_bloc.dart';
import 'package:final_flutter/logic/auth/auth_repository.dart';
import 'package:final_flutter/logic/email/email_bloc.dart';
import 'package:final_flutter/logic/email/email_repository.dart';
import 'package:final_flutter/presentation/screens/auth/splash_screen.dart';
import 'logic/settings/settings_bloc.dart';
import 'logic/settings/settings_state.dart';
import 'logic/settings/settings_event.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart';

void main() async {
  final authRepository = AuthRepository();
  final emailRepository = EmailRepository();
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService().initialize();
  runApp(
    MyApp(authRepository: authRepository, emailRepository: emailRepository),
  );
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
    final notificationBloc = NotificationBloc();

    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(create: (_) => AuthBloc(authRepository)),
        BlocProvider<NotificationBloc>.value(value: notificationBloc),
        BlocProvider<SettingsBloc>(create: (_) => SettingsBloc()),
        BlocProvider<EmailBloc>(
          create: (context) => EmailBloc(
            emailRepository: emailRepository,
            notificationBloc: notificationBloc,
            settingsBloc: context.read<SettingsBloc>(),
            authBloc: context.read<AuthBloc>(),
          ),
        ),
      ],
      child: BlocBuilder<SettingsBloc, SettingsState>(
        builder: (context, state) {
          return MaterialApp(
            title: 'Flutter App',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: state.isDarkMode ? ThemeMode.dark : ThemeMode.light,
            home: const SplashScreen(),
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
              FlutterQuillLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('en'),
              // Thêm các locale khác nếu muốn hỗ trợ
            ],
          );
        },
      ),
    );
  }
}
