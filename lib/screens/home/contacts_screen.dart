import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/glass_container.dart';
import '../../widgets/glass_text_field.dart';
import '../../services/user_service.dart';
import '../../models/user_model.dart';
import '../../models/chat_model.dart';
import '../../services/auth_service.dart';
import '../../providers/chat_provider.dart';
import '../chat/chat_screen.dart';
import '../../providers/theme_provider.dart';
import '../../widgets/app_widgets.dart';

class ContactsScreen extends StatefulWidget {
  const ContactsScreen({super.key});

  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> {
  final UserService _userService = UserService();
  final TextEditingController _searchController = TextEditingController();
  List<UserModel> _searchResults = [];
  bool _isLoading = false;
  String? _currentUserid;

  @override
  void initState() {
    super.initState();
    _currentUserid = Provider.of<AuthService>(context, listen: false).currentUser?.id;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _performSearch(String query) async {
    if (query.length < 2) {
      if (mounted) setState(() => _searchResults = []);
      return;
    }

    setState(() => _isLoading = true);
    try {
      final results = await _userService.searchUsers(query);
      if (mounted) {
        setState(() {
          // Filter out current user
          _searchResults = results.where((u) => u.id != _currentUserid).toList();
        });
      }
    } catch (e) {
      debugPrint("Search error: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _startChat(UserModel user) {
    if (_currentUserid == null) return;

    // Check if chat already exists or create new one
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    
    // Logic to find existing private chat
    final existingChat = chatProvider.chats.firstWhere(
      (c) => c.type == ChatType.private && c.participantIds.contains(user.id),
      orElse: () => ChatModel(
        id: '', // Empty ID signals new chat
        name: user.name,
        type: ChatType.private,
        participants: [user],
        unreadCounts: const {},
        isPinned: false,
        isMuted: false, 
        adminIds: [],
      ),
    );

    if (existingChat.id.isNotEmpty) {
      // Open existing chat
      final displayName = existingChat.getDisplayName(_currentUserid!);
      final displayAvatar = existingChat.getDisplayAvatar(_currentUserid!);
      
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatScreen(
            chatId: existingChat.id,
            chatName: displayName,
            imageUrl: displayAvatar,
            isOnline: user.isOnline,
          ),
        ),
      );
    } else {
      // Create new chat
      chatProvider.createChat([user]).then((chatId) {
        if (!mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatScreen(
              chatId: chatId,
              chatName: user.name,
              imageUrl: user.avatar,
              isOnline: user.isOnline,
            ),
          ),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Container(
      decoration: themeProvider.backgroundDecoration,
      child: Scaffold(
        backgroundColor: Colors.transparent,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 16, 20, 12),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Text(
                    'Find People',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),

          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: GlassTextField(
              controller: _searchController,
              hintText: 'Search by username or name...',
              prefixIcon: const Icon(Icons.search_outlined),
              textInputAction: TextInputAction.search,
              onChanged: (val) {
                // Debounce could be added here
                if (val.length > 2) _performSearch(val);
              },
              onSubmitted: _performSearch,
            ),
          ),

          const SizedBox(height: 8),

          // Contacts list
          Expanded(
            child: _isLoading 
                ? const Center(child: CircularProgressIndicator(color: AppTheme.secondary))
                : _searchResults.isEmpty 
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
                        itemCount: _searchResults.length,
                        itemBuilder: (context, index) {
                          final user = _searchResults[index];
                          return _buildUserItem(user, index);
                        },
                      ),
          ),

        ],
      ),
    ),
      ),
  );
}

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          GlassContainer(
            width: 80,
            height: 80,
            borderRadius: BorderRadius.circular(25),
            blur: 15,
            child: Icon(
              Icons.person_add_outlined,
              size: 36,
              color: Colors.white.withOpacity(0.2),
            ),
          ).animate()
            .scale(duration: 500.ms, curve: Curves.easeOutBack)
            .fadeIn(),
          const SizedBox(height: 24),
          const Text(
            'Ready to expand?',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ).animate().fadeIn(delay: 200.ms),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Search by username or email to find and connect with people.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withOpacity(0.4),
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ).animate().fadeIn(delay: 400.ms),
        ],
      ),
    );
  }

  Widget _buildUserItem(UserModel user, int index) {
    return GestureDetector(
      onTap: () => _startChat(user),
      child: GlassContainer(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        borderRadius: BorderRadius.circular(20),
        blur: 15,
        opacity: 0.05,
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 0.5,
        ),
        child: Row(
          children: [
            AppAvatar(
              name: user.name,
              size: 50,
              imageUrl: user.avatar,
              isOnline: user.isOnline,
            ),
            const SizedBox(width: 14),
            // Name and username
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '@${user.username ?? "user"}',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            // Actions
            Icon(Icons.chat_bubble_outline_rounded, color: AppTheme.secondary, size: 24),
          ],
        ),
      ).animate()
          .fadeIn(delay: Duration(milliseconds: 50 * index), duration: 300.ms)
          .slideX(begin: 0.05, end: 0),
    );
  }
}
