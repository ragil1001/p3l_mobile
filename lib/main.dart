import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'screens/otentikasi/login.dart';
import 'screens/otentikasi/register.dart';
import 'screens/pembeli.dart';
import 'screens/hunter.dart';
import 'screens/kurir.dart';
import 'screens/penitip.dart';
import 'firebase_options.dart';
import 'services/auth_service.dart';
import 'services/notification_service.dart';

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  print('Handling background message: ${message.messageId}');
  // You can add custom logic here, e.g., update local data
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Set background message handler
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

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final notificationService = NotificationService();

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
      builder: (context, child) {
        // Initialize notification service
        WidgetsBinding.instance.addPostFrameCallback((_) {
          notificationService.initialize(context);
          notificationService.checkInitialMessage(context);
        });
        return child!;
      },
    );
  }
}
