import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/otentikasi/login.dart';
import 'screens/otentikasi/register.dart';
import 'screens/pembeli.dart';
import 'screens/hunter.dart';
import 'screens/kurir.dart';
import 'screens/penitip.dart';
import 'screens/otentikasi/loadingPage.dart';
import 'firebase_options.dart';
import 'services/auth_service.dart';
import 'services/notification_service.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  print('Handling background message: ${message.messageId}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  FlutterNativeSplash.preserve(widgetsBinding: WidgetsBinding.instance);

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  final authService = AuthService();
  final token = await authService.getToken();
  if (token != null) {
    final fcmToken = await FirebaseMessaging.instance.getToken();
    if (fcmToken != null) {
      await authService.sendFcmTokenToBackend(fcmToken);
    }
  }

  FirebaseMessaging.instance.onTokenRefresh.listen((fcmToken) async {
    await authService.sendFcmTokenToBackend(fcmToken);
    print('FCM token refreshed: $fcmToken');
  }).onError((err) {
    print('Error refreshing FCM token: $err');
  });

  FlutterNativeSplash.remove();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  Future<Widget> _getInitialScreen() async {
    final authService = AuthService();
    final token = await authService.getToken();
    if (token == null) {
      return const SplashScreen();
    }

    final userType = await authService.getUserType();
    final role = await authService.getRole();
    if (userType == 'pembeli' && role == 'pembeli') {
      return const PembeliScreen();
    } else if (userType == 'penitip' && role == 'penitip') {
      return const PenitipScreen();
    } else if (userType == 'pegawai' && role == 'hunter') {
      return const HunterScreen();
    } else if (userType == 'pegawai' && role == 'kurir') {
      return const KurirScreen();
    }
    return const LoginScreen();
  }

  @override
  Widget build(BuildContext context) {
    final notificationService = NotificationService();

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
      home: FutureBuilder<Widget>(
        future: _getInitialScreen(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          return snapshot.data ?? const SplashScreen();
        },
      ),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/pembeli_dashboard': (context) => const PembeliScreen(),
        '/hunter_dashboard': (context) => const HunterScreen(),
        '/kurir_dashboard': (context) => const KurirScreen(),
        '/penitip_dashboard': (context) => const PenitipScreen(),
      },
      builder: (context, child) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          notificationService.initialize(context);
          notificationService.checkInitialMessage(context);
        });
        return child!;
      },
    );
  }
}

extension AuthServiceExtension on AuthService {
  Future<String?> getUserType() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_type');
  }
}
