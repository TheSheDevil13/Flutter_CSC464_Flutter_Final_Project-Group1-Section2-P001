// ─────────────────────────────────────────────────────────────────────────────
// FILE: lib/screens/home_screen.dart
// Language selection screen. Entry point after splash.
// ─────────────────────────────────────────────────────────────────────────────
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/chat_provider.dart';
import '../models/language_data.dart';
import '../theme/app_theme.dart';
import '../widgets/language_card.dart';
import '../widgets/gradient_button.dart';
import '../widgets/app_logo.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _headerCtrl;
  late final Animation<double>   _headerFade;
  late final Animation<Offset>   _headerSlide;
  bool _isStarting = false;

  @override
  void initState() {
    super.initState();
    _headerCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));
    _headerFade = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _headerCtrl, curve: Curves.easeOut));
    _headerSlide = Tween<Offset>(
            begin: const Offset(0, -0.15), end: Offset.zero)
        .animate(CurvedAnimation(parent: _headerCtrl, curve: Curves.easeOut));
    _headerCtrl.forward();
  }

  @override
  void dispose() {
    _headerCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleStart(ChatProvider provider) async {
    if (_isStarting) return;
    setState(() => _isStarting = true);

    final success = await provider.startNewChat();

    if (!mounted) return;
    setState(() => _isStarting = false);

    if (success) {
      Navigator.pushNamed(context, '/chat');
    } else {
      _showError(provider.errorMessage);
      provider.clearError();
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.inter(fontSize: 14)),
        backgroundColor: AppColors.error,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ChatProvider>(
      builder: (ctx, provider, _) => Scaffold(
        backgroundColor: AppColors.bg,
        appBar: AppBar(
          title: const AppLogo(size: 28),
          actions: [
            IconButton(
              icon: const Icon(Icons.history_rounded),
              tooltip: 'Chat History',
              onPressed: () => Navigator.pushNamed(context, '/history'),
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                // ── Header ──────────────────────────────────────────────────
                SlideTransition(
                  position: _headerSlide,
                  child: FadeTransition(
                    opacity: _headerFade,
                    child: _buildHeader(provider),
                  ),
                ),

                const SizedBox(height: 24),

                // ── Grid label ──────────────────────────────────────────────
                Text(
                  'SELECT A LANGUAGE',
                  style: GoogleFonts.inter(
                    color: AppColors.textMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 12),

                // ── Language Grid ────────────────────────────────────────────
                Expanded(
                  child: GridView.builder(
                    physics: const BouncingScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 1.45,
                    ),
                    itemCount: kAvailableLanguages.length,
                    itemBuilder: (_, i) {
                      final lang  = kAvailableLanguages[i];
                      final isSel = provider.selectedLanguage.name == lang.name;
                      return LanguageCard(
                        lang:      lang,
                        isSelected: isSel,
                        delay:     Duration(milliseconds: i * 55),
                        onTap:     () => provider.selectLanguage(lang),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 16),

                // ── Start Button ────────────────────────────────────────────
                GradientButton(
                  label:     'Start Learning ${provider.selectedLanguage.name}',
                  icon:      Icons.auto_awesome_rounded,
                  isLoading: _isStarting,
                  onTap:     () => _handleStart(provider),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ChatProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'What would you\nlike to learn? 🌍',
          style: GoogleFonts.spaceGrotesk(
            fontSize: 30,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Pick a language — your AI tutor is ready',
          style: GoogleFonts.inter(
              fontSize: 15, color: AppColors.textSecondary, height: 1.5),
        ),
      ],
    );
  }
}