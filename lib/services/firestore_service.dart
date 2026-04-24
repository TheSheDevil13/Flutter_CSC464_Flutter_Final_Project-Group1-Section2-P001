// ─────────────────────────────────────────────────────────────────────────────
// FILE: lib/services/firestore_service.dart
// All Firestore CRUD operations. This is the ONLY file that touches Firestore.
//
// Firestore Schema:
//   /chats/{chatId}                     ← Chat session document
//     language:     string
//     languageFlag: string
//     createdAt:    timestamp
//     lastMessage:  string
//     messageCount: number
//     /messages/{messageId}             ← Sub-collection (unlimited messages)
//       sender:    "user" | "ai"
//       message:   string
//       timestamp: timestamp
// ─────────────────────────────────────────────────────────────────────────────
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/message_model.dart';
import '../models/chat_session_model.dart';

class FirestoreService {
  FirestoreService._();
  static final FirestoreService instance = FirestoreService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ── Collection references ──────────────────────────────────────────────────

  CollectionReference<Map<String, dynamic>> get _chats =>
      _db.collection('chats');

  CollectionReference<Map<String, dynamic>> _messages(String chatId) =>
      _chats.doc(chatId).collection('messages');

  // ══════════════════════════════════════════════════════════════════════════
  // CHAT SESSION OPERATIONS
  // ══════════════════════════════════════════════════════════════════════════

  /// Creates a new /chats/{chatId} document and returns the new ID.
  Future<String> createChatSession({
    required String language,
    required String languageFlag,
  }) async {
    try {
      final ref = await _chats.add({
        'language':     language,
        'languageFlag': languageFlag,
        'createdAt':    FieldValue.serverTimestamp(),
        'lastMessage':  '',
        'messageCount': 0,
      });
      return ref.id;
    } on FirebaseException catch (e) {
      throw _wrap(e, 'create chat session');
    }
  }

  /// Fetches all sessions, newest first.
  Future<List<ChatSessionModel>> fetchAllSessions() async {
    try {
      final snap = await _chats
          .orderBy('createdAt', descending: true)
          .get();
      return snap.docs
          .map((d) => ChatSessionModel.fromFirestore(d))
          .toList();
    } on FirebaseException catch (e) {
      throw _wrap(e, 'fetch sessions');
    }
  }

  /// Real-time stream of all sessions — used by HistoryScreen.
  Stream<List<ChatSessionModel>> watchAllSessions() {
    return _chats
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => ChatSessionModel.fromFirestore(d)).toList());
  }

  /// Deletes a session AND all its messages (Firestore does NOT cascade).
  Future<void> deleteChatSession(String chatId) async {
    try {
      // 1. Fetch all message document references
      final msgSnap = await _messages(chatId).get();

      // 2. Use a batch to delete everything atomically
      final batch = _db.batch();
      for (final doc in msgSnap.docs) {
        batch.delete(doc.reference);
      }
      batch.delete(_chats.doc(chatId));

      await batch.commit();
    } on FirebaseException catch (e) {
      throw _wrap(e, 'delete chat session');
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // MESSAGE OPERATIONS
  // ══════════════════════════════════════════════════════════════════════════

  /// Saves one message and atomically updates the parent session metadata.
  ///
  /// Returns the new message document ID.
  Future<String> saveMessage({
    required String chatId,
    required String sender,
    required String message,
  }) async {
    try {
      final batch   = _db.batch();
      final msgRef  = _messages(chatId).doc(); // auto ID
      final chatRef = _chats.doc(chatId);

      // Write the message
      batch.set(msgRef, {
        'sender':    sender,
        'message':   message,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Update parent session metadata
      final preview = message.length > 80
          ? '${message.substring(0, 80)}...'
          : message;
      batch.update(chatRef, {
        'lastMessage':  preview,
        'messageCount': FieldValue.increment(1),
      });

      await batch.commit();
      return msgRef.id;
    } on FirebaseException catch (e) {
      throw _wrap(e, 'save message');
    }
  }

  /// Fetches all messages for a session in chronological order.
  Future<List<MessageModel>> fetchMessages(String chatId) async {
    try {
      final snap = await _messages(chatId)
          .orderBy('timestamp', descending: false)
          .get();
      return snap.docs
          .map((d) => MessageModel.fromFirestore(d))
          .toList();
    } on FirebaseException catch (e) {
      throw _wrap(e, 'fetch messages');
    }
  }

  /// Real-time stream of messages — used for live chat updates.
  Stream<List<MessageModel>> watchMessages(String chatId) {
    return _messages(chatId)
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => MessageModel.fromFirestore(d)).toList());
  }

  // ── Error helper ───────────────────────────────────────────────────────────
  Exception _wrap(FirebaseException e, String operation) {
    return Exception('Firestore error during $operation: ${e.message}');
  }
}