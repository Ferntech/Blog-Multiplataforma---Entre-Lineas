import 'package:material_ui/material_ui.dart';

class AppColors {
  AppColors._();

  // Superficies y papel editorial
  static const Color paperBg = Color(0xFFFAF7F2);
  static const Color cardSurface = Color(0xFFFFFFFF);
  static const Color parchment = Color(0xFFFFFBEB);
  static const Color parchmentSoft = Color(0xFFF3EFE6);
  static const Color warmBorder = Color(0xFFE5DEC9);

  // Tintas y tipografía
  static const Color inkNavy = Color(0xFF08245C);
  static const Color inkNavyDeep = Color(0xFF05183D);
  static const Color inkBody = Color(0xFF1F2937);
  static const Color inkMuted = Color(0xFF57534E);

  // Acentos libreros
  static const Color amberPrimary = Color(0xFFB45309);
  static const Color amberGold = Color(0xFFD97706);
  static const Color espressoDark = Color(0xFF291D16);
}

class AppTheme {
  AppTheme._();

  static ThemeData get lightTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.amberPrimary,
      primary: AppColors.amberPrimary,
      onPrimary: Colors.white,
      secondary: AppColors.inkNavy,
      onSecondary: Colors.white,
      surface: AppColors.paperBg,
      onSurface: AppColors.inkBody,
      surfaceContainerLow: AppColors.cardSurface,
      surfaceContainer: AppColors.parchmentSoft,
      outline: AppColors.warmBorder,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.paperBg,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.cardSurface,
        foregroundColor: AppColors.inkNavy,
        elevation: 0,
        scrolledUnderElevation: 1,
        surfaceTintColor: Colors.transparent,
        iconTheme: IconThemeData(color: AppColors.inkNavy),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.cardSurface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: AppColors.amberPrimary.withValues(alpha: 0.14),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? AppColors.amberPrimary : AppColors.inkMuted,
          );
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            fontSize: 12,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? AppColors.amberPrimary : AppColors.inkMuted,
          );
        }),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.cardSurface,
        labelStyle: const TextStyle(color: AppColors.inkMuted),
        prefixIconColor: AppColors.inkNavy,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.warmBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: AppColors.amberPrimary,
            width: 1.8,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1.8),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.amberPrimary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.inkNavy,
          side: const BorderSide(color: AppColors.warmBorder),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.warmBorder,
        thickness: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.inkNavyDeep,
        contentTextStyle: const TextStyle(color: Colors.white),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }
}
