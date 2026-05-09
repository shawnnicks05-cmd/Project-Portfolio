// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'data/app_store.dart';
import 'screens/auth_screen.dart';
import 'screens/home_screen.dart';
import 'theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Initialize Firebase
    await Firebase.initializeApp();
    print('Firebase initialized successfully');

    // Test Firestore connection with expected collections
    final firestore = FirebaseFirestore.instance;
    final testSnapshot = await firestore.collection('users').limit(1).get();
    print(
        'Firestore database is ready. Found ${testSnapshot.docs.length} users');
  } catch (e) {
    print('Firebase initialization error: $e');
    if (e.toString().contains('NOT_FOUND') ||
        e.toString().contains('does not exist')) {
      print('Firestore database not created yet. Please visit:');
      print(
          'https://console.cloud.google.com/datastore/setup?project=selecta-coe-main');
    }
    // Continue without Firebase for demo purposes
  }

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
    return ChangeNotifierProvider(
      create: (_) => AppStore(),
      child: MaterialApp(
        title: 'SELECTA-COE',
        theme: AppTheme.theme,
        debugShowCheckedModeBanner: false,
        initialRoute: '/',
        routes: {
          '/': (_) => const AuthScreen(),
          '/home': (_) => const HomeScreen(),
        },
      ),
    );
  }
}
