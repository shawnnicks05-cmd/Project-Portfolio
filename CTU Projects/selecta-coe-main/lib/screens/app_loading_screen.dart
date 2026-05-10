import 'package:flutter/material.dart';
import '../theme.dart';
import '../widgets/app_logo.dart';

/// Shown while Firebase, local store, and theme finish initializing.
class AppLoadingScreen extends StatelessWidget {
  const AppLoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightBackground,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AppLogo(
                  size: 120,
                  borderRadius: 14,
                  fallbackColor: AppTheme.lightPrimary,
                ),
                const SizedBox(height: 24),
                Text(
                  'SELECTA-COE',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                    color: AppTheme.lightTextPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Student Electronic Ledger & Competency Tracker',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.35,
                    color: AppTheme.lightTextMuted,
                  ),
                ),
                const SizedBox(height: 40),
                SizedBox(
                  width: 36,
                  height: 36,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    color: AppTheme.lightPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
