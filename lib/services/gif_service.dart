import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class GifResult {
  final String id;
  final String previewUrl;  // tinygif — small animated thumbnail for grid
  final String originalUrl; // full gif — sent in chat
  final String title;

  const GifResult({
    required this.id,
    required this.previewUrl,
    required this.originalUrl,
    required this.title,
  });
}

class GifService {
  // Tenor v1 public demo key — works without registration
  // Replace with your own key from tenor.com/developer for production
  static const _apiKey = 'LIVDSRZULELA';
  static const _base = 'https://api.tenor.com/v1';

  Future<List<GifResult>> fetchTrending({int limit = 24}) async {
    final uri = Uri.parse(
      '$_base/trending?key=$_apiKey&limit=$limit&media_filter=minimal&contentfilter=medium',
    );
    return _fetch(uri);
  }

  Future<List<GifResult>> search(String query, {int limit = 24}) async {
    if (query.trim().isEmpty) return fetchTrending(limit: limit);
    final uri = Uri.parse(
      '$_base/search?key=$_apiKey&q=${Uri.encodeComponent(query.trim())}'
      '&limit=$limit&media_filter=minimal&contentfilter=medium',
    );
    return _fetch(uri);
  }

  Future<List<GifResult>> _fetch(Uri uri) async {
    try {
      debugPrint('[GifService] GET $uri');
      final response = await http.get(
        uri,
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      debugPrint('[GifService] status=${response.statusCode}');

      if (response.statusCode != 200) {
        debugPrint('[GifService] Error body: ${response.body}');
        return [];
      }

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final results = body['results'] as List<dynamic>? ?? [];

      debugPrint('[GifService] Got ${results.length} results');

      final gifs = <GifResult>[];
      for (final item in results) {
        final mediaList = item['media'] as List<dynamic>?;
        if (mediaList == null || mediaList.isEmpty) continue;
        final media = mediaList[0] as Map<String, dynamic>;

        // tinygif = small animated, good for thumbnails
        final tiny = media['tinygif'] as Map<String, dynamic>?;
        // gif = full quality
        final full = media['gif'] as Map<String, dynamic>?
            ?? media['mediumgif'] as Map<String, dynamic>?
            ?? tiny;

        final previewUrl = tiny?['url'] as String? ?? '';
        final originalUrl = full?['url'] as String? ?? previewUrl;

        if (previewUrl.isEmpty) continue;

        gifs.add(GifResult(
          id: item['id']?.toString() ?? '',
          previewUrl: previewUrl,
          originalUrl: originalUrl,
          title: item['title'] as String? ?? '',
        ));
      }

      return gifs;
    } catch (e, st) {
      debugPrint('[GifService] Exception: $e\n$st');
      return [];
    }
  }
}
