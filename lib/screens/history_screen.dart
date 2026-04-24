// ─────────────────────────────────────────────────────────────────────────────
// FILE: lib/screens/history_screen.dart
// Shows all past chat sessions. Resume or delete sessions.
// ─────────────────────────────────────────────────────────────────────────────
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/chat_provider.dart';
import '../models/chat_session_model.dart';
import '../theme/app_theme.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});
  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  @override
  void initState() {
    super.initState();
    // Load sessions after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ChatProvider>().loadAllSessions();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ChatProvider>(builder: (ctx, p, _) {
      return Scaffold(
        backgroundColor: AppColors.bg,
        appBar: AppBar(
          title: Text('Chat History',
              style: GoogleFonts.spaceGrotesk(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700)),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_rounded,
                color: AppColors.textSecondary),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: !p.sessionsLoaded
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.primary))
            : p.sessions.isEmpty
                ? _buildEmpty()
                : RefreshIndicator(
                    color: AppColors.primary,
                    onRefresh: () => p.loadAllSessions(),
                    child: ListView.separated(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.all(16),
                      itemCount: p.sessions.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (_, i) => _SessionCard(
                        session:  p.sessions[i],
                        onResume: () => _resume(p, p.sessions[i]),
                        onDelete: () => _confirmDelete(p, p.sessions[i]),
                      ),
                    ),
                  ),
      );
    });
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.history_rounded,
            color: AppColors.textMuted, size: 80),
        const SizedBox(height: 20),
        Text('No chats yet',
            style: GoogleFonts.spaceGrotesk(
                color: AppColors.textSecondary,
                fontSize: 22, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Text('Start a lesson to see your history here',
            style: GoogleFonts.inter(
                color: AppColors.textMuted, fontSize: 14)),
        const SizedBox(height: 32),
        ElevatedButton.icon(
          onPressed: () => Navigator.pushReplacementNamed(context, '/home'),
          icon:  const Icon(Icons.add_rounded),
          label: const Text('Start a Lesson'),
        ),
      ]),
    );
  }

  Future<void> _resume(ChatProvider p, ChatSessionModel s) async {
    final ok = await p.loadSession(s);
    if (!mounted) return;
    if (ok) {
      Navigator.pushNamed(context, '/chat');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(p.errorMessage),
        backgroundColor: AppColors.error,
      ));
    }
  }

  Future<void> _confirmDelete(ChatProvider p, ChatSessionModel s) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.cardBg,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: Text('Delete Session?',
            style: GoogleFonts.spaceGrotesk(
                color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
        content: Text(
          'All messages in this ${s.language} session will be permanently deleted.',
          style: GoogleFonts.inter(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel',
                style: GoogleFonts.inter(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Delete',
                style: GoogleFonts.inter(
                    color: AppColors.error, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (confirmed == true) await p.deleteSession(s.id);
  }
}

// ── Session card ──────────────────────────────────────────────────────────────
class _SessionCard extends StatelessWidget {
  final ChatSessionModel session;
  final VoidCallback onResume;
  final VoidCallback onDelete;

  const _SessionCard({
    required this.session,
    required this.onResume,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final date = DateFormat('MMM d, y • h:mm a').format(session.createdAt);

    return GestureDetector(
      onTap: onResume,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(children: [
          // Flag avatar
          Container(
            width: 52,
            height: 52,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                  colors: [AppColors.primary, AppColors.secondary]),
            ),
            child: Center(
              child: Text(session.languageFlag,
                  style: const TextStyle(fontSize: 26)),
            ),
          ),
          const SizedBox(width: 14),

          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              Text('${session.language} Lesson',
                  style: GoogleFonts.spaceGrotesk(
                      color: AppColors.textPrimary,
                      fontSize: 16, fontWeight: FontWeight.w700)),
              if (session.lastMessage.isNotEmpty) ...[
                const SizedBox(height: 3),
                Text(session.lastMessage,
                    style: GoogleFonts.inter(
                        color: AppColors.textSecondary, fontSize: 12),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
              const SizedBox(height: 6),
              Row(children: [
                const Icon(Icons.access_time_rounded,
                    color: AppColors.textMuted, size: 12),
                const SizedBox(width: 4),
                Text(date,
                    style: GoogleFonts.inter(
                        color: AppColors.textMuted, fontSize: 11)),
                const SizedBox(width: 12),
                const Icon(Icons.chat_bubble_outline_rounded,
                    color: AppColors.textMuted, size: 12),
                const SizedBox(width: 4),
                Text('${session.messageCount} msgs',
                    style: GoogleFonts.inter(
                        color: AppColors.textMuted, fontSize: 11)),
              ]),
            ]),
          ),

          // Resume chip + delete
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: AppColors.primary.withOpacity(0.3)),
                ),
                child: Text('Resume',
                    style: GoogleFonts.inter(
                        color: AppColors.primary,
                        fontSize: 11, fontWeight: FontWeight.w600)),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: onDelete,
                child: const Icon(Icons.delete_outline_rounded,
                    color: AppColors.textMuted, size: 20),
              ),
            ],
          ),
        ]),
      ),
    );
  }
}