import 'package:flutter/material.dart';

class AppColors {
  // Light theme (existing)
  static const Color azul = Color(0xFF1463A5);
  static const Color azulSoft = Color(0xFFDCEBF7);
  static const Color azulDeep = Color(0xFF0D4A7C);
  
  static const Color lluvia = Color(0xFF14808F);
  static const Color lluviaSoft = Color(0xFFD6EEF1);
  static const Color lluviaDeep = Color(0xFF0D656D);
  
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
  
  // Dark theme colors
  static const Color darkBg = Color(0xFF0A1620);
  static const Color darkSurface = Color(0xFF111D2A);
  static const Color darkSurface2 = Color(0xFF1A2A3A);
  static const Color darkInk = Color(0xFFE8EEF2);
  static const Color darkMuted = Color(0xFF8BA4B5);
  static const Color darkLine = Color(0xFF2A3F4F);
  static const Color darkAzulSoft = Color(0xFF1A3A5C);
  static const Color darkLluviaSoft = Color(0xFF1A3A4A);
  static const Color darkBroteSoft = Color(0xFF1A3A2A);
  static const Color darkAlertaSoft = Color(0xFF3A2A1A);
  
  // Gradients (same for both themes)
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [azul, lluvia],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient surfaceGradient = LinearGradient(
    colors: [surface, surface2, azulSoft],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
  
  static const LinearGradient darkSurfaceGradient = LinearGradient(
    colors: [darkSurface, darkSurface2, darkAzulSoft],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}

class AppTheme {
  static ThemeData get lightTheme {
    return _buildTheme(
      brightness: Brightness.light,
      bg: AppColors.bg,
      surface: AppColors.surface,
      surface2: AppColors.surface2,
      ink: AppColors.ink,
      muted: AppColors.muted,
      line: AppColors.line,
      azulSoft: AppColors.azulSoft,
      lluviaSoft: AppColors.lluviaSoft,
      broteSoft: AppColors.broteSoft,
      alertaSoft: AppColors.alertaSoft,
      surfaceGradient: AppColors.surfaceGradient,
    );
  }
  
  static ThemeData get darkTheme {
    return _buildTheme(
      brightness: Brightness.dark,
      bg: AppColors.darkBg,
      surface: AppColors.darkSurface,
      surface2: AppColors.darkSurface2,
      ink: AppColors.darkInk,
      muted: AppColors.darkMuted,
      line: AppColors.darkLine,
      azulSoft: AppColors.darkAzulSoft,
      lluviaSoft: AppColors.darkLluviaSoft,
      broteSoft: AppColors.darkBroteSoft,
      alertaSoft: AppColors.darkAlertaSoft,
      surfaceGradient: AppColors.darkSurfaceGradient,
    );
  }
  
  static ThemeData _buildTheme({
    required Brightness brightness,
    required Color bg,
    required Color surface,
    required Color surface2,
    required Color ink,
    required Color muted,
    required Color line,
    required Color azulSoft,
    required Color lluviaSoft,
    required Color broteSoft,
    required Color alertaSoft,
    required LinearGradient surfaceGradient,
  }) {
    final ColorScheme colorScheme = ColorScheme(
      brightness: brightness,
      primary: AppColors.azul,
      onPrimary: Colors.white,
      secondary: AppColors.lluvia,
      onSecondary: Colors.white,
      error: Colors.red.shade400,
      onError: Colors.white,
      surface: surface,
      onSurface: ink,
    );
    
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: bg,
      colorScheme: colorScheme,
      fontFamily: 'Roboto',
      appBarTheme: AppBarTheme(
        backgroundColor: bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: ink),
        titleTextStyle: TextStyle(
          color: ink,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: line),
        ),
        margin: const EdgeInsets.all(12),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.azul,
          foregroundColor: Colors.white,
          elevation: 2,
          shadowColor: AppColors.azul.withValues(alpha: 0.4),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.azul,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface2,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: line, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: line, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.azul, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.red.shade400, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.red.shade600, width: 2),
        ),
        labelStyle: TextStyle(color: muted, fontSize: 14),
        floatingLabelStyle: TextStyle(color: AppColors.azul, fontSize: 13),
      ),
      dividerTheme: DividerThemeData(
        color: line,
        thickness: 1,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}