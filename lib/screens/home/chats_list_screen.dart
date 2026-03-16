import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:async';
import '../../theme/app_theme.dart';
import '../chat/chat_screen.dart';
import '../chat/group_chat_screen.dart';
import 'contacts_screen.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/chat_provider.dart';
import '../../providers/story_provider.dart';
import '../../models/chat_model.dart';
import '../../models/story_model.dart';
import 'package:intl/intl.dart';
import '../../widgets/glass_container.dart';
import '../../widgets/glass_text_field.dart';
import '../../models/message_model.dart';

class ChatsListScreen extends StatefulWidget {
  const ChatsListScreen({super.key});

  @override
  State<ChatsListScreen> createState() => _ChatsListScreenState();
}

class _ChatsListScreenState extends State<ChatsListScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isSearching = false;
  bool _showStories = false;
  Timer? _storyHideTimer;
  // Tracks the story count from the last auto-show so new stories re-trigger it.
  int _lastSeenStoryCount = 0;

  // Duration constants
  static const Duration _storyWithContentDuration = Duration(seconds: 30);
  static const Duration _storyEmptyDuration = Duration(seconds: 3);

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final storyProvider = Provider.of<StoryProvider>(context);
    final currentCount = storyProvider.latestPerUser.length;

    // Auto-show only when new stories appear that we haven't shown yet
    if (currentCount > _lastSeenStoryCount && !_showStories) {
      _lastSeenStoryCount = currentCount;
      _showStoriesWith(hasContent: true);
    } else if (currentCount > _lastSeenStoryCount) {
      // Update tracker even if already visible
      _lastSeenStoryCount = currentCount;
    }
  }

  /// Shows the stories tray and schedules an auto-hide.
  /// [hasContent] true  → hide after 30 s
  ///              false → hide after  3 s
  void _showStoriesWith({required bool hasContent}) {
    _storyHideTimer?.cancel();
    if (mounted) setState(() => _showStories = true);
    _storyHideTimer = Timer(
      hasContent ? _storyWithContentDuration : _storyEmptyDuration,
      () {
        // Only auto-hide if there are still no new stories (for the 3s case)
        // or when the 30s timer fires (for the stories case).
        if (mounted) setState(() => _showStories = false);
      },
    );
  }

  void _onScroll() {
    if (_scrollController.offset < -80 && !_showStories) {
      final storyProvider = Provider.of<StoryProvider>(context, listen: false);
      final hasStories = storyProvider.latestPerUser.isNotEmpty;
      _showStoriesWith(hasContent: hasStories);
    }
  }

  // Data now comes from ChatProvider

  List<ChatModel> _getFilteredChats(List<ChatModel> allChats) {
    List<ChatModel> filtered = allChats.where((c) => c.type != ChatType.ai).toList();
    
    if (_searchController.text.isNotEmpty) {
      final query = _searchController.text.toLowerCase();
      filtered = filtered.where((c) =>
        c.name.toLowerCase().contains(query) ||
        (c.lastMessage?.content.toLowerCase().contains(query) ?? false)
      ).toList();
    }
    
    // Sort: pinned first, then by time
    filtered.sort((a, b) {
      if (a.isPinned && !b.isPinned) return -1;
      if (!a.isPinned && b.isPinned) return 1;
      
      final timeA = a.lastMessage?.timestamp ?? DateTime(2000);
      final timeB = b.lastMessage?.timestamp ?? DateTime(2000);
      return timeB.compareTo(timeA);
    });
    
    return filtered;
  }

  @override
  void dispose() {
    _storyHideTimer?.cancel();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ChatProvider>(
      builder: (context, chatProvider, child) {
        return Scaffold(
          backgroundColor: Colors.transparent,
          body: GestureDetector(
            onTap: () {
              if (_isSearching) {
                setState(() {
                  _isSearching = false;
                  _searchController.clear();
                });
                FocusScope.of(context).unfocus();
              }
            },
            child: CustomScrollView(
              controller: _scrollController,
              physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
              slivers: [
                // Custom App Bar
                SliverAppBar(
                  floating: true,
                  pinned: true,
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  expandedHeight: _isSearching ? 140 : 80,
                  toolbarHeight: 70,
                  flexibleSpace: FlexibleSpaceBar(
                    background: Padding(
                      padding: EdgeInsets.only(
                        top: MediaQuery.of(context).padding.top + 8,
                        left: 20,
                        right: 20,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'CHATZY',
                                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.0,
                                ),
                              ),
                              // Animated Search Button (Nav-style)
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _isSearching = !_isSearching;
                                    if (!_isSearching) _searchController.clear();
                                  });
                                },
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 400),
                                  curve: Curves.easeInOutCubic,
                                  padding: EdgeInsets.symmetric(
                                    horizontal: _isSearching ? 14 : 10,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _isSearching 
                                      ? (Theme.of(context).brightness == Brightness.light 
                                          ? Colors.black.withOpacity(0.08) 
                                          : Colors.white.withOpacity(0.12))
                                      : Colors.transparent,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Icon(
                                    _isSearching ? Icons.close : Icons.search_rounded,
                                    size: 24,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (_isSearching)
                            Container(
                              margin: const EdgeInsets.only(top: 15),
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              height: 50,
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.surface.withOpacity(
                                  Theme.of(context).brightness == Brightness.light ? 1.0 : 0.15,
                                ),
                                borderRadius: BorderRadius.circular(15),
                                border: Border.all(
                                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
                                ),
                              ),
                              child: TextField(
                                controller: _searchController,
                                autofocus: true,
                                style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                                onChanged: (_) => setState(() {}),
                                decoration: InputDecoration(
                                  hintText: 'Search chats...',
                                  hintStyle: TextStyle(
                                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                                    fontSize: 15,
                                  ),
                                  border: InputBorder.none,
                                  icon: Icon(
                                    Icons.search, 
                                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                                    size: 20,
                                  ),
                                ),
                              ),
                            ).animate().fadeIn(duration: 200.ms).slideY(begin: -0.1, end: 0),
                        ],
                      ),
                    ),
                  ),
                ),

                // Stories Tray
                SliverToBoxAdapter(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeInOutCubic,
                    height: _showStories ? 110 : 0,
                    child: ClipRect(
                      child: Opacity(
                        opacity: _showStories ? 1.0 : 0.0,
                        child: _buildStoriesTray(),
                      ),
                    ),
                  ),
                ),

                // Chats List Header
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 12),
                    child: Text(
                      'Recent Messages',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),

                // Chats List
                Builder(
                  builder: (context) {
                    final filteredChats = _getFilteredChats(chatProvider.chats);
                    
                    if (filteredChats.isEmpty) {
                      return SliverFillRemaining(
                        hasScrollBody: false,
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              GlassContainer(
                                width: 100,
                                height: 100,
                                borderRadius: BorderRadius.circular(30),
                                blur: 20,
                                child: Icon(
                                  Icons.chat_bubble_outline_rounded,
                                  size: 48,
                                  color: Colors.white.withOpacity(0.2),
                                ),
                              ).animate()
                                .scale(duration: 600.ms, curve: Curves.easeOutBack)
                                .fadeIn(),
                              const SizedBox(height: 24),
                              Text(
                                'No conversations yet',
                                style: GoogleFonts.inter(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ).animate().fadeIn(delay: 200.ms),
                              const SizedBox(height: 8),
                              Text(
                                'Start a new chat by searching for a friend\nor tapping the search icon above.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.4),
                                  fontSize: 14,
                                  height: 1.5,
                                ),
                              ).animate().fadeIn(delay: 400.ms),
                            ],
                          ),
                        ),
                      );
                    }

                    return SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final chat = filteredChats[index];
                            final lastMsg = chat.lastMessage;
                            final currentUserId = chatProvider.currentUserId ?? '';
                            final displayName = chat.getDisplayName(currentUserId);
                            final displayAvatar = chat.getDisplayAvatar(currentUserId);
                            
                            final timeStr = lastMsg != null 
                              ? (DateTime.now().difference(lastMsg.timestamp).inDays < 1
                                  ? DateFormat.jm().format(lastMsg.timestamp)
                                  : DateFormat.MMMd().format(lastMsg.timestamp))
                              : '';

                            return _ChatItem(
                              name: displayName,
                              message: lastMsg?.content ?? 'No messages yet',
                              time: timeStr,
                              unreadCount: chat.unreadCount,
                              isOnline: chat.participants.any((p) => p.id != currentUserId && p.isOnline),
                              isGroup: chat.type == ChatType.group,
                              isPinned: chat.isPinned,
                              imageUrl: displayAvatar,
                              onTap: () {
                                if (chat.type == ChatType.group) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => GroupChatScreen(chatId: chat.id, groupName: displayName),
                                    ),
                                  );
                                } else {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ChatScreen(
                                        chatId: chat.id,
                                        chatName: displayName,
                                        isOnline: chat.participants.any((p) => p.id != currentUserId && p.isOnline),
                                        imageUrl: displayAvatar,
                                      ),
                                    ),
                                  );
                                }
                              },
                              onLongPress: () => _showDeleteConfirmation(context, chatProvider, chat),
                            ).animate()
                              .fadeIn(delay: Duration(milliseconds: 100 * index), duration: 400.ms)
                              .slideY(begin: 0.1, end: 0, curve: Curves.easeOutQuart);
                          },
                          childCount: filteredChats.length,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

            ],
          ),
        );
      },
    );
  }

  void _showDeleteConfirmation(BuildContext context, ChatProvider provider, ChatModel chat) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Delete Confirmation',
      barrierColor: Colors.black.withOpacity(0.5),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) {
        final currentUserId = provider.currentUserId ?? '';
        final displayName = chat.getDisplayName(currentUserId);
        final displayAvatar = chat.getDisplayAvatar(currentUserId);
        
        return Scaffold(
          backgroundColor: Colors.transparent,
          body: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Highlighted Chat Item
                    _ChatItem(
                      name: displayName,
                      message: chat.lastMessage?.content ?? 'No messages yet',
                      time: '',
                      unreadCount: 0,
                      isOnline: false,
                      isGroup: chat.type == ChatType.group,
                      isPinned: false,
                      imageUrl: displayAvatar,
                      onTap: () {},
                      onLongPress: () {},
                    ).animate().scale(begin: const Offset(0.9, 0.9), end: const Offset(1, 1), duration: 400.ms, curve: Curves.easeOutBack).fadeIn(),
                    
                    const SizedBox(height: 30),
                    
                    // Options
                    GlassContainer(
                      padding: const EdgeInsets.all(20),
                      borderRadius: BorderRadius.circular(24),
                      blur: 20,
                      child: Column(
                        children: [
                          Text(
                            'Delete this chat?',
                            style: GoogleFonts.inter(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'All messages with $displayName will be permanently removed.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.6),
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 25),
                          Row(
                            children: [
                              Expanded(
                                child: TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 15),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                                  ),
                                  child: const Text('Cancel', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                                ),
                              ),
                              const SizedBox(width: 15),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () {
                                    provider.deleteChat(chat.id);
                                    Navigator.pop(context);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Chat deleted'),
                                        behavior: SnackBarBehavior.floating,
                                        backgroundColor: Colors.redAccent.withOpacity(0.8),
                                      ),
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.redAccent,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 15),
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                                  ),
                                  child: const Text('Delete', style: TextStyle(fontWeight: FontWeight.bold)),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ).animate().slideY(begin: 0.2, end: 0, duration: 400.ms, curve: Curves.easeOutQuart).fadeIn(),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStoriesTray() {
    return Container(
      height: 110,
      margin: const EdgeInsets.only(top: 10),
      child: Consumer<StoryProvider>(
        builder: (context, storyProvider, _) {
          final storyUsers = storyProvider.latestPerUser;

          return ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: storyUsers.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) return _buildAddStory();
              final story = storyUsers[index - 1];
              return _buildStoryItem(story, storyProvider);
            },
          );
        },
      ),
    );
  }

  Widget _buildAddStory() {
    return GestureDetector(
      onTap: () {},
      child: Container(
        margin: const EdgeInsets.only(right: 16),
        child: Column(
          children: [
            Stack(
              children: [
                Container(
                  width: 68,
                  height: 68,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withOpacity(0.12),
                      width: 1.5,
                    ),
                  ),
                  child: const Icon(
                    Icons.add_rounded,
                    color: Colors.white70,
                    size: 30,
                  ),
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: AppTheme.background,
                      shape: BoxShape.circle,
                    ),
                    child: Container(
                      width: 22,
                      height: 22,
                      decoration: const BoxDecoration(
                        color: AppTheme.secondary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.add, color: Colors.white, size: 14),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Your Story',
              style: TextStyle(color: Colors.white38, fontSize: 11),
            ),
          ],
        ),
      ),
    ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack);
  }

  Widget _buildStoryItem(StoryModel story, StoryProvider storyProvider) {
    final isViewed = storyProvider.isViewed(story.id, 'me');
    
    return GestureDetector(
      onTap: () {
        storyProvider.markViewed(story.id, 'me');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Viewing ${story.userName}\'s story'),
            backgroundColor: AppTheme.surface,
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(right: 16),
        child: Column(
          children: [
            // Gradient ring (fades if viewed)
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.all(2.5),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: isViewed
                    ? null
                    : const LinearGradient(
                        colors: [
                          Color(0xFFFF6B6B),
                          Color(0xFFFFE66D),
                          Color(0xFF4ECDC4),
                        ],
                      ),
                color: isViewed ? Colors.white24 : null,
              ),
              child: Container(
                padding: const EdgeInsets.all(2.5),
                decoration: const BoxDecoration(
                  color: AppTheme.background,
                  shape: BoxShape.circle,
                ),
                child: Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    image: story.userAvatar != null
                        ? DecorationImage(
                            image: NetworkImage(story.userAvatar!),
                            fit: BoxFit.cover,
                          )
                        : null,
                    gradient: story.userAvatar == null
                        ? AppTheme.primaryGradient
                        : null,
                  ),
                  child: story.userAvatar == null
                      ? Center(
                          child: Text(
                            story.userName[0].toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 22,
                            ),
                          ),
                        )
                      : null,
                ),
              ),
            ),
            const SizedBox(height: 6),
            SizedBox(
              width: 70,
              child: Text(
                story.userName.split(' ')[0],
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: isViewed
                      ? Colors.white38
                      : Colors.white.withOpacity(0.9),
                  fontSize: 11,
                  fontWeight: isViewed ? FontWeight.normal : FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack);
  }
}

