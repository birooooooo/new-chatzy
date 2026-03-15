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

  // List of models to try in order
  static const List<String> _modelNames = [
    'gemini-1.5-flash',
    'gemini-1.5-pro',
    'gemini-pro',
  ];

  AiService(); // No init here, we init on demand or try models in the method

  /// Analyzes the text and returns one of the valid acting moods.
  Future<String> analyzeSentiment(String text) async {
    if (_apiKey == 'YOUR_API_KEY_HERE') {
      print('Warning: API Key not set in AiService');
      return 'neutral';
    }

    if (text.trim().isEmpty) return 'neutral';

    for (final modelName in _modelNames) {
      try {
        final model = GenerativeModel(model: modelName, apiKey: _apiKey);
        final prompt = '''
        Classify the sentiment of the following chat message into exactly one of these categories:
        - happy (joy, excitement, success, laughter)
        - sad (bad news, disappointment, empathy, crying)
        - thinking (questions, confusion, ideas, planning)
        - waving (greetings, goodbyes, hi, hello, bye)
        - surprised (shock, wow, amazing, disbelief)
        - angry (mad, hate, frustration, annoyance)
        - sleeping (tired, goodnight, bored, sleep)
        - neutral (default, statements, facts)

        Message: "$text"

        Return ONLY the category name (lowercase).
      ''';

        final content = [Content.text(prompt)];
        final response = await model.generateContent(content);
        
        // If we get here, the model worked!
        final mood = response.text?.trim().toLowerCase() ?? 'neutral';
        return _parseMood(mood);

      } catch (e) {
        print('AI Service Error (Model $modelName): $e');
        // Continue to next model if this one failed
        continue;
      }
    }
    
    // If all failed, fallback to keyword matching on the raw text
    print('Falling back to keyword matching for animation testing.');
    return _parseMood(text.trim().toLowerCase());
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
    if (_apiKey.isEmpty || _apiKey.startsWith('YOUR_API_KEY')) {
      return "I'm sorry, but my API key is not configured. Please set the API key in `ai_service.dart`.";
    }

    String lastError = "Unknown error";
    
    for (final modelName in _modelNames) {
      try {
        // Build the system instructions
        final systemPrompt = '''
        You are CHATZY AI, a helpful and intelligent personal assistant.
        Your goal is to assist the user with their daily life problems, work, and social interactions.
        
        IMPORTANT CONTEXT:
        The following is a summary of the user's recent conversations with their friends and colleagues in this app. 
        Use this context to provide personalized advice, summarize discussions, or help with follow-ups.
        
        $contextHistory
        
        When the user asks about a specific person or topic mentioned in these chats, use the information provided above.
        If the information is not in the context, be honest but remain helpful.
        
        Keep your responses concise, friendly, and professional.
        ''';

        // Use systemInstruction for consistent behavior across all turns
        final model = GenerativeModel(
          model: modelName, 
          apiKey: _apiKey,
          systemInstruction: Content.system(systemPrompt),
        );
        
        // Convert history to Content format
        final contents = history.reversed.map((m) {
          final role = m.senderId == 'me' ? 'user' : 'model';
          return Content(role, [TextPart(m.content)]);
        }).toList();

        // Add the current input
        contents.add(Content('user', [TextPart(input)]));

        final response = await model.generateContent(contents);
        return response.text ?? "I'm not sure how to respond to that.";

      } catch (e) {
        lastError = e.toString();
        print('AI Chat Error (Model $modelName): $e');
        continue;
      }
    }

    return "I'm having trouble connecting to my brain right now.\n\nDetails: $lastError";
  }

  /// Summarizes a conversation list.
  Future<String> summarizeConversation(List<MessageModel> messages) async {
    if (_apiKey.isEmpty || _apiKey.startsWith('YOUR_API_KEY') || _apiKey == 'AIzaSyB0g0EK_gv0J_b2IUL7Z7vpgLt903pYHs0') {
      // Mock summary if key is placeholder
       await Future.delayed(const Duration(seconds: 1));
       return "• Discussion about project deadlines.\n• Agreed to meet on Friday at 10 AM.\n• Need to finalize the UI designs by tomorrow.";
    }

    if (messages.isEmpty) return "No messages to summarize.";

    final conversationText = messages.reversed.map((m) => "${m.senderId == 'me' ? 'User' : 'Contact'}: ${m.content}").join('\n');

    for (final modelName in _modelNames) {
      try {
        final model = GenerativeModel(model: modelName, apiKey: _apiKey);
        final prompt = '''
        Summarize the following chat conversation into a few bullet points. 
        Focus on the main topics discussed and any pending actions or questions.
        Keep it brief and professional.

        Chat History:
        $conversationText
        ''';

        final content = [Content.text(prompt)];
        final response = await model.generateContent(content);
        return response.text ?? "Could not generate summary.";
      } catch (e) {
        print('AI Summary Error (Model $modelName): $e');
        continue;
      }
    }

    return "Failed to connect to AI for summarization.";
  }
}
