import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class GroqService {
  GroqService._();

  // Get the API key from the .env file
  static String get _apiKey => dotenv.env['GROQ_API_KEY'] ?? '';

  // Use the LLaMA 3.3 70B model
  static const String _modelName = 'llama-3.3-70b-versatile';

  static Future<String> sendMessage({
    required String language,
    required List<Map<String, dynamic>> conversationHistory,
    required String userMessage,
  }) async {
    if (_apiKey.isEmpty || _apiKey == 'YOUR_GROQ_API_KEY_HERE') {
      throw const GroqException('Please add your Groq API Key to the .env file');
    }

    final url = Uri.parse('https://api.groq.com/openai/v1/chat/completions');
    
    // Build the messages list for the API request
    final List<Map<String, String>> messages = [];
    
    // Add the system prompt first
    messages.add({
      'role': 'system',
      'content': _buildSystemPrompt(language),
    });

    // Add all previous conversation history
    for (final msg in conversationHistory) {
      messages.add({
        'role': msg['role'] == 'model' || msg['role'] == 'assistant' ? 'assistant' : 'user',
        'content': msg['content'] as String,
      });
    }

    // Add the user's new message
    messages.add({
      'role': 'user',
      'content': userMessage,
    });

    try {
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': _modelName,
          'messages': messages,
          'temperature': 0.7,
        }),
      );

      if (response.statusCode == 200) {
        // Parse the successful response
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        return data['choices'][0]['message']['content'].toString().trim();
      } else {
        // Handle API errors
        final error = jsonDecode(response.body);
        throw GroqException(error['error']?['message'] ?? 'Unknown API error (${response.statusCode})');
      }
    } catch (e) {
      if (e is GroqException) rethrow;
      throw GroqException('Network Error: ${e.toString()}');
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

class GroqException implements Exception {
  final String message;
  const GroqException(this.message);
  @override
  String toString() => message;
}
