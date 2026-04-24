// ─────────────────────────────────────────────────────────────────────────────
// FILE: lib/models/message_model.dart
// Data class representing a single chat message stored in Firestore.
// ─────────────────────────────────────────────────────────────────────────────
import 'package:cloud_firestore/cloud_firestore.dart';

/// Possible senders of a message in the chat.
enum MessageSender { user, ai }

class MessageModel {
  final String id;
  final String sender;   // "user" or "ai"
  final String message;
  final DateTime timestamp;

  const MessageModel({
    required this.id,
    required this.sender,
    required this.message,
    required this.timestamp,
  });

  // ── Convenience getters ────────────────────────────────────────────────────
  bool get isUser => sender == 'user';
  bool get isAI   => sender == 'ai';

  // ── Firestore serialization ────────────────────────────────────────────────

  /// Converts to a Map suitable for Firestore write operations.
  Map<String, dynamic> toFirestoreMap() {
    return {
      'sender':    sender,
      'message':   message,
      'timestamp': FieldValue.serverTimestamp(), // always use server time
    };
  }

  /// Deserializes from a Firestore DocumentSnapshot.
  factory MessageModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return MessageModel(
      id:        doc.id,
      sender:    data['sender']    as String? ?? 'user',
      message:   data['message']   as String? ?? '',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Used for optimistic local updates before Firestore confirms the write.
  factory MessageModel.local({
    required String sender,
    required String message,
  }) {
    return MessageModel(
      id:        DateTime.now().microsecondsSinceEpoch.toString(),
      sender:    sender,
      message:   message,
      timestamp: DateTime.now(),
    );
  }

  @override
  String toString() =>
      'MessageModel(id: $id, sender: $sender, msg: ${message.substring(0, message.length.clamp(0, 30))}...)';
}