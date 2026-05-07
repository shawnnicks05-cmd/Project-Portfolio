// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'data/app_store.dart';
import 'screens/auth_screen.dart';
import 'screens/home_screen.dart';
import 'theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Request storage permissions for Android
  if (defaultTargetPlatform == TargetPlatform.android) {
    // Note: Permissions are declared in AndroidManifest.xml
    // This is just a reminder for development
  }

  await AppStore().init();
  runApp(const SelectaCOEApp());
}

class SelectaCOEApp extends StatelessWidget {
  const SelectaCOEApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SELECTA-COE',
      theme: AppTheme.theme,
      debugShowCheckedModeBanner: false,
      initialRoute: AppStore().isLoggedIn ? '/home' : '/',
      routes: {
        '/': (_) => const AuthScreen(),
        '/home': (_) => const HomeScreen(),
      },
    );
  }
}
