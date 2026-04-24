// ─────────────────────────────────────────────────────────────────────────────
// FILE: lib/widgets/app_logo.dart
// Reusable branding widget with gradient icon and stylized text.
// ─────────────────────────────────────────────────────────────────────────────
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class AppLogo extends StatelessWidget {
  final double size;
  const AppLogo({super.key, this.size = 24});

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      // Gradient Icon Container
      Container(
        width: size + 10, height: size + 10,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            colors: [AppColors.primary, AppColors.secondary]),
          boxShadow: [BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 10)],
        ),
        child: Icon(Icons.language_rounded,
            color: Colors.white, size: size * 0.65),
      ),
      const SizedBox(width: 8),
      // App Name
      Text('LinguaAI',
          style: GoogleFonts.spaceGrotesk(
            color: AppColors.textPrimary,
            fontSize: size,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          )),
    ]);
  }
}