class _ChatItem extends StatelessWidget {
  final String name;
  final String message;
  final String time;
  final int unreadCount;
  final bool isOnline;
  final bool isGroup;
  final bool isPinned;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final String? imageUrl;

  const _ChatItem({
    required this.name,
    required this.message,
    required this.time,
    required this.unreadCount,
    required this.isOnline,
    required this.isGroup,
    required this.isPinned,
    required this.onTap,
    required this.onLongPress,
    this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: GlassContainer(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(12),
        borderRadius: BorderRadius.circular(24),
        blur: 20,
        opacity: unreadCount > 0 ? 0.08 : 0.04,
        border: unreadCount > 0 
            ? Border.all(color: AppTheme.secondary.withOpacity(0.4), width: 1.5)
            : Border.all(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.07), width: 0.5),
        gradient: unreadCount > 0
            ? LinearGradient(
                colors: [AppTheme.secondary.withOpacity(0.15), Colors.transparent],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        child: Row(
          children: [
            Stack(
              children: [
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    gradient: isGroup ? AppTheme.primaryGradient : AppTheme.blueGradient,
                    borderRadius: BorderRadius.circular(20),
                    image: imageUrl != null && !isGroup
                        ? DecorationImage(
                            image: NetworkImage(imageUrl!),
                            fit: BoxFit.cover,
                          )
                        : null,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: imageUrl == null || isGroup
                      ? Center(
                          child: isGroup
                              ? const Icon(Icons.group_rounded, color: Colors.white, size: 28)
                              : Text(
                                  name[0].toUpperCase(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        )
                      : null,
                ),
                if (isOnline && !isGroup)
                  Positioned(
                    right: -2,
                    bottom: -2,
                    child: Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        color: AppTheme.background,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: AppTheme.online,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(color: AppTheme.online.withOpacity(0.5), blurRadius: 4),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontSize: 17,
                            fontWeight: unreadCount > 0 ? FontWeight.bold : FontWeight.w600,
                            letterSpacing: 0.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        time,
                        style: TextStyle(
                          color: unreadCount > 0
                              ? AppTheme.secondary
                              : Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                          fontSize: 12,
                          fontWeight: unreadCount > 0 ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          message,
                          style: TextStyle(
                            color: unreadCount > 0
                                ? Theme.of(context).colorScheme.onSurface.withOpacity(0.85)
                                : Theme.of(context).colorScheme.onSurface.withOpacity(0.35),
                            fontSize: 14,
                            fontWeight: unreadCount > 0 ? FontWeight.w500 : FontWeight.normal,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (unreadCount > 0)
                        Container(
                          margin: const EdgeInsets.only(left: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            gradient: AppTheme.primaryGradient,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.secondary.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              )
                            ],
                          ),
                          child: Text(
                            unreadCount > 99 ? '99+' : unreadCount.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
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
