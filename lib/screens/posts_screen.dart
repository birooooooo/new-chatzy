import 'package:flutter/material.dart';
import '../services/post_service.dart';
import 'welcome_screen.dart';

class PostsScreen extends StatefulWidget {
  const PostsScreen({super.key});

  @override
  State<PostsScreen> createState() => _PostsScreenState();
}

class _PostsScreenState extends State<PostsScreen> {
  // ── Backend service ──
  final _postService = PostService();

  List<Map<String, dynamic>> _posts = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPosts();
  }

  Future<void> _loadPosts() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      // ── PostService: fetch from posts.json ──
      final posts = await _postService.fetchPosts();
      setState(() { _posts = posts; _isLoading = false; });
    } catch (e) {
      setState(() { _error = 'Failed to load posts.'; _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Posts', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.home_outlined),
            onPressed: () => Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const WelcomeScreen()),
              (route) => false,
            ),
          ),
          IconButton(icon: const Icon(Icons.refresh_rounded), onPressed: _loadPosts),
        ],
      ),
      body: _isLoading
          ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              CircularProgressIndicator(strokeWidth: 3, valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).primaryColor)),
              const SizedBox(height: 16),
              const Text('Loading posts...', style: TextStyle(color: Color(0xFF757575))),
            ]))
          : _error != null
              ? Center(child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    const Icon(Icons.error_outline, color: Colors.red, size: 60),
                    const SizedBox(height: 16),
                    Text(_error!, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, color: Color(0xFF1A1A1A))),
                    const SizedBox(height: 24),
                    ElevatedButton(onPressed: _loadPosts, child: const Text('Try Again')),
                  ]),
                ))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _posts.length,
                  itemBuilder: (context, i) => _buildPostCard(_posts[i]),
                ),
    );
  }

  Widget _buildPostCard(Map<String, dynamic> post) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // ── Image ──
          SizedBox(
            width: double.infinity, height: 200,
            child: Image.network(
              post['imageUrl'] as String,
              fit: BoxFit.cover,
              loadingBuilder: (_, child, progress) {
                if (progress == null) return child;
                return Container(height: 200, color: const Color(0xFFF3F4F6),
                  child: Center(child: CircularProgressIndicator(
                    value: progress.expectedTotalBytes != null ? progress.cumulativeBytesLoaded / progress.expectedTotalBytes! : null,
                    color: Theme.of(context).primaryColor, strokeWidth: 2,
                  )));
              },
              errorBuilder: (_, __, ___) => Container(height: 200, color: const Color(0xFFF3F4F6),
                child: const Center(child: Icon(Icons.broken_image_outlined, color: Color(0xFFD1D5DB), size: 40))),
            ),
          ),
          // ── Title + Body ──
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Post #${post['id']}', style: TextStyle(color: Theme.of(context).primaryColor, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8)),
              const SizedBox(height: 6),
              Text(post['title'] as String, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A))),
              const SizedBox(height: 8),
              Text(post['body'] as String, style: const TextStyle(fontSize: 14, color: Color(0xFF6B7280), height: 1.5)),
            ]),
          ),
        ]),
      ),
    );
  }
}
