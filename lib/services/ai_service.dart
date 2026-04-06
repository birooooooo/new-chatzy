import 'package:google_generative_ai/google_generative_ai.dart';
import '../models/message_model.dart';

class AiService {
  // ==========================================================
  // REPLACE THE KEY BELOW WITH YOUR OWN GEMINI API KEY
  // ==========================================================
  static const String _apiKey = 'AIzaSyCcu3AuO1VSEdu75G4sLz3LgUVmwirtPis';
  // ==========================================================

  late final GenerativeModel _model;
  
  // Mapping of fallback logic if AI fails or returns something unexpected
  static const List<String> _validMoods = [
    'happy', 
    'sad', 
    'thinking', 
    'waving', 
    'surprised', 
    'angry', 
    'sleeping',
    'neutral'
  ];

  static const String _primaryModel = 'gemini-2.0-flash';

  AiService(); // No init here, we init on demand or try models in the method

  /// Analyzes the text and returns one of the valid acting moods.
  Future<String> analyzeSentiment(String text) async {
    if (text.trim().isEmpty) return 'neutral';

    try {
      final model = GenerativeModel(model: _primaryModel, apiKey: _apiKey);
      final prompt = '''
Classify the sentiment of the following chat message into exactly one of these categories:
happy, sad, thinking, waving, surprised, angry, sleeping, neutral

Message: "$text"

Return ONLY the single category name in lowercase.''';
      final response = await model.generateContent([Content.text(prompt)]);
      return _parseMood(response.text?.trim().toLowerCase() ?? 'neutral');
    } catch (e) {
      // Silently fall back to keyword matching
      return _parseMood(text.trim().toLowerCase());
    }
  }

  String _parseMood(String mood) {
    if (_validMoods.contains(mood)) {
      return mood;
    }
    // Fallback: simple string matching if AI returns something weird or if we are bypassing the AI
      if (mood.contains('happy') || mood.contains('good') || mood.contains('great')) return 'happy';
      if (mood.contains('sad') || mood.contains('bad')) return 'sad';
      if (mood.contains('think') || mood.contains('how')) return 'thinking';
      if (mood.contains('wav') || mood.contains('hi') || mood.contains('hello') || mood.contains('hey')) return 'waving';
      if (mood.contains('surpris') || mood.contains('shock') || mood.contains('wow')) return 'surprised';
      if (mood.contains('angr') || mood.contains('mad') || mood.contains('hate')) return 'angry';
      if (mood.contains('sleep') || mood.contains('tired') || mood.contains('bored')) return 'sleeping';

      return 'neutral';
  }

  /// Generates a response from the AI based on user input and provided context.
  Future<String> getChatResponse(String input, List<MessageModel> history, String contextHistory) async {
    try {
      final model = GenerativeModel(
        model: _primaryModel,
        apiKey: _apiKey,
        systemInstruction: Content.system(
          'You are CHATZY AI, a helpful personal assistant. '
          'Context from user chats: $contextHistory '
          'Keep responses concise, friendly, and professional.',
        ),
      );

      final contents = history.reversed.map((m) {
        return Content(m.senderId == 'me' ? 'user' : 'model', [TextPart(m.content)]);
      }).toList();
      contents.add(Content('user', [TextPart(input)]));

      final response = await model.generateContent(contents);
      return response.text ?? "I'm not sure how to respond to that.";
    } catch (e) {
      return "I'm having trouble connecting right now. Please try again.";
    }
  }

  /// Summarizes a conversation list.
  Future<String> summarizeConversation(List<MessageModel> messages) async {
    if (messages.isEmpty) return "No messages to summarize.";

    final conversationText = messages.reversed
        .map((m) => '${m.senderId == 'me' ? 'User' : 'Contact'}: ${m.content}')
        .join('\n');

    try {
      final model = GenerativeModel(model: _primaryModel, apiKey: _apiKey);
      final response = await model.generateContent([
        Content.text(
          'Summarize this chat into 3 bullet points. Be brief.\n\n$conversationText',
        ),
      ]);
      return response.text ?? "Could not generate summary.";
    } catch (e) {
      return "• Could not summarize — AI unavailable.";
    }
  }
}
