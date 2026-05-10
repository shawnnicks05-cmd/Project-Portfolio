import 'package:flutter/material.dart';

/// Path to the main brand image — change here only; used by auth + loading screens.
class AppAssets {
  AppAssets._();

  static const String logo = 'assets/LOGO.png';
}

/// Shared logo treatment for auth (tabs include Sign In / Create Account) and splash loading.
class AppLogo extends StatelessWidget {
  const AppLogo({
    super.key,
    required this.size,
    this.borderRadius = 12,
    this.fallbackColor,
  });

  final double size;
  final double borderRadius;
  final Color? fallbackColor;

  @override
  Widget build(BuildContext context) {
    final iconColor =
        fallbackColor ?? Theme.of(context).colorScheme.primary;

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: SizedBox(
        width: size,
        height: size,
        child: Image.asset(
          AppAssets.logo,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => Icon(
            Icons.school_rounded,
            size: size * 0.45,
            color: iconColor,
          ),
        ),
      ),
    );
  }
}
