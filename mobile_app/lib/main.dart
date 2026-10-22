import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'core/theme.dart';
import 'screens/main_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('es', null);
  runApp(const RaizAzulApp());
}

class RaizAzulApp extends StatelessWidget {
  const RaizAzulApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Raíz Azul',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const MainScreen(),
    );
  }
}
