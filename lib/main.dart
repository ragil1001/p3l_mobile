import 'package:flutter/material.dart';
import 'screens/otentikasi/login.dart';
import 'screens/otentikasi/register.dart';
import 'screens/pembeli.dart';
import 'screens/hunter.dart';
import 'screens/kurir.dart';
import 'screens/penitip.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ReuseMart',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xFF00BFA5),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF00BFA5),
        ),
        useMaterial3: true,
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.grey[100],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF00BFA5)),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF00BFA5),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
      ),
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/pembeli_dashboard': (context) => const PembeliScreen(),
        '/hunter_dashboard': (context) => const HunterScreen(),
        '/kurir_dashboard': (context) => const KurirScreen(),
        '/penitip_dashboard': (context) => const PenitipScreen(),
      },
    );
  }
}
