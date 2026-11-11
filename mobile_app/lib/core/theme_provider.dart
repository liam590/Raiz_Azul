import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  static const _key = 'raiz_azul_theme_mode';
  
  ThemeMode _themeMode = ThemeMode.system;
  bool _isInitialized = false;
  
  ThemeMode get themeMode => _themeMode;
  bool get isInitialized => _isInitialized;
  bool get isDarkMode => _themeMode == ThemeMode.dark;
  
  ThemeProvider() {
    _loadTheme();
  }
  
  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final themeIndex = prefs.getInt(_key) ?? 0; // 0=system, 1=light, 2=dark
    _themeMode = ThemeMode.values[themeIndex];
    _isInitialized = true;
    notifyListeners();
  }
  
  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;
    
    _themeMode = mode;
    notifyListeners();
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_key, mode.index);
  }
  
  Future<void> toggleTheme() async {
    final newMode = _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    await setThemeMode(newMode);
  }
}