import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'screens/dashboard.dart';
import 'screens/hunter/hunter_dashboard.dart';
import 'screens/kurir/courier_dashboard.dart';
import 'screens/otentikasi/login.dart';
import 'screens/otentikasi/register.dart';
import 'screens/penitip/dashboardPenitip.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(const CaptureApp());
}

class CaptureApp extends StatelessWidget {
  const CaptureApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ReuseMart Capture',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xFF4A5E2A),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4A5E2A),
        ),
        useMaterial3: true,
        fontFamily: 'Poppins',
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
            borderSide: const BorderSide(color: Color(0xFF4A5E2A)),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF4A5E2A),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
      ),
      routes: {
        '/login': (_) => const LoginScreen(),
        '/pembeli_dashboard': (_) => const PembeliDashboard(),
        '/penitip_dashboard': (_) => const PenitipDashboard(),
        '/hunter_dashboard': (_) => const HunterDashboard(),
        '/kurir_dashboard': (_) => const CourierDashboard(),
      },
      home: const CaptureMenu(),
    );
  }
}

class CaptureMenu extends StatelessWidget {
  const CaptureMenu({super.key});

  Future<void> _open(
    BuildContext context,
    Widget screen, {
    String? userType,
    String? role,
    String? userId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    if (role != null) {
      await prefs.setString('token', 'capture-token');
      await prefs.setString('role', role);
      await prefs.setString('user_type', userType ?? 'pegawai');
      await prefs.setString('user_id', userId ?? '1');
    }

    if (!context.mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => screen),
    );
  }

  Widget _button(
    BuildContext context,
    String label,
    IconData icon,
    VoidCallback onPressed,
  ) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        key: ValueKey(label),
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(label),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ReuseMart Screen Capture'),
        backgroundColor: const Color(0xFF7A7C52),
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              _button(
                context,
                'Login',
                Icons.login,
                () => _open(context, const LoginScreen()),
              ),
              const SizedBox(height: 12),
              _button(
                context,
                'Register',
                Icons.person_add,
                () => _open(context, const RegisterScreen()),
              ),
              const SizedBox(height: 12),
              _button(
                context,
                'Pembeli',
                Icons.shopping_bag,
                () => _open(context, const PembeliDashboard()),
              ),
              const SizedBox(height: 12),
              _button(
                context,
                'Penitip',
                Icons.inventory_2,
                () => _open(
                  context,
                  const PenitipDashboard(),
                  userType: 'penitip',
                  role: 'penitip',
                  userId: '9',
                ),
              ),
              const SizedBox(height: 12),
              _button(
                context,
                'Hunter',
                Icons.search,
                () => _open(
                  context,
                  const HunterDashboard(),
                  userType: 'pegawai',
                  role: 'hunter',
                  userId: '17',
                ),
              ),
              const SizedBox(height: 12),
              _button(
                context,
                'Kurir',
                Icons.local_shipping,
                () => _open(
                  context,
                  const CourierDashboard(),
                  userType: 'pegawai',
                  role: 'kurir',
                  userId: '21',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
