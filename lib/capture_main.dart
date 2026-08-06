import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/dashboard.dart';
import 'screens/otentikasi/login.dart';
import 'screens/otentikasi/register.dart';
import 'screens/penitip/dashboardPenitip.dart';
import 'screens/hunter/hunter_dashboard.dart';
import 'screens/kurir/courier_dashboard.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final screen = Uri.base.queryParameters['screen'] ?? 'pembeli';
  final prefs = await SharedPreferences.getInstance();
  await prefs.clear();

  if (screen == 'hunter') {
    await prefs.setString('token', 'capture-token');
    await prefs.setString('role', 'hunter');
    await prefs.setString('user_type', 'pegawai');
    await prefs.setString('user_id', '17');
  } else if (screen == 'kurir') {
    await prefs.setString('token', 'capture-token');
    await prefs.setString('role', 'kurir');
    await prefs.setString('user_type', 'pegawai');
    await prefs.setString('user_id', '21');
  } else if (screen == 'penitip') {
    await prefs.setString('token', 'capture-token');
    await prefs.setString('role', 'penitip');
    await prefs.setString('user_type', 'penitip');
    await prefs.setString('user_id', '9');
  }

  Widget page;
  switch (screen) {
    case 'login':
      page = const LoginScreen();
      break;
    case 'register':
      page = const RegisterScreen();
      break;
    case 'penitip':
      page = const PenitipDashboard();
      break;
    case 'hunter':
      page = const HunterDashboard();
      break;
    case 'kurir':
      page = const CourierDashboard();
      break;
    default:
      page = const PembeliDashboard();
  }

  runApp(MaterialApp(
    title: 'ReuseMart Capture',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      primaryColor: const Color(0xFF4A5E2A),
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF4A5E2A)),
      useMaterial3: true,
      fontFamily: 'Poppins',
    ),
    routes: {
      '/login': (_) => const LoginScreen(),
      '/pembeli_dashboard': (_) => const PembeliDashboard(),
      '/penitip_dashboard': (_) => const PenitipDashboard(),
      '/hunter_dashboard': (_) => const HunterDashboard(),
      '/kurir_dashboard': (_) => const CourierDashboard(),
    },
    home: page,
  ));
}
