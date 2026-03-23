import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_widgets.dart';
import '../../widgets/glass_container.dart';

class ChatSearchScreen extends StatefulWidget {
  const ChatSearchScreen({super.key});

  @override
  State<ChatSearchScreen> createState() => _ChatSearchScreenState();
}

class _ChatSearchScreenState extends State<ChatSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isSearching = false;
  
  final List<Map<String, dynamic>> _searchResults = [
    {'type': 'message', 'chat': 'Sarah Johnson', 'text': 'Hey! How are you?', 'time': '2 hours ago'},
    {'type': 'message', 'chat': 'Tech Team', 'text': 'Meeting at 3pm today', 'time': 'Yesterday'},
    {'type': 'chat', 'name': 'Project Discussion', 'members': 5},
    {'type': 'message', 'chat': 'Alex Smith', 'text': 'Thanks for the help!', 'time': '2 days ago'},
    {'type': 'chat', 'name': 'Family Group', 'members': 8},
    {'type': 'message', 'chat': 'Emily Davis', 'text': 'See you tomorrow', 'time': '3 days ago'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
        title: TextField(
          controller: _searchController,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Search messages and chats...',
            border: InputBorder.none,
          ),
          onChanged: (value) {
            setState(() {
              _searchQuery = value;
              _isSearching = value.isNotEmpty;
            });
          },
        ),
        actions: [
          if (_searchQuery.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                _searchController.clear();
                setState(() {
                  _searchQuery = '';
                  _isSearching = false;
                });
              },
            ),
        ],
      ),
      body: _isSearching
          ? ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _searchResults.length,
              itemBuilder: (context, index) {
                final result = _searchResults[index];
                
                if (result['type'] == 'message') {
                  return _MessageSearchResult(
                    chat: result['chat'],
                    text: result['text'],
                    time: result['time'],
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Open chat with ${result['chat']}')),
                      );
                    },
                  )
                      .animate()
                      .fadeIn(delay: Duration(milliseconds: index * 50))
                      .slideX(begin: 0.05, end: 0);
                } else {
                  return _ChatSearchResult(
                    name: result['name'],
                    members: result['members'],
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Open ${result['name']}')),
                      );
                    },
                  )
                      .animate()
                      .fadeIn(delay: Duration(milliseconds: index * 50))
                      .slideX(begin: 0.05, end: 0);
                }
              },
            )
          : _buildEmptyState(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search,
            size: 80,
            color: AppTheme.textLight.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'Search for messages and chats',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: AppTheme.textLight,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Type to start searching',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.textLight,
            ),
          ),
        ],
      )
          .animate()
          .fadeIn(duration: 300.ms),
    );
  }
}

class _MessageSearchResult extends StatelessWidget {
  final String chat;
  final String text;
  final String time;
  final VoidCallback onTap;

  const _MessageSearchResult({
    required this.chat,
    required this.text,
    required this.time,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: AppTheme.borderRadiusMedium,
          boxShadow: AppTheme.softShadow,
        ),
        child: Row(
          children: [
            GlassContainer(
              width: 44,
              height: 44,
              borderRadius: BorderRadius.circular(12),
              blur: 10,
              color: Colors.white.withOpacity(0.1),
              child: const Icon(Icons.message, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(chat, style: Theme.of(context).textTheme.titleMedium),
                      Text(
                        time,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.textLight,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    text,
                    style: Theme.of(context).textTheme.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatSearchResult extends StatelessWidget {
  final String name;
  final int members;
  final VoidCallback onTap;

  const _ChatSearchResult({
    required this.name,
    required this.members,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: AppTheme.borderRadiusMedium,
          boxShadow: AppTheme.softShadow,
        ),
        child: Row(
          children: [
            AppAvatar(
              name: name,
              size: 44,
              icon: Icons.group_rounded,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: Theme.of(context).textTheme.titleMedium),
                  Text(
                    '$members members',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppTheme.textLight),
          ],
        ),
      ),
    );
  }
}
