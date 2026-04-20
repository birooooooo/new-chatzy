import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/message_model.dart';

class AiService {
  static const String _apiKey = 'sk_c66f5c63a239c9301738ee77b9107a9d';
  static const String _model = 'mercury-2';
  static const String _baseUrl = 'https://api.inceptionlabs.ai/v1/chat/completions';

  static const List<String> _validMoods = [
    'happy', 'sad', 'thinking', 'waving', 'surprised', 'angry', 'sleeping', 'neutral'
  ];

  Map<String, String> get _headers => {
    'Authorization': 'Bearer $_apiKey',
    'Content-Type': 'application/json',
  };

  Future<String> _call(String prompt, {String? system, int maxTokens = 512}) async {
    final messages = <Map<String, String>>[];
    if (system != null) messages.add({'role': 'system', 'content': system});
    messages.add({'role': 'user', 'content': prompt});

    final response = await http.post(
      Uri.parse(_baseUrl),
      headers: _headers,
      body: jsonEncode({
        'model': _model,
        'max_tokens': maxTokens,
        'messages': messages,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['choices'][0]['message']['content'] as String? ?? '';
    }
    debugPrint('InceptionLabs API error ${response.statusCode}: ${response.body}');
    throw Exception('API error ${response.statusCode}');
  }

  /// Analyzes the text and returns one of the valid acting moods.
  Future<String> analyzeSentiment(String text) async {
    if (text.trim().isEmpty) return 'neutral';
    try {
      final result = await _call(
        'Classify the sentiment of the following chat message into exactly one of these categories:\n'
        'happy, sad, thinking, waving, surprised, angry, sleeping, neutral\n\n'
        'Message: "$text"\n\n'
        'Return ONLY the single category name in lowercase.',
      );
      return _parseMood(result.trim().toLowerCase());
    } catch (_) {
      return _parseMood(text.trim().toLowerCase());
    }
  }

  String _parseMood(String mood) {
    if (_validMoods.contains(mood)) return mood;
    if (mood.contains('happy') || mood.contains('good') || mood.contains('great')) return 'happy';
    if (mood.contains('sad') || mood.contains('bad')) return 'sad';
    if (mood.contains('think') || mood.contains('how')) return 'thinking';
    if (mood.contains('wav') || mood.contains('hi') || mood.contains('hello') || mood.contains('hey')) return 'waving';
    if (mood.contains('surpris') || mood.contains('shock') || mood.contains('wow')) return 'surprised';
    if (mood.contains('angr') || mood.contains('mad') || mood.contains('hate')) return 'angry';
    if (mood.contains('sleep') || mood.contains('tired') || mood.contains('bored')) return 'sleeping';
    return 'neutral';
  }

  /// Send any free-form prompt and get a raw text response.
  Future<String> freePrompt(String prompt) async {
    return await _call(prompt, maxTokens: 512);
  }

  /// Generates a response from the AI based on user input and provided context.
  Future<String> getChatResponse(String input, List<MessageModel> history, String contextHistory) async {
    try {
      final messages = <Map<String, String>>[
        {
          'role': 'system',
          'content': 'You are CHATZY AI, a helpful personal assistant. '
              'Context from user chats: $contextHistory '
              'Keep responses concise, friendly, and professional.',
        },
      ];
      for (final m in history.reversed) {
        messages.add({
          'role': m.senderId == 'me' ? 'user' : 'assistant',
          'content': m.content,
        });
      }
      messages.add({'role': 'user', 'content': input});

      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: _headers,
        body: jsonEncode({'model': _model, 'max_tokens': 1024, 'messages': messages}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'] as String? ??
            "I'm not sure how to respond to that.";
      }
      return "I'm having trouble connecting right now. Please try again.";
    } catch (e) {
      debugPrint('getChatResponse error: $e');
      return "I'm having trouble connecting right now. Please try again.";
    }
  }

  /// Summarizes a conversation list.
  Future<String> summarizeConversation(List<MessageModel> messages) async {
    if (messages.isEmpty) return "No messages to summarize.";
    final text = messages.reversed
        .map((m) => '${m.senderId == 'me' ? 'User' : 'Contact'}: ${m.content}')
        .join('\n');
    try {
      return await _call(
        'Summarize this chat into 3 bullet points. Be brief.\n\n$text',
        maxTokens: 256,
      );
    } catch (_) {
      return '• Could not summarize — AI unavailable.';
    }
  }
}
