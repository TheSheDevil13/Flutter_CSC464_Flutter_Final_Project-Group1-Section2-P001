// ─────────────────────────────────────────────────────────────────────────────
// FILE: lib/widgets/typing_indicator.dart
// Animated "Thinking..." indicator used while waiting for AI responses.
// ─────────────────────────────────────────────────────────────────────────────
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class TypingIndicator extends StatefulWidget {
  const TypingIndicator({super.key});
  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator>
    with TickerProviderStateMixin {
  final List<AnimationController> _ctrls = [];
  final List<Animation<double>>   _anims = [];

  @override
  void initState() {
    super.initState();
    for (int i = 0; i < 3; i++) {
      final c = AnimationController(
          vsync: this, duration: const Duration(milliseconds: 550));
      final a = CurvedAnimation(parent: c, curve: Curves.easeInOut)
          .drive(Tween(begin: 0.0, end: 1.0));
      _ctrls.add(c);
      _anims.add(a);
      Future.delayed(Duration(milliseconds: i * 150),
          () { if (mounted) c.repeat(reverse: true); });
    }
  }

  @override
  void dispose() {
    for (final c in _ctrls) { c.dispose(); }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        // Avatar
        Container(
          width: 28, height: 28,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
                colors: [AppColors.secondary, AppColors.primary]),
          ),
          child: const Icon(Icons.psychology_rounded,
              color: Colors.white, size: 14),
        ),
        const SizedBox(width: 8),

        // Bubble
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant,
            borderRadius: const BorderRadius.only(
              topLeft:      Radius.circular(18),
              topRight:     Radius.circular(18),
              bottomLeft:   Radius.circular(4),
              bottomRight: Radius.circular(18),
            ),
            border: Border.all(
                color: AppColors.secondary.withOpacity(0.18), width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Thinking',
                  style: GoogleFonts.inter(
                      color: AppColors.textMuted,
                      fontSize: 13,
                      fontStyle: FontStyle.italic)),
              const SizedBox(width: 6),
              ...List.generate(3, (i) => AnimatedBuilder(
                animation: _anims[i],
                builder: (_, __) => Transform.translate(
                  offset: Offset(0, -5 * _anims[i].value),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    width: 6, height: 6,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color.lerp(
                        AppColors.textMuted,
                        AppColors.secondary,
                        _anims[i].value,
                      ),
                    ),
                  ),
                ),
              )),
            ],
          ),
        ),
      ],
    );
  }
}