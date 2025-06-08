import 'package:flutter/material.dart';

class AppColors {
  // Primary Colors
  static const Color primary = Color(0xFF6C63FF);
  static const Color primaryLight = Color(0xFF9C95FF);
  static const Color primaryDark = Color(0xFF764ba2);

  // Secondary Colors
  static const Color secondary = Color(0xFF4CAF50);
  static const Color secondaryLight = Color(0xFF81C784);
  static const Color secondaryDark = Color(0xFF388E3C);

  // Accent Colors
  static const Color accent = Color(0xFFFF6B6B);
  static const Color accentLight = Color(0xFFFF9999);
  static const Color accentDark = Color(0xFFE53E3E);

  // Background Colors (Light)
  static const Color background = Color(0xFFF8F9FA);
  static const Color surface = Colors.white;
  static const Color surfaceVariant = Color(0xFFF1F3F4);

  // Background Colors (Dark)
  static const Color backgroundDark = Color(0xFF121212);
  static const Color surfaceDark = Color(0xFF1E1E1E);
  static const Color surfaceVariantDark = Color(0xFF2D2D2D);

  // Text Colors (Light)
  static const Color textPrimary = Color(0xFF2D3748);
  static const Color textSecondary = Color(0xFF718096);
  static const Color textOnPrimary = Colors.white;
  static const Color textTertiary = Color(0xFFA0AEC0);

  // Text Colors (Dark)
  static const Color textPrimaryDark = Color(0xFFE2E8F0);
  static const Color textSecondaryDark = Color(0xFFA0AEC0);
  static const Color textTertiaryDark = Color(0xFF718096);

  // Status Colors
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFF9800);
  static const Color error = Color(0xFFFF6B6B);
  static const Color info = Color(0xFF2196F3);

  // Neutral Colors (Light)
  static const Color divider = Color(0xFFE2E8F0);
  static const Color border = Color(0xFFCBD5E0);
  static const Color disabled = Color(0xFFA0AEC0);

  // Neutral Colors (Dark)
  static const Color dividerDark = Color(0xFF424242);
  static const Color borderDark = Color(0xFF4A5568);
  static const Color disabledDark = Color(0xFF718096);

  // Special Colors
  static const Color unreadBackground = Color(0xFFF0F8FF);
  static const Color unreadBackgroundDark = Color(0xFF1A365D);
  static const Color starColor = Color(0xFFECC94B);
  static const Color deleteColor = Color(0xFFFC8181);
}

class AppTheme {
  static TextTheme generateTextTheme(double fontSize) {
    return TextTheme(
      bodyLarge: TextStyle(fontSize: fontSize + 2),
      bodyMedium: TextStyle(fontSize: fontSize),
      bodySmall: TextStyle(fontSize: fontSize - 2),
      titleLarge: TextStyle(
        fontSize: fontSize + 6,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  static ThemeData lightTheme(double fontSize) {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      textTheme: generateTextTheme(fontSize),
      // Color Scheme
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        primaryContainer: AppColors.primaryLight,
        secondary: AppColors.secondary,
        secondaryContainer: AppColors.secondaryLight,
        tertiary: AppColors.accent,
        tertiaryContainer: AppColors.accentLight,
        surface: AppColors.surface,
        error: AppColors.error,
        onPrimary: AppColors.textOnPrimary,
        onSecondary: AppColors.textOnPrimary,
        onSurface: AppColors.textPrimary,
        onError: AppColors.textOnPrimary,
        outline: AppColors.border,
        shadow: Colors.black26,
      ),

      // App Bar Theme
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnPrimary,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AppColors.textOnPrimary,
        ),
      ),

      // Card Theme
      cardTheme: CardTheme(
        color: AppColors.surface,
        elevation: 4,
        shadowColor: Colors.black.withAlpha((255 * 0.05).toInt()),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),

      // Elevated Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.textOnPrimary,
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),

