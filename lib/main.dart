import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'core/firebase/firebase_service.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    PushNotificationService.init(_navigatorKey);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gestión de Trámites',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      navigatorKey: _navigatorKey,
      home: const LoginScreen(),
    );
  }
}
