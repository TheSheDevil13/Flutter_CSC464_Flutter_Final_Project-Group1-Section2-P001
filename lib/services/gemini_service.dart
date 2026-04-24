// ─────────────────────────────────────────────────────────────────────────────
// FILE: lib/services/gemini_service.dart
// Handles all communication with the Gemini API.
// ─────────────────────────────────────────────────────────────────────────────
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class GeminiService {
  GeminiService._(); // prevent instantiation

  // ══════════════════════════════════════════════════════════════════════════
  // YOUR GEMINI API KEY GOES HERE 👇
  // ══════════════════════════════════════════════════════════════════════════
  static String get _apiKey => dotenv.env['GEMINI_API_KEY'] ?? '';
  // ══════════════════════════════════════════════════════════════════════════

  static const String _modelName = 'gemini-1.5-flash';

  static Future<String> sendMessage({
    required String language,
    required List<Map<String, dynamic>> conversationHistory,
    required String userMessage,
  }) async {
    if (_apiKey.isEmpty || _apiKey == 'YOUR_GEMINI_API_KEY_HERE') {
      throw const GeminiException('Please add your Gemini API Key in lib/services/gemini_service.dart');
    }

    try {
      final model = GenerativeModel(
        model: _modelName,
        apiKey: _apiKey,
        systemInstruction: Content.system(_buildSystemPrompt(language)),
      );

      // Convert history to Gemini Content objects
      final history = conversationHistory.map((msg) {
        final role = msg['role'] as String;
        final parts = msg['parts'] as List;
        final text = parts[0]['text'] as String;
        return Content(role, [TextPart(text)]);
      }).toList();

      final chat = model.startChat(history: history);
      
      final response = await chat.sendMessage(Content.text(userMessage));
      
      return response.text?.trim() ?? '';
    } catch (e) {
      if (e is GeminiException) rethrow;
      throw GeminiException('API Error: ${e.toString()}');
    }
  }

  static String _buildSystemPrompt(String language) => '''
You are LinguaAI — a world-class, friendly, and encouraging $language language tutor.

YOUR ROLE:
- Help learners practice and improve their $language through natural conversation.
- Correct grammar mistakes gently: show the corrected version, then briefly explain why.
- Teach vocabulary and phrases in context; always provide the $language text and English translation.
- Share cultural tips and interesting facts about countries where $language is spoken.
- Adapt to the learner's level — be simpler for beginners, more advanced for fluent speakers.
- Keep responses concise (2–5 sentences) unless a longer explanation is needed.
- Use occasional emojis to keep the tone warm 🎓.

RESPONSE FORMAT:
- If correcting: ✏️ Correction: [corrected version] — [reason]
- If teaching: 📚 [Phrase in $language] = "[English translation]"
- If answering: Direct, clear answer with an example.
- End with a gentle follow-up question to keep the conversation going.

IMPORTANT: Respond in English by default. Only switch to $language if the user explicitly asks to practice or if it's part of a translation example.
''';
}

class GeminiException implements Exception {
  final String message;
  const GeminiException(this.message);
  @override
  String toString() => message;
}
