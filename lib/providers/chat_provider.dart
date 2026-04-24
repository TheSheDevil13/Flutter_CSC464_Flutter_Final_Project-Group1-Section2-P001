import 'package:flutter/foundation.dart';
import '../models/message_model.dart';
import '../models/chat_session_model.dart';
import '../models/language_data.dart';
import '../services/firestore_service.dart';
import '../services/gemini_service.dart'; 

// Tracks the current status of the AI response
enum AiState { idle, loading, error }

class ChatProvider extends ChangeNotifier {
  ChatProvider() {
    // Default to the first available language
    _selectedLanguage = kAvailableLanguages.first;
  }

  final _db = FirestoreService.instance;

  // Application state variables
  late LanguageData     _selectedLanguage;
  String?               _activeChatId;
  List<MessageModel>    _messages      = [];
  List<ChatSessionModel>_sessions      = [];
  AiState               _aiState       = AiState.idle;
  String                _errorMessage  = '';
  bool                  _sessionsLoaded = false;

  // Keep a local history to send to the Gemini API
  final List<Map<String, dynamic>> _history = [];
  static const int _maxHistory = 20;

  // Getters for the UI
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

  // Update the selected language
  void selectLanguage(LanguageData lang) {
    _selectedLanguage = lang;
    notifyListeners();
  }

  // Create a new chat session
  Future<bool> startNewChat() async {
    _resetChatState();
    notifyListeners();

    try {
      // Create a document in Firestore for the new chat
      _activeChatId = await _db.createChatSession(
        language:     _selectedLanguage.name,
        languageFlag: _selectedLanguage.flag,
      );

      // Get the initial greeting from the AI
      await _fetchAiGreeting();

      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to start chat: ${e.toString().replaceAll("Exception: ", "")}');
      return false;
    }
  }

  // Load a previous chat session from Firestore
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

  // Handle sending a message to the AI
  Future<void> sendMessage(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || _activeChatId == null) return;
    if (_aiState == AiState.loading) return;

    // Show the user's message in the UI immediately
    final userMsg = MessageModel.local(sender: 'user', message: trimmed);
    _messages.add(userMsg);
    _aiState      = AiState.loading;
    _errorMessage = '';
    notifyListeners();

    try {
      // Save the user's message to Firestore and local history
      await _db.saveMessage(
        chatId:  _activeChatId!,
        sender:  'user',
        message: trimmed,
      );
      _addToHistory('user', trimmed);

      // Call the Gemini API to get a response
      final aiText = await GeminiService.sendMessage(
        language:            _selectedLanguage.name,
        conversationHistory: List.from(_history),
        userMessage:         trimmed,
      );

      // Save the AI's response to Firestore and local history
      await _db.saveMessage(
        chatId:  _activeChatId!,
        sender:  'ai',
        message: aiText,
      );
      _messages.add(MessageModel.local(sender: 'ai', message: aiText));
      _addToHistory('model', aiText);

      _aiState = AiState.idle;
      notifyListeners();
    } catch (e) {
      _setError(e.toString().replaceAll('Exception: ', ''));
    }
  }

  // Fetch all past chat sessions
  Future<void> loadAllSessions() async {
    try {
      _sessions = await _db.fetchAllSessions();
      _sessionsLoaded = true;
      notifyListeners();
    } catch (e) {
      _setError('Failed to load history: ${e.toString().replaceAll("Exception: ", "")}');
    }
  }

  // Delete a specific chat session
  Future<void> deleteSession(String chatId) async {
    try {
      await _db.deleteChatSession(chatId);
      _sessions.removeWhere((s) => s.id == chatId);
      
      // If we deleted the active chat, reset the state
      if (_activeChatId == chatId) _resetChatState();
      
      notifyListeners();
    } catch (e) {
      _setError('Failed to delete: ${e.toString().replaceAll("Exception: ", "")}');
    }
  }

  void clearError() {
    if (_aiState == AiState.error) {
      _aiState = AiState.idle;
      notifyListeners();
    }
  }

  // Helper to fetch the initial AI greeting
  Future<void> _fetchAiGreeting() async {
    _aiState = AiState.loading;
    notifyListeners();

    try {
      final greeting = await GeminiService.sendMessage(
        language:            _selectedLanguage.name,
        conversationHistory: [],
        userMessage:
            'Hello! I want to start a ${_selectedLanguage.name} lesson. '
            'Please greet me warmly in ${_selectedLanguage.name} (with English translation), '
            'introduce yourself briefly, and ask what I would like to focus on today.',
      );

      // Save and show the greeting
      await _db.saveMessage(
        chatId:  _activeChatId!,
        sender:  'ai',
        message: greeting,
      );
      _messages.add(MessageModel.local(sender: 'ai', message: greeting));
      _addToHistory('model', greeting);
    } catch (_) {
      // Use a fallback greeting if the API fails
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

  // Add a message to the local history array
  void _addToHistory(String role, String text) {
    _history.add({
      'role':  role,
      'parts': [{'text': text}],
    });
    
    // Remove oldest messages if we exceed the limit
    if (_history.length > _maxHistory) {
      _history.removeRange(0, _history.length - _maxHistory);
    }
  }

  // Rebuild local history when loading a past session
  void _rebuildHistory(List<MessageModel> messages) {
    _history.clear();
    for (final m in messages) {
      _addToHistory(m.isUser ? 'user' : 'model', m.message);
    }
  }

  // Reset all state to defaults
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