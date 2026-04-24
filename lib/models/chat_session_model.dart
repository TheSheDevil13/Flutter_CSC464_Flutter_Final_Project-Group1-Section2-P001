// ─────────────────────────────────────────────────────────────────────────────
// FILE: lib/models/chat_session_model.dart
// Data class representing one chat session document in /chats/{chatId}.
// ─────────────────────────────────────────────────────────────────────────────
import 'package:cloud_firestore/cloud_firestore.dart';

class ChatSessionModel {
  final String   id;
  final String   language;
  final String   languageFlag;
  final DateTime createdAt;
  final String   lastMessage;
  final int      messageCount;

  const ChatSessionModel({
    required this.id,
    required this.language,
    required this.languageFlag,
    required this.createdAt,
    this.lastMessage  = '',
    this.messageCount = 0,
  });

  // ── Firestore serialization ────────────────────────────────────────────────

  Map<String, dynamic> toFirestoreMap() {
    return {
      'language':     language,
      'languageFlag': languageFlag,
      'createdAt':    FieldValue.serverTimestamp(),
      'lastMessage':  lastMessage,
      'messageCount': messageCount,
    };
  }

  factory ChatSessionModel.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return ChatSessionModel(
      id:           doc.id,
      language:     data['language']     as String? ?? 'Spanish',
      languageFlag: data['languageFlag'] as String? ?? '🇪🇸',
      createdAt:    (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastMessage:  data['lastMessage']  as String? ?? '',
      messageCount: data['messageCount'] as int?    ?? 0,
    );
  }

  ChatSessionModel copyWith({
    String?   lastMessage,
    int?      messageCount,
  }) {
    return ChatSessionModel(
      id:           id,
      language:     language,
      languageFlag: languageFlag,
      createdAt:    createdAt,
      lastMessage:  lastMessage  ?? this.lastMessage,
      messageCount: messageCount ?? this.messageCount,
    );
  }

  @override
  String toString() =>
      'ChatSessionModel(id: $id, lang: $language, msgs: $messageCount)';
}