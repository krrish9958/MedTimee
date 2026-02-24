import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color primaryViolet = Color(0xFF7A3CF3);
  static const Color softViolet = Color(0xFFECE3FF);
  static const Color softBlue = Color(0xFFE6EEFF);
  static const Color ink = Color(0xFF251B3B);
  static const Color muted = Color(0xFF6C6780);

  static ThemeData light() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: primaryViolet,
      brightness: Brightness.light,
    );

    final textTheme = GoogleFonts.poppinsTextTheme().copyWith(
      headlineLarge: const TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        color: ink,
        height: 1.08,
      ),
      headlineMedium: const TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: ink,
        height: 1.1,
      ),
      headlineSmall: const TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: ink,
        height: 1.15,
      ),
      titleLarge: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: ink,
      ),
      titleMedium: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: ink,
      ),
      bodyLarge: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w500,
        color: ink,
        height: 1.35,
      ),
      bodyMedium: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: muted,
        height: 1.35,
      ),
      bodySmall: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: muted,
        height: 1.3,
      ),
      labelLarge: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
      ),
      labelMedium: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
      ),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      textTheme: textTheme,
      primaryTextTheme: textTheme,
      scaffoldBackgroundColor: Colors.transparent,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 31 / 1.4,
          fontWeight: FontWeight.w700,
          color: ink,
        ),
      ),
      cardTheme: CardThemeData(
        color: Colors.white.withValues(alpha: 0.7),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: ink, size: 23);
          }
          return IconThemeData(color: ink.withValues(alpha: 0.75), size: 20);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            fontSize: selected ? 13 : 12.2,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? ink : muted,
          );
        }),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primaryViolet,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: textTheme.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryViolet.withValues(alpha: 0.85),
          textStyle: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.78),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        hintStyle: textTheme.bodyMedium?.copyWith(
          color: muted.withValues(alpha: 0.8),
        ),
        helperStyle: textTheme.bodySmall,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  static ThemeData dark() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: primaryViolet,
      brightness: Brightness.dark,
    );

    final textTheme = GoogleFonts.poppinsTextTheme(ThemeData.dark().textTheme)
        .copyWith(
          headlineSmall: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: Color(0xFFF3ECFF),
          ),
          titleLarge: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Color(0xFFF3ECFF),
          ),
          titleMedium: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFFE8DFFF),
          ),
          bodyLarge: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: Color(0xFFE8DFFF),
            height: 1.35,
          ),
          bodyMedium: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFFC8BDE3),
            height: 1.35,
          ),
          bodySmall: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Color(0xFFB6ABCf),
          ),
          labelLarge: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFFF3ECFF),
          ),
        );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      textTheme: textTheme,
      primaryTextTheme: textTheme,
      scaffoldBackgroundColor: Colors.transparent,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 31 / 1.4,
          fontWeight: FontWeight.w700,
          color: Color(0xFFF3ECFF),
        ),
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFF2A3348).withValues(alpha: 0.86),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: Color(0xFFF3ECFF), size: 23);
          }
          return const IconThemeData(color: Color(0xFFBBB2D5), size: 20);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            fontSize: selected ? 13 : 12.2,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? const Color(0xFFF3ECFF) : const Color(0xFFBBB2D5),
          );
        }),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primaryViolet,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: textTheme.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: const Color(0xFFD6C9FF),
          textStyle: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF202A3F),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        hintStyle: textTheme.bodyMedium?.copyWith(color: const Color(0xFF9F95BA)),
        helperStyle: textTheme.bodySmall,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
      dividerColor: const Color(0xFF3A445A),
    );
  }
}
