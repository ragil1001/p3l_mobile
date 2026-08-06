import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'firebase_options.dart';
import 'screens/dashboard.dart';
import 'screens/hunter/hunter_dashboard.dart';
import 'screens/kurir/courier_dashboard.dart';
import 'screens/otentikasi/login.dart';
import 'screens/otentikasi/register.dart';
import 'screens/penitip/dashboardPenitip.dart';

const _captureChannel = MethodChannel('com.example.p3l_mobile/capture');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final screen =
      await _captureChannel.invokeMethod<String>('getCaptureScreen') ?? 'pembeli';
  final prefs = await SharedPreferences.getInstance();
  await prefs.clear();

  if (screen == 'penitip') {
    await prefs.setString('token', 'capture-token');
    await prefs.setString('role', 'penitip');
    await prefs.setString('user_type', 'penitip');
    await prefs.setString('user_id', '9');
  } else if (screen == 'hunter') {
    await prefs.setString('token', 'capture-token');
    await prefs.setString('role', 'hunter');
    await prefs.setString('user_type', 'pegawai');
    await prefs.setString('user_id', '17');
  } else if (screen == 'kurir') {
    await prefs.setString('token', 'capture-token');
    await prefs.setString('role', 'kurir');
    await prefs.setString('user_type', 'pegawai');
    await prefs.setString('user_id', '21');
  }

  Widget home;
  switch (screen) {
    case 'login':
      home = const LoginScreen();
      break;
    case 'register':
      home = const RegisterScreen();
      break;
    case 'penitip':
      home = const PenitipDashboard();
      break;
    case 'hunter':
      home = const HunterDashboard();
      break;
    case 'kurir':
      home = const CourierDashboard();
      break;
    default:
      home = const PembeliDashboard();
  }

  runApp(CaptureApp(home: home));
}

class CaptureApp extends StatelessWidget {
  const CaptureApp({super.key, required this.home});

  final Widget home;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ReuseMart',
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
      ),
      routes: {
        '/login': (_) => const LoginScreen(),
        '/pembeli_dashboard': (_) => const PembeliDashboard(),
        '/penitip_dashboard': (_) => const PenitipDashboard(),
        '/hunter_dashboard': (_) => const HunterDashboard(),
        '/kurir_dashboard': (_) => const CourierDashboard(),
      },
      home: home,
    );
  }
}
