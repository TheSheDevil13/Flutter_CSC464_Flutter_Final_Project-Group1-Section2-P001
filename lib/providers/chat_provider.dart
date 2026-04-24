// ─────────────────────────────────────────────────────────────────────────────
// FILE: lib/providers/chat_provider.dart
// Central ChangeNotifier. Single source of truth for all app state.
// ─────────────────────────────────────────────────────────────────────────────
import 'package:flutter/foundation.dart';
import '../models/message_model.dart';
import '../models/chat_session_model.dart';
import '../models/language_data.dart';
import '../services/firestore_service.dart';

// ── UPDATED SERVICE IMPORT ───────────────────────────────────────────────────
import '../services/groq_service.dart'; 
// ─────────────────────────────────────────────────────────────────────────────

/// Tracks the AI response lifecycle state.
enum AiState { idle, loading, error }

class ChatProvider extends ChangeNotifier {
  ChatProvider() {
    // Set default language to first in the list
    _selectedLanguage = kAvailableLanguages.first;
  }

  final _db = FirestoreService.instance;

  // ── State fields ──────────────────────────────────────────────────────────
  late LanguageData     _selectedLanguage;
  String?               _activeChatId;
  List<MessageModel>    _messages      = [];
  List<ChatSessionModel>_sessions      = [];
  AiState               _aiState       = AiState.idle;
  String                _errorMessage  = '';
  bool                  _sessionsLoaded = false;

  // Conversation history sent to AI on each request
  // Note: We keep the Gemini-style 'parts' structure here; 
  // GroqService handles the conversion internally.
  final List<Map<String, dynamic>> _history = [];
  static const int _maxHistory = 20; // max message pairs kept

  // ── Public getters ─────────────────────────────────────────────────────────
  LanguageData          get selectedLanguage  => _selectedLanguage;
  String?               get activeChatId      => _activeChatId;
  List<MessageModel>    get messages          => List.unmodifiable(_messages);
  List<ChatSessionModel>get sessions          => List.unmodifiable(_sessions);
  AiState               get aiState           => _aiState;
  String                get errorMessage      => _errorMessage;
  bool                  get isLoading         => _aiState == AiState.loading;
  bool                  get hasError          => _aiState == AiState.error;
  bool                  get hasActiveChat     => _activeChatId != null;
  bool                  get sessionsLoaded    => _sessionsLoaded;

  // ── Language selection ─────────────────────────────────────────────────────

  void selectLanguage(LanguageData lang) {
    _selectedLanguage = lang;
    notifyListeners();
  }

  // ── Start a brand-new chat session ────────────────────────────────────────

  Future<bool> startNewChat() async {
    _resetChatState();
    notifyListeners();

    try {
      // 1. Create session document in Firestore
      _activeChatId = await _db.createChatSession(
        language:     _selectedLanguage.name,
        languageFlag: _selectedLanguage.flag,
      );

      // 2. Fetch and display the AI greeting from Groq
      await _fetchAiGreeting();

      notifyListeners();
      return true; // success — caller can navigate to /chat
    } catch (e) {
      _setError('Failed to start chat: ${e.toString().replaceAll("Exception: ", "")}');
      return false;
    }
  }

  // ── Load an existing session from history ──────────────────────────────────

  Future<bool> loadSession(ChatSessionModel session) async {
    _resetChatState();
    _activeChatId      = session.id;
    _selectedLanguage  = findLanguage(session.language) ?? kAvailableLanguages.first;
    notifyListeners();

    try {
      _messages = await _db.fetchMessages(session.id);
      _rebuildHistory(_messages);
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to load session: ${e.toString().replaceAll("Exception: ", "")}');
      return false;
    }
  }

  // ── Send a message ─────────────────────────────────────────────────────────

  Future<void> sendMessage(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || _activeChatId == null) return;
    if (_aiState == AiState.loading) return;

    // ① Optimistic UI: show user message immediately
    final userMsg = MessageModel.local(sender: 'user', message: trimmed);
    _messages.add(userMsg);
    _aiState      = AiState.loading;
    _errorMessage = '';
    notifyListeners();

