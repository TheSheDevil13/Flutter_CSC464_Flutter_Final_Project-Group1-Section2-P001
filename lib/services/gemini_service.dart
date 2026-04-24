import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class GeminiService {
  GeminiService._(); // prevent instantiation

  // Get the API key from the .env file
  static String get _apiKey => dotenv.env['GEMINI_API_KEY'] ?? '';

  // Use the 2.5 flash lite model for reliable, fast responses
  static const String _modelName = 'gemini-2.5-flash-lite';

  static Future<String> sendMessage({
    required String language,
    required List<Map<String, dynamic>> conversationHistory,
    required String userMessage,
  }) async {
    if (_apiKey.isEmpty || _apiKey == 'YOUR_GEMINI_API_KEY_HERE') {
      throw const GeminiException('Please add your Gemini API Key to the .env file');
    }

    try {
      // Initialize the model with our API key and system instructions
      final model = GenerativeModel(
        model: _modelName,
        apiKey: _apiKey,
        systemInstruction: Content.system(_buildSystemPrompt(language)),
      );

      // Convert our history format into Gemini's Content format
      final history = conversationHistory.map((msg) {
        final role = msg['role'] as String;
        final parts = msg['parts'] as List;
        final text = parts[0]['text'] as String;
        return Content(role, [TextPart(text)]);
      }).toList();

      // Start the chat and send the user's message
      final chat = model.startChat(history: history);
      final response = await chat.sendMessage(Content.text(userMessage));
      
      return response.text?.trim() ?? '';
    } catch (e) {
      if (e is GeminiException) rethrow;
      throw GeminiException('API Error: ${e.toString()}');
    }
  }

  // Instructs the AI how to act as a language tutor
  static String _buildSystemPrompt(String language) => '''
You are LinguaAI — a friendly and encouraging $language language tutor.

YOUR ROLE:
- Help learners practice $language through natural conversation.
- Correct grammar mistakes gently, explaining why.
- Teach vocabulary and phrases with English translations.
- Adapt to the learner's level.
- Keep responses concise (2-5 sentences).

RESPONSE FORMAT:
- If correcting: ✏️ Correction: [corrected version] — [reason]
- If teaching: 📚 [Phrase in $language] = "[English translation]"
- Answer clearly and end with a follow-up question.

IMPORTANT: Respond in English by default unless asked otherwise or giving examples.
''';
}

class GeminiException implements Exception {
  final String message;
  const GeminiException(this.message);
  @override
  String toString() => message;
}
