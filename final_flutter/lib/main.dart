import 'package:final_flutter/logic/notification/notification_bloc.dart';
import 'package:final_flutter/logic/settings/settings_bloc.dart';
import 'package:final_flutter/logic/settings/settings_event.dart';
import 'package:final_flutter/logic/settings/settings_state.dart';
import 'package:final_flutter/service/notification_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:final_flutter/config/app_theme.dart';
import 'package:final_flutter/logic/auth/auth_bloc.dart';
import 'package:final_flutter/logic/auth/auth_repository.dart';
import 'package:final_flutter/logic/email/email_bloc.dart';
import 'package:final_flutter/logic/email/email_repository.dart';
import 'package:final_flutter/presentation/screens/auth/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await _initializeServices();

    final authRepository = AuthRepository();
    final emailRepository = EmailRepository();

    runApp(
      MyApp(authRepository: authRepository, emailRepository: emailRepository),
    );
  } catch (e) {
    debugPrint('Error initializing app: $e');
  }
}

Future<void> _initializeServices() async {
  await NotificationService().initialize();
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
      providers: _buildBlocProviders(),
      child: BlocBuilder<SettingsBloc, SettingsState>(
        builder: (context, settingsState) {
          return MaterialApp(
            title: 'Flutter Email App',
            debugShowCheckedModeBanner: false,

            theme: AppTheme.lightTheme(settingsState.fontSize),
            darkTheme: AppTheme.darkTheme,
            themeMode: _getThemeMode(settingsState),

            home: const SplashScreen(),

            // Global error handling
            builder: (context, child) {
              return MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  textScaler: TextScaler.linear(
                    MediaQuery.of(
                      context,
                    ).textScaler.scale(1.0).clamp(0.8, 1.2),
                  ),
                ),
                child: child ?? const SizedBox.shrink(),
              );
            },
          );
        },
      ),
    );
  }

  List<BlocProvider> _buildBlocProviders() {
    final notificationBloc = NotificationBloc();

    return [
      // Auth Bloc
      BlocProvider<AuthBloc>(create: (_) => AuthBloc(authRepository)),

      // Settings Bloc
      BlocProvider<SettingsBloc>(
        create: (_) => SettingsBloc()..add(LoadSettingsEvent()),
      ),

      // Notification Bloc
      BlocProvider<NotificationBloc>.value(value: notificationBloc),

      // Email Bloc
      BlocProvider<EmailBloc>(
        create: (context) => EmailBloc(
          emailRepository: emailRepository,
          notificationBloc: notificationBloc,
          authBloc: BlocProvider.of<AuthBloc>(context),
          settingsBloc: BlocProvider.of<SettingsBloc>(context),
        ),
      ),
    ];
  }

  ThemeMode _getThemeMode(SettingsState state) {
    return state.isDarkMode ? ThemeMode.dark : ThemeMode.light;
  }
}
