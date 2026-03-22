import 'dart:convert';
import 'package:flutter/services.dart';

class PostService {
  Future<List<Map<String, dynamic>>> fetchPosts() async {
    try {
      final String response = await rootBundle.loadString('assets/posts.json');
      final data = await json.decode(response);
      if (data is List) {
        return List<Map<String, dynamic>>.from(data);
      }
      return [];
    } catch (e) {
      // Fallback or rethrow
      return [
        {
          "id": 1,
          "title": "Welcome to the App",
          "body": "This is a fallback post because the data file could not be loaded.",
          "imageUrl": "https://picsum.photos/800/400?random=1"
        }
      ];
    }
  }
}