    try {
      // ② Save user message to Firestore
      await _db.saveMessage(
        chatId:  _activeChatId!,
        sender:  'user',
        message: trimmed,
      );

      // ③ Add to local history for context
      _addToHistory('user', trimmed);

      // ④ CALL GROQ SERVICE
      final aiText = await GroqService.sendMessage(
        language:            _selectedLanguage.name,
        conversationHistory: List.from(_history),
        userMessage:         trimmed,
      );

      // ⑤ Save AI response to Firestore
      await _db.saveMessage(
        chatId:  _activeChatId!,
        sender:  'ai',
        message: aiText,
      );

      // ⑥ Show AI response in UI
      _messages.add(MessageModel.local(sender: 'ai', message: aiText));
      _addToHistory('model', aiText);

      _aiState = AiState.idle;
      notifyListeners();
    } catch (e) {
      _setError(e.toString().replaceAll('Exception: ', ''));
    }
  }

  // ── Session history management ─────────────────────────────────────────────

  Future<void> loadAllSessions() async {
    try {
      _sessions = await _db.fetchAllSessions();
      _sessionsLoaded = true;
      notifyListeners();
    } catch (e) {
      _setError('Failed to load history: ${e.toString().replaceAll("Exception: ", "")}');
    }
  }

  Future<void> deleteSession(String chatId) async {
    try {
      await _db.deleteChatSession(chatId);
      _sessions.removeWhere((s) => s.id == chatId);
      if (_activeChatId == chatId) _resetChatState();
      notifyListeners();
    } catch (e) {
      _setError('Failed to delete: ${e.toString().replaceAll("Exception: ", "")}');
    }
  }

  // ── Error management ───────────────────────────────────────────────────────

  void clearError() {
    if (_aiState == AiState.error) {
      _aiState = AiState.idle;
      notifyListeners();
    }
  }

  // ── Private helpers ────────────────────────────────────────────────────────

  Future<void> _fetchAiGreeting() async {
    _aiState = AiState.loading;
    notifyListeners();

    try {
      // ── CALL GROQ SERVICE FOR GREETING ─────────────────────────────────────
      final greeting = await GroqService.sendMessage(
        language:            _selectedLanguage.name,
        conversationHistory: [],
        userMessage:
            'Hello! I want to start a ${_selectedLanguage.name} lesson. '
            'Please greet me warmly in ${_selectedLanguage.name} (with English translation), '
            'introduce yourself briefly, and ask what I would like to focus on today.',
      );

      await _db.saveMessage(
        chatId:  _activeChatId!,
        sender:  'ai',
        message: greeting,
      );
      _messages.add(MessageModel.local(sender: 'ai', message: greeting));
      _addToHistory('model', greeting);
    } catch (_) {
      // Fallback greeting if the API fails
      const fallback =
          'Hello! 👋 Welcome to your language lesson! I\'m your AI tutor and I\'m excited to help you learn.\n\n'
          'What would you like to focus on today?\n'
          '• Basic vocabulary\n'
          '• Conversation practice\n'
          '• Grammar rules\n'
          '• Something else?';
      await _db.saveMessage(
          chatId: _activeChatId!, sender: 'ai', message: fallback);
      _messages.add(MessageModel.local(sender: 'ai', message: fallback));
    }
    _aiState = AiState.idle;
  }

  void _addToHistory(String role, String text) {
    _history.add({
      'role':  role,
      'parts': [{'text': text}],
    });
    // Keep history bounded
    if (_history.length > _maxHistory) {
      _history.removeRange(0, _history.length - _maxHistory);
    }
  }

  void _rebuildHistory(List<MessageModel> messages) {
    _history.clear();
    for (final m in messages) {
      _addToHistory(m.isUser ? 'user' : 'model', m.message);
    }
  }

  void _resetChatState() {
    _activeChatId = null;
    _messages.clear();
    _history.clear();
    _aiState      = AiState.idle;
    _errorMessage = '';
  }

  void _setError(String msg) {
    _aiState      = AiState.error;
    _errorMessage = msg;
    notifyListeners();
  }
}