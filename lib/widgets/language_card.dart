// ─────────────────────────────────────────────────────────────────────────────
// FILE: lib/widgets/language_card.dart
// Interactive card for language selection with elastic entrance animation.
// ─────────────────────────────────────────────────────────────────────────────
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/language_data.dart';
import '../theme/app_theme.dart';

class LanguageCard extends StatefulWidget {
  final LanguageData lang;
  final bool        isSelected;
  final VoidCallback onTap;
  final Duration     delay;

  const LanguageCard({
    super.key,
    required this.lang,
    required this.isSelected,
    required this.onTap,
    this.delay = Duration.zero,
  });

  @override
  State<LanguageCard> createState() => _LanguageCardState();
}

class _LanguageCardState extends State<LanguageCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double>   _fade;
  late final Animation<double>   _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _fade  = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut)
        .drive(Tween(begin: 0.0, end: 1.0));
    _scale = CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut)
        .drive(Tween(begin: 0.75, end: 1.0));
    
    // Trigger entrance animation after the specified delay
    Future.delayed(widget.delay, () { if (mounted) _ctrl.forward(); });
  }

  @override
  void dispose() { 
    _ctrl.dispose(); 
    super.dispose(); 
  }

  // Converts the hex string from model to a usable Flutter Color
  Color get _accentColor =>
      Color(int.parse('FF${widget.lang.colorHex}', radix: 16));

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: ScaleTransition(
        scale: _scale,
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: widget.isSelected
                  ? const LinearGradient(
                      colors: [
                        AppColors.primary,
                        AppColors.primaryDark,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
              color: widget.isSelected ? null : AppColors.cardBg,
              border: Border.all(
                color: widget.isSelected
                    ? AppColors.primary
                    : AppColors.divider,
                width: 1.5,
              ),
              boxShadow: widget.isSelected
                  ? [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.35),
                        blurRadius: 18,
                        spreadRadius: 2,
                        offset: const Offset(0, 4),
                      )
                    ]
                  : [],
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top row: flag + checkmark indicator
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(widget.lang.flag,
                          style: const TextStyle(fontSize: 28)),
                      if (widget.isSelected)
                        Container(
                          width: 22, height: 22,
                          decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white24),
                          child: const Icon(Icons.check_rounded,
                              color: Colors.white, size: 14),
                        )
                      else
                        Container(
                          width: 10, height: 10,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _accentColor.withOpacity(0.6),
                          ),
                        ),
                    ],
                  ),
                  const Spacer(),
                  // Language labels
                  Text(
                    widget.lang.name,
                    style: GoogleFonts.spaceGrotesk(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    widget.lang.nativeName,
                    style: GoogleFonts.inter(
                      color: widget.isSelected
                          ? Colors.white60
                          : AppColors.textMuted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}