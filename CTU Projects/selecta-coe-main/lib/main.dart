// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:selecta_coee/data/firebase_database_service.dart';
import 'data/app_store.dart';
import 'screens/auth_screen.dart';
import 'screens/Dashboard.dart';
import 'screens/app_loading_screen.dart';
import 'theme.dart';
import 'theme_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const _BootstrapApp());
}

/// Shows [AppLoadingScreen] until async startup completes, then runs the real app.
class _BootstrapApp extends StatefulWidget {
  const _BootstrapApp();

  @override
  State<_BootstrapApp> createState() => _BootstrapAppState();
}

class _BootstrapAppState extends State<_BootstrapApp> {
  ThemeProvider? _themeProvider;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _runStartup();
  }

  Future<void> _runStartup() async {
    try {
      try {
        await Firebase.initializeApp();
        print('Firebase initialized successfully');

        // Initialize Firebase Auth
        FirebaseAuth.instance;
        print('Firebase Auth initialized');

        final firestore = FirebaseFirestore.instance;
        final testSnapshot = await firestore.collection('users').limit(1).get();
        print(
          'Firestore database is ready. Found ${testSnapshot.docs.length} users',
        );
      } catch (e) {
        print('Firebase initialization error: $e');
        if (e.toString().contains('NOT_FOUND') ||
            e.toString().contains('does not exist')) {
          print('Firestore database not created yet. Please visit:');
          print(
            'https://console.cloud.google.com/datastore/setup?project=selecta-coe-main',
          );
        }
      }

      if (defaultTargetPlatform == TargetPlatform.android) {
        // Note: Permissions are declared in AndroidManifest.xml
      }

      await AppStore().init();

      try {
        final firebaseService = FirebaseDatabaseService();
        await firebaseService.createTestData();
      } catch (e) {
        print('Test data creation skipped: $e');
      }

      final themeProvider = ThemeProvider();
      await themeProvider.init();

      if (!mounted) return;
      setState(() {
        _themeProvider = themeProvider;
        _errorMessage = null;
      });
    } catch (e, st) {
      print('Startup error: $e\n$st');
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_errorMessage != null) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          backgroundColor: AppTheme.lightBackground,
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline,
                      size: 48, color: AppTheme.lightDanger),
                  const SizedBox(height: 16),
                  Text(
                    'Could not start the app',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.lightTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _errorMessage!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: AppTheme.lightTextSecondary, fontSize: 13),
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: () {
                      setState(() {
                        _errorMessage = null;
                        _themeProvider = null;
                      });
                      _runStartup();
                    },
                    child: const Text('Try again'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    if (_themeProvider == null) {
      return const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: AppLoadingScreen(),
      );
    }

    return SelectaCOEApp(themeProvider: _themeProvider!);
  }
}

class SelectaCOEApp extends StatelessWidget {
  final ThemeProvider themeProvider;
  const SelectaCOEApp({super.key, required this.themeProvider});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppStore()),
        ChangeNotifierProvider.value(value: themeProvider),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'SELECTA-COE',
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,
            debugShowCheckedModeBanner: false,
            initialRoute: '/',
            routes: {
              '/': (_) => const AuthScreen(),
              '/home': (_) => const HomeScreen(),
            },
          );
        },
      ),
    );
  }
}
