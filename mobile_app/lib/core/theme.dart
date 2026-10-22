import 'package:flutter/material.dart';

class AppColors {
  static const Color azul = Color(0xFF1463A5);
  static const Color azulSoft = Color(0xFFDCEBF7);
  
  static const Color lluvia = Color(0xFF14808F);
  static const Color lluviaSoft = Color(0xFFD6EEF1);
  
  static const Color brote = Color(0xFF2F7F45);
  static const Color broteSoft = Color(0xFFDDEFE2);
  
  static const Color tierra = Color(0xFF8A5731);
  static const Color tierraSoft = Color(0xFFF2E6DB);
  
  static const Color alerta = Color(0xFFA85F00);
  static const Color alertaSoft = Color(0xFFFBEBD0);
  
  static const Color bg = Color(0xFFEDF3F6);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surface2 = Color(0xFFF5F9FB);
  static const Color ink = Color(0xFF0B2530);
  static const Color muted = Color(0xFF556F7B);
  static const Color line = Color(0xFFD3E0E6);
}

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.bg,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.azul,
        primary: AppColors.azul,
        surface: AppColors.surface,
        onSurface: AppColors.ink,
      ),
      fontFamily: 'Roboto',
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: AppColors.ink),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: AppColors.line),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.azul,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
      ),
    );
  }
}
