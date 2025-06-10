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
import 'package:final_flutter/logic/auth/auth_event.dart';
import 'package:final_flutter/logic/auth/auth_state.dart';
import 'package:final_flutter/logic/email/email_bloc.dart';
import 'package:final_flutter/logic/email/email_repository.dart';
import 'package:final_flutter/presentation/screens/auth/splash_screen.dart';
import 'package:flutter_quill/flutter_quill.dart';

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
            home: const AppInitializer(),
            localizationsDelegates: const [
              FlutterQuillLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('en'),
            ],
            builder: (context, child) {
              return MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  textScaler: TextScaler.linear(
                    MediaQuery.of(context).textScaler.scale(1.0).clamp(0.8, 1.2),
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

// Widget mới để handle việc khởi tạo và check health
class AppInitializer extends StatefulWidget {
  const AppInitializer({super.key});

  @override
  State<AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer> {
  @override
  void initState() {
    super.initState();
    // Trigger health check khi widget được khởi tạo
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthBloc>().add(CheckHealthEvent());
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        // Khi health check thành công, chuyển đến SplashScreen
        if (state is AuthHealthCheckSuccess) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const SplashScreen()),
          );
        }
      },
      child: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          if (state is AuthHealthCheckFailure) {
            return _buildErrorScreen(state.error);
          }
          
          // Hiển thị loading screen trong khi check health
          return _buildLoadingScreen();
        },
      ),
    );
  }

  Widget _buildLoadingScreen() {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.email,
              size: 80,
              color: AppColors.primary,
            ),
            const SizedBox(height: 32),
            
            CircularProgressIndicator(
              color: AppColors.primary,
              strokeWidth: 3,
            ),
            const SizedBox(height: 24),
            
            Text(
              'Initializing...',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).primaryColor,
              ),
            ),
            const SizedBox(height: 8),
            
            Text(
              'Please wait while we set up your email app',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: .7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorScreen(String error) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 80,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 32),
              
              Text(
                'Connection Error',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
              const SizedBox(height: 16),
              
              Text(
                'Unable to connect to the server. Please check your internet connection and try again.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: .7),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              
              Text(
                'Error: $error',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: .5),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              
              ElevatedButton.icon(
                onPressed: () {
                  // Retry health check
                  context.read<AuthBloc>().add(CheckHealthEvent());
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}