      // Text Button Theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
      ),

      // Outlined Button Theme
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),

      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.background,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        labelStyle: const TextStyle(color: AppColors.textSecondary),
        hintStyle: const TextStyle(color: AppColors.disabled),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),

      // Switch Theme
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateColor.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.secondary;
          }
          return AppColors.disabled;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.secondary.withAlpha((255 * 0.5).toInt());
          }
          return AppColors.disabled.withAlpha((255 * 0.3).toInt());
        }),
      ),

      // Checkbox Theme
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primary;
          }
          return Colors.transparent;
        }),
        checkColor: WidgetStateProperty.all(AppColors.textOnPrimary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),

      // Radio Theme
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primary;
          }
          return AppColors.disabled;
        }),
      ),

      // List Tile Theme
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        titleTextStyle: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        subtitleTextStyle: TextStyle(
          fontSize: 14,
          color: AppColors.textSecondary,
        ),
      ),

      // Dialog Theme
      dialogTheme: DialogTheme(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 8,
        titleTextStyle: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
        ),
        contentTextStyle: const TextStyle(
          fontSize: 14,
          color: AppColors.textSecondary,
        ),
      ),

      // Bottom Sheet Theme
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        elevation: 8,
      ),

      // Snack Bar Theme
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.textPrimary,
        contentTextStyle: const TextStyle(color: AppColors.textOnPrimary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
      ),

      // Divider Theme
      dividerTheme: const DividerThemeData(
        color: AppColors.divider,
        thickness: 1,
        space: 1,
      ),

      // Icon Theme
      iconTheme: const IconThemeData(color: AppColors.textSecondary, size: 24),

      // Primary Icon Theme
      primaryIconTheme: const IconThemeData(
        color: AppColors.textOnPrimary,
        size: 24,
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,

      // Color Scheme
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        primaryContainer: AppColors.primaryDark,
        secondary: AppColors.secondary,
        secondaryContainer: AppColors.secondaryDark,
        tertiary: AppColors.accent,
        tertiaryContainer: AppColors.accentDark,
        surface: AppColors.surfaceDark,
        error: AppColors.error,
        onPrimary: AppColors.textOnPrimary,
        onSecondary: AppColors.textOnPrimary,
        onSurface: AppColors.textPrimaryDark,
        onError: AppColors.textOnPrimary,
        outline: AppColors.borderDark,
        shadow: Colors.black87,
      ),

      // App Bar Theme
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.surfaceDark,
        foregroundColor: AppColors.textPrimaryDark,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimaryDark,
        ),
      ),

      // Card Theme
      cardTheme: CardTheme(
        color: AppColors.surfaceDark,
        elevation: 8,
        shadowColor: Colors.black.withAlpha((255 * 0.3).toInt()),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),

      // Elevated Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.textOnPrimary,
          elevation: 4,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),

      // Text Button Theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
      ),

      // Outlined Button Theme
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),

      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceVariantDark,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.borderDark),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.borderDark),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        labelStyle: const TextStyle(color: AppColors.textSecondaryDark),
        hintStyle: const TextStyle(color: AppColors.disabledDark),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),

      // Switch Theme
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateColor.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.secondary;
          }
          return AppColors.disabledDark;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.secondary.withAlpha((255 * 0.5).toInt());
          }
          return AppColors.disabledDark.withAlpha((255 * 0.3).toInt());
        }),
      ),

      // Checkbox Theme
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primary;
          }
          return Colors.transparent;
        }),
        checkColor: WidgetStateProperty.all(AppColors.textOnPrimary),
        side: BorderSide(color: AppColors.borderDark),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),

      // Radio Theme
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primary;
          }
          return AppColors.disabledDark;
        }),
      ),

      // List Tile Theme
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        titleTextStyle: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimaryDark,
        ),
        subtitleTextStyle: TextStyle(
          fontSize: 14,
          color: AppColors.textSecondaryDark,
        ),
      ),

      // Dialog Theme
      dialogTheme: DialogTheme(
        backgroundColor: AppColors.surfaceDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 12,
        titleTextStyle: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimaryDark,
        ),
        contentTextStyle: const TextStyle(
          fontSize: 14,
          color: AppColors.textSecondaryDark,
        ),
      ),

      // Bottom Sheet Theme
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surfaceDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        elevation: 12,
      ),

      // Snack Bar Theme
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.surfaceVariantDark,
        contentTextStyle: const TextStyle(color: AppColors.textPrimaryDark),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
      ),

      // Divider Theme
      dividerTheme: const DividerThemeData(
        color: AppColors.dividerDark,
        thickness: 1,
        space: 1,
      ),

      // Icon Theme
      iconTheme: const IconThemeData(
        color: AppColors.textSecondaryDark,
        size: 24,
      ),

      // Primary Icon Theme
      primaryIconTheme: const IconThemeData(
        color: AppColors.textOnPrimary,
        size: 24,
      ),

      // Text Theme
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimaryDark,
        ),
        headlineMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimaryDark,
        ),
        headlineSmall: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimaryDark,
        ),
        titleLarge: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimaryDark,
        ),
        titleMedium: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimaryDark,
        ),
        titleSmall: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimaryDark,
        ),
        bodyLarge: TextStyle(fontSize: 16, color: AppColors.textPrimaryDark),
        bodyMedium: TextStyle(fontSize: 14, color: AppColors.textPrimaryDark),
        bodySmall: TextStyle(fontSize: 12, color: AppColors.textSecondaryDark),
        labelLarge: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: AppColors.textPrimaryDark,
        ),
        labelMedium: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: AppColors.textSecondaryDark,
        ),
        labelSmall: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: AppColors.textSecondaryDark,
        ),
      ),

      // Scaffold Background Color
      scaffoldBackgroundColor: AppColors.backgroundDark,
    );
  }
}
