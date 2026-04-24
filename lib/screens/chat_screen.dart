// ─────────────────────────────────────────────────────────────────────────────
// FILE: lib/screens/chat_screen.dart
// Main chat interface. Displays messages, handles input, shows typing indicator.
// ─────────────────────────────────────────────────────────────────────────────
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/chat_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/message_bubble.dart';
import '../widgets/typing_indicator.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});
  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _textCtrl    = TextEditingController();
  final _scrollCtrl  = ScrollController();
  final _focusNode    = FocusNode();
  bool  _canSend      = false;

  @override
  void initState() {
    super.initState();
    _textCtrl.addListener(() {
      final hasText = _textCtrl.text.trim().isNotEmpty;
      if (hasText != _canSend) setState(() => _canSend = hasText);
    });
  }

  @override
  void dispose() {
    _textCtrl.dispose();
    _scrollCtrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent + 100,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _send() async {
    final text = _textCtrl.text.trim();
    if (text.isEmpty) return;
    _textCtrl.clear();
    setState(() => _canSend = false);
    _focusNode.requestFocus();

    final provider = context.read<ChatProvider>();
    await provider.sendMessage(text);
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ChatProvider>(builder: (ctx, p, _) {
      // Scroll whenever messages change
      if (p.messages.isNotEmpty || p.isLoading) _scrollToBottom();

      return Scaffold(
        backgroundColor: AppColors.bg,
        appBar: _buildAppBar(p),
        body: Column(
          children: [
            // Error banner
            if (p.hasError)
              _ErrorBanner(message: p.errorMessage, onDismiss: p.clearError),

            // Messages
            Expanded(
              child: p.messages.isEmpty && !p.isLoading
                  ? _buildEmpty(p.selectedLanguage.name)
                  : ListView.builder(
                      controller: _scrollCtrl,
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                      itemCount:
                          p.messages.length + (p.isLoading ? 1 : 0),
                      itemBuilder: (_, i) {
                        if (i == p.messages.length && p.isLoading) {
                          return const Padding(
                            padding: EdgeInsets.only(top: 4, bottom: 8),
                            child: TypingIndicator(),
                          );
                        }
                        return MessageBubble(
                          message: p.messages[i],
                          index:   i,
                        );
                      },
                    ),
            ),

            // Input bar
            _buildInputBar(p),
          ],
        ),
      );
    });
  }

  PreferredSizeWidget _buildAppBar(ChatProvider p) {
    return AppBar(
      backgroundColor: AppColors.surface,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_rounded,
            color: AppColors.textSecondary),
        onPressed: () => Navigator.pop(context),
      ),
      title: Row(children: [
        // Language emoji avatar
        Container(
          width: 38,
          height: 38,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [AppColors.primary, AppColors.secondary],
            ),
          ),
          child: Center(
            child: Text(p.selectedLanguage.flag,
                style: const TextStyle(fontSize: 20)),
          ),
        ),
        const SizedBox(width: 10),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(
            '${p.selectedLanguage.name} Tutor',
            style: GoogleFonts.spaceGrotesk(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w700),
          ),
          Row(children: [
            Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                  color: AppColors.secondary, shape: BoxShape.circle),
            ),
            const SizedBox(width: 5),
            Text('AI powered',
                style: GoogleFonts.inter(
                    color: AppColors.secondary, fontSize: 11)),
          ]),
        ]),
      ]),
      actions: [
        IconButton(
          icon: const Icon(Icons.info_outline_rounded,
              color: AppColors.textMuted),
          onPressed: () => _showInfo(p),
        ),
        const SizedBox(width: 4),
      ],
      bottom: const PreferredSize(
        preferredSize: Size.fromHeight(1),
        child: Divider(height: 1, color: AppColors.divider),
      ),
    );
  }

  Widget _buildEmpty(String lang) {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.surfaceVariant,
            border: Border.all(color: AppColors.divider),
          ),
          child: const Icon(Icons.chat_bubble_outline_rounded,
              color: AppColors.textMuted, size: 36),
        ),
        const SizedBox(height: 20),
        Text('Ready to learn $lang!',
            style: GoogleFonts.spaceGrotesk(
                color: AppColors.textSecondary,
                fontSize: 18,
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        Text('Type a message to begin your lesson',
            style: GoogleFonts.inter(
                color: AppColors.textMuted, fontSize: 14)),
      ]),
    );
  }

  Widget _buildInputBar(ChatProvider p) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(12, 10, 12, bottom > 0 ? 10 : 22),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
        // Text field
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: _focusNode.hasFocus
                    ? AppColors.primary.withOpacity(0.6)
                    : Colors.transparent,
                width: 1.5,
              ),
            ),
            child: TextField(
              controller:   _textCtrl,
              focusNode:    _focusNode,
              minLines:     1,
              maxLines:     5,
              textCapitalization: TextCapitalization.sentences,
              style: GoogleFonts.inter(
                  color: AppColors.textPrimary, fontSize: 15),
              decoration: InputDecoration(
                hintText: 'Ask your tutor anything...',
                hintStyle: GoogleFonts.inter(
                    color: AppColors.textMuted, fontSize: 15),
                border:         InputBorder.none,
                contentPadding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              ),
              onSubmitted: p.isLoading ? null : (_) => _send(),
            ),
          ),
        ),
        const SizedBox(width: 8),

        // Send button
        AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width:  48,
          height: 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: (_canSend && !p.isLoading)
                ? const LinearGradient(
                    colors: [AppColors.primary, AppColors.secondary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight)
                : null,
            color: (_canSend && !p.isLoading) ? null : AppColors.surfaceVariant,
            boxShadow: (_canSend && !p.isLoading)
                ? [BoxShadow(
                    color: AppColors.primary.withOpacity(0.4),
                    blurRadius: 12, spreadRadius: 1)]
                : null,
          ),
          child: Material(
            color: Colors.transparent,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: (_canSend && !p.isLoading) ? _send : null,
              child: Center(
                child: p.isLoading
                    ? const SizedBox(
                        width: 20, height: 20,
                        child: CircularProgressIndicator(
                            color: AppColors.textMuted, strokeWidth: 2))
                    : Icon(
                        Icons.send_rounded,
                        color: _canSend
                            ? Colors.white
                            : AppColors.textMuted,
                        size: 20),
              ),
            ),
          ),
        ),
      ]),
    );
  }

  void _showInfo(ChatProvider p) {
    showModalBottomSheet(
      context:           context,
      backgroundColor:   AppColors.cardBg,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 40, height: 4,
              decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 20),
          Text('Session Info',
              style: GoogleFonts.spaceGrotesk(
                  color: AppColors.textPrimary,
                  fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 20),
          _infoTile('Language',    p.selectedLanguage.name),
          _infoTile('Messages',    '${p.messages.length}'),
          _infoTile('Session ID',
              p.activeChatId?.substring(0, 12) ?? 'N/A'),
            _infoTile('AI Engine', 'Gemini API'),
          const SizedBox(height: 16),
        ]),
      ),
    );
  }

  Widget _infoTile(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(children: [
        Text(label,
            style: GoogleFonts.inter(
                color: AppColors.textSecondary, fontSize: 14)),
        const Spacer(),
        Text(value,
            style: GoogleFonts.inter(
                color: AppColors.textPrimary,
                fontSize: 14, fontWeight: FontWeight.w600)),
      ]),
    );
  }
}

// ── Error banner widget ────────────────────────────────────────────────────────
class _ErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback onDismiss;
  const _ErrorBanner({required this.message, required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin:  const EdgeInsets.fromLTRB(12, 8, 12, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.error.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.error.withOpacity(0.5)),
      ),
      child: Row(children: [
        const Icon(Icons.error_outline_rounded,
            color: AppColors.error, size: 18),
        const SizedBox(width: 10),
        Expanded(
          child: Text(message,
              style: GoogleFonts.inter(
                  color: AppColors.textPrimary, fontSize: 13)),
        ),
        GestureDetector(
          onTap: onDismiss,
          child: const Icon(Icons.close_rounded,
              color: AppColors.textMuted, size: 18),
        ),
      ]),
    );
  }
}