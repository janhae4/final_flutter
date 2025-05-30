import 'package:final_flutter/logic/auth/auth_repository.dart';
import 'package:flutter/material.dart';
import 'ui/screens/auth/login_screen.dart';
import 'ui/screens/home/home_screen.dart';

class MyApp extends StatefulWidget {
  const MyApp({super.key, required AuthRepository authRepository});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ThemeMode _themeMode = ThemeMode.system;
  Color _accentColor = Colors.blue;

  void setThemeMode(ThemeMode mode) {
    setState(() {
      _themeMode = mode;
    });
  }

  void setAccentColor(Color color) {
    setState(() {
      _accentColor = color;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Mail',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: _accentColor, brightness: Brightness.light),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: _accentColor, brightness: Brightness.dark),
        useMaterial3: true,
      ),
      themeMode: _themeMode,
      initialRoute: '/login',
      routes: {
        '/login': (context) => LoginScreen(),
        '/home': (context) => HomeScreen(
          themeMode: _themeMode,
          setThemeMode: setThemeMode,
          accentColor: _accentColor,
          setAccentColor: setAccentColor,
        ),
      },
    );
  }
} 