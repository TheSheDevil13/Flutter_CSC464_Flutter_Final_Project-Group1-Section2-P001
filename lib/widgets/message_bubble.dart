// ─────────────────────────────────────────────────────────────────────────────
// FILE: lib/widgets/message_bubble.dart
// Renders a single chat message with entrance animation.
// User messages: purple gradient, right-aligned.
// AI messages:    dark card with teal border, left-aligned.
// ─────────────────────────────────────────────────────────────────────────────
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/message_model.dart';
import '../theme/app_theme.dart';

class MessageBubble extends StatefulWidget {
  final MessageModel message;
  final int index;

  const MessageBubble({super.key, required this.message, required this.index});

  @override
  State<MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<MessageBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double>   _fade;
  late final Animation<Offset>   _slide;

  bool get _isUser => widget.message.isUser;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 380));
    _fade  = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut)
        .drive(Tween(begin: 0.0, end: 1.0));
    _slide = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut)
        .drive(Tween(
          begin: Offset(_isUser ? 0.25 : -0.25, 0),
          end:   Offset.zero,
        ));

    // Stagger but cap at index 6 so later messages don't delay too long
    final delay = Duration(milliseconds: (widget.index.clamp(0, 6)) * 45);
    Future.delayed(delay, () { if (mounted) _ctrl.forward(); });
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Column(
            crossAxisAlignment: _isUser
                ? CrossAxisAlignment.end
                : CrossAxisAlignment.start,
            children: [
              // Sender label
              _label(),
              const SizedBox(height: 4),

              // Bubble row
              Row(
                mainAxisAlignment: _isUser
                    ? MainAxisAlignment.end
                    : MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (!_isUser) _aiAvatar(),
                  if (!_isUser) const SizedBox(width: 8),
                  _bubble(context),
                  if (_isUser) const SizedBox(width: 8),
                ],
              ),

              // Timestamp
              const SizedBox(height: 3),
              Padding(
                padding: EdgeInsets.only(
                  left:  _isUser ? 0 : 40,
                  right: _isUser ? 4 : 0,
                ),
                child: Text(
                  DateFormat('h:mm a').format(widget.message.timestamp),
                  style: GoogleFonts.inter(
                      color: AppColors.textMuted, fontSize: 10),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label() {
    return Padding(
      padding: EdgeInsets.only(
        left:  _isUser ? 0 : 40,
        right: _isUser ? 4 : 0,
      ),
      child: Row(
        mainAxisAlignment:
            _isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!_isUser)
            const Icon(Icons.auto_awesome_rounded,
                size: 11, color: AppColors.secondary),
          if (!_isUser) const SizedBox(width: 4),
          Text(
            _isUser ? 'You' : 'AI Tutor',
            style: GoogleFonts.inter(
              color: _isUser ? AppColors.primary : AppColors.secondary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _aiAvatar() {
    return Container(
      width: 28,
      height: 28,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [AppColors.secondary, AppColors.primary],
        ),
      ),
      child: const Icon(Icons.psychology_rounded,
          color: Colors.white, size: 14),
    );
  }

  Widget _bubble(BuildContext context) {
    return GestureDetector(
      onLongPress: () {
        Clipboard.setData(ClipboardData(text: widget.message.message));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Copied to clipboard'),
            duration: Duration(seconds: 1),
          ),
        );
      },
      child: Container(
        constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.74),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          gradient: _isUser
              ? const LinearGradient(
                  colors: [AppColors.primary, Color(0xFF8B83FF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: _isUser ? null : AppColors.surfaceVariant,
          borderRadius: BorderRadius.only(
            topLeft:      const Radius.circular(18),
            topRight:     const Radius.circular(18),
            bottomLeft:  Radius.circular(_isUser ? 18 : 4),
            bottomRight: Radius.circular(_isUser ? 4 : 18),
          ),
          border: _isUser
              ? null
              : Border.all(
                  color: AppColors.secondary.withOpacity(0.18), width: 1),
          boxShadow: [
            BoxShadow(
              color: (_isUser ? AppColors.primary : AppColors.secondary)
                  .withOpacity(0.12),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Text(
          widget.message.message,
          style: GoogleFonts.inter(
              color: Colors.white, fontSize: 15, height: 1.55),
        ),
      ),
    );
  }
}