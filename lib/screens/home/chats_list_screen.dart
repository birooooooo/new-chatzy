import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:async';
import 'dart:ui';
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
import '../../widgets/app_widgets.dart';
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
  int _lastSeenStoryCount = 0;
  String _activeFilter = 'All';
  final List<String> _filters = ['All', 'Favorites', 'Work', 'Groups', 'Communities'];

  // Focused interaction state
  ChatModel? _selectedChat;
  Offset? _selectedChatPosition;
  double _scrollOffset = 0.0;

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
    final offset = _scrollController.offset;
    if (mounted) setState(() => _scrollOffset = offset);
    if (offset < -80 && !_showStories) {
      final storyProvider = Provider.of<StoryProvider>(context, listen: false);
      final hasStories = storyProvider.latestPerUser.isNotEmpty;
      _showStoriesWith(hasContent: hasStories);
    }
  }

  String _relativeTime(DateTime t) {
    final diff = DateTime.now().difference(t);
    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} mins';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays == 1) return 'yesterday';
    return '${diff.inDays}d';
  }

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
        final topPad = MediaQuery.of(context).padding.top;

        return Scaffold(
          backgroundColor: Colors.transparent,
          body: Column(
            children: [
              // ── Fixed header (never scrolls) ──
              Container(
                padding: EdgeInsets.only(
                  top: topPad + 10,
                  left: 16, right: 16, bottom: 10,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        const Text('Chitzy', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                        const Spacer(),
                        _HeaderIcon(icon: Icons.search_rounded, onTap: () => setState(() {
                          _isSearching = !_isSearching;
                          if (!_isSearching) _searchController.clear();
                        })),
                        const SizedBox(width: 8),
                        _HeaderIcon(icon: Icons.camera_alt_outlined, onTap: () {}),
                        const SizedBox(width: 8),
                        _HeaderIcon(icon: Icons.more_vert_rounded, onTap: () {}),
                      ],
                    ),
                    if (_isSearching) ...[
                      const SizedBox(height: 10),
                      Container(
                        height: 40,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                        child: TextField(
                          controller: _searchController,
                          autofocus: true,
                          style: const TextStyle(color: Colors.white, fontSize: 14),
                          onChanged: (_) => setState(() {}),
                          decoration: InputDecoration(
                            hintText: 'Search...',
                            hintStyle: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 14),
                            border: InputBorder.none,
                            prefixIcon: Icon(Icons.search, color: Colors.white.withOpacity(0.5), size: 18),
                            isDense: true,
                          ),
                        ),
                      ).animate().fadeIn(duration: 200.ms),
                    ],
                    const SizedBox(height: 12),
                    if (_showStories) _buildStoriesTray(),
                    const SizedBox(height: 10),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: _filters.map((f) {
                          final isActive = _activeFilter == f;
                          return GestureDetector(
                            onTap: () => setState(() => _activeFilter = f),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              margin: const EdgeInsets.only(right: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                              decoration: BoxDecoration(
                                color: isActive ? Colors.white : Colors.white.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(f, style: TextStyle(
                                color: isActive ? Colors.black : Colors.white.withOpacity(0.7),
                                fontSize: 13,
                                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                              )),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),

              // ── Scrollable chat list (clipped below header) ──
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    if (_isSearching) {
                      setState(() { _isSearching = false; _searchController.clear(); });
                      FocusScope.of(context).unfocus();
                    }
                  },
                  child: ClipRect(
                    child: CustomScrollView(
                        controller: _scrollController,
                        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                        slivers: [

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

                        // Build all items inside one connected glass bubble
                        final currentUserId = chatProvider.currentUserId ?? '';
                        final items = <Widget>[];
                        for (int i = 0; i < filteredChats.length; i++) {
                          final chat = filteredChats[i];
                          final lastMsg = chat.lastMessage;
                          final displayName = chat.getDisplayName(currentUserId);
                          final displayAvatar = chat.getDisplayAvatar(currentUserId);
                          final timeStr = lastMsg != null ? _relativeTime(lastMsg.timestamp) : '';

                          final otherParticipant = (chat.type == ChatType.private && chat.participants.isNotEmpty)
                              ? chat.participants.firstWhere(
                                  (p) => p.id != currentUserId,
                                  orElse: () => chat.participants.first,
                                )
                              : null;
                          final liveOther = otherParticipant != null
                              ? (chatProvider.getLiveUser(otherParticipant.id) ?? otherParticipant)
                              : null;
                          final isOnline = liveOther?.isOnline ?? false;

                          items.add(
                            Builder(
                              builder: (itemContext) => _ChatItem(
                                name: displayName,
                                message: lastMsg?.content ?? 'No messages yet',
                                time: timeStr,
                                unreadCount: chat.getUnreadCount(currentUserId),
                                isOnline: isOnline,
                                isGroup: chat.type == ChatType.group,
                                isPinned: chat.isPinned,
                                imageUrl: displayAvatar,
                                onTap: () {
                                  if (chat.type == ChatType.group) {
                                    Navigator.push(context, MaterialPageRoute(
                                      builder: (_) => GroupChatScreen(chatId: chat.id, groupName: displayName),
                                    ));
                                  } else {
                                    Navigator.push(context, MaterialPageRoute(
                                      builder: (_) => ChatScreen(
                                        chatId: chat.id,
                                        chatName: displayName,
                                        isOnline: isOnline,
                                        imageUrl: displayAvatar,
                                      ),
                                    ));
                                  }
                                },
                                onLongPress: () {
                                  final RenderBox box = itemContext.findRenderObject() as RenderBox;
                                  final position = box.localToGlobal(Offset.zero);
                                  setState(() {
                                    _selectedChat = chat;
                                    _selectedChatPosition = position;
                                  });
                                },
                              ),
                            ),
                          );

                          // Divider between items, not after last
                          if (i < filteredChats.length - 1) {
                            items.add(
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 14),
                                child: Container(
                                  height: 0.5,
                                  color: Colors.white.withOpacity(0.08),
                                ),
                              ),
                            );
                          }
                        }

                        return SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Colors.white.withOpacity(0.10),
                                    Colors.white.withOpacity(0.03),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(24),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: items,
                              ),
                            ),
                          ).animate()
                            .fadeIn(duration: 400.ms)
                            .slideY(begin: 0.06, end: 0, curve: Curves.easeOutQuart),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFocusedOverlay(ChatProvider provider) {
    if (_selectedChat == null || _selectedChatPosition == null) return const SizedBox.shrink();

    return Positioned.fill(
      child: GestureDetector(
        onTap: () => setState(() {
          _selectedChat = null;
          _selectedChatPosition = null;
        }),
        child: Container(
          color: Colors.black.withOpacity(0.5),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Stack(
              children: [
                Positioned(
                  top: _selectedChatPosition!.dy,
                  left: _selectedChatPosition!.dx,
                  right: 20,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Transform.scale(
                        scale: 1.05,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Colors.white.withOpacity(0.14),
                                    Colors.white.withOpacity(0.04),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(color: Colors.white.withOpacity(0.18), width: 1),
                              ),
                              child: _ChatItem(
                                name: _selectedChat!.getDisplayName(provider.currentUserId ?? ''),
                                message: _selectedChat!.lastMessage?.content ?? 'No messages yet',
                                time: '',
                                unreadCount: _selectedChat!.getUnreadCount(provider.currentUserId),
                                isOnline: _selectedChat!.participants.any((p) => p.id != provider.currentUserId && p.isOnline),
                                isGroup: _selectedChat!.type == ChatType.group,
                                isPinned: _selectedChat!.isPinned,
                                imageUrl: _selectedChat!.getDisplayAvatar(provider.currentUserId ?? ''),
                                onTap: () {},
                                onLongPress: () {},
                              ),
                            ),
                          ),
                        ),
                      ).animate()
                        .scale(duration: 400.ms, curve: Curves.easeOutBack, begin: const Offset(0.95, 0.95))
                        .fadeIn(),
                      
                      const SizedBox(height: 16),
                      
                      GestureDetector(
                        onTap: () {
                          final chat = _selectedChat!;
                          provider.deleteChat(chat.id);
                          setState(() {
                            _selectedChat = null;
                            _selectedChatPosition = null;
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Chat with ${chat.name} deleted'),
                              behavior: SnackBarBehavior.floating,
                              backgroundColor: AppTheme.error.withOpacity(0.9),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.redAccent.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.redAccent.withOpacity(0.3),
                                blurRadius: 15,
                              )
                            ],
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.delete_outline_rounded, color: Colors.white, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'Delete Conversation',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ).animate().fadeIn(delay: 200.ms).slideY(begin: -0.2, end: 0),
                      ),
                    ],
                  ),
                ),
                
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 120),
                    child: Text(
                      'Tap anywhere to cancel',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.4),
                        fontSize: 12,
                      ),
                    ).animate().fadeIn(delay: 500.ms),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStoriesTray() {
    return SizedBox(
      height: 100,
      child: Consumer<StoryProvider>(
        builder: (context, storyProvider, _) {
          final storyUsers = storyProvider.latestPerUser;
          return ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.zero,
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
        margin: const EdgeInsets.only(right: 10),
        child: Column(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  width: 68,
                  height: 68,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
                  ),
                  child: const Icon(Icons.add_rounded, color: Colors.white70, size: 28),
                ),
              ),
            ),
            const SizedBox(height: 6),
            const Text('You', style: TextStyle(color: Colors.white54, fontSize: 11)),
          ],
        ),
      ),
    );
  }

  Widget _buildStoryItem(StoryModel story, StoryProvider storyProvider) {
    final isViewed = storyProvider.isViewed(story.id, 'me');
    return GestureDetector(
      onTap: () => storyProvider.markViewed(story.id, 'me'),
      child: Container(
        margin: const EdgeInsets.only(right: 10),
        child: Column(
          children: [
            Stack(
              children: [
                // Square story thumbnail with orange glow border
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 68,
                  height: 68,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isViewed
                          ? Colors.white24
                          : const Color(0xFFFF8C00),
                      width: isViewed ? 1.5 : 2.5,
                    ),
                    boxShadow: isViewed
                        ? []
                        : [
                            BoxShadow(
                              color: const Color(0xFFFF8C00).withOpacity(0.4),
                              blurRadius: 8,
                              spreadRadius: 1,
                            )
                          ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: story.userAvatar != null
                        ? Image.network(story.userAvatar!, fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              color: Colors.white.withOpacity(0.1),
                              child: const Icon(Icons.person, color: Colors.white54),
                            ))
                        : Container(
                            color: Colors.white.withOpacity(0.1),
                            child: const Icon(Icons.person, color: Colors.white54),
                          ),
                  ),
                ),
                // Count badge
                Positioned(
                  top: 4,
                  right: 4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF8C00),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text('3', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            SizedBox(
              width: 68,
              child: Text(
                story.userName.split(' ')[0],
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: isViewed ? Colors.white38 : Colors.white.withOpacity(0.9),
                  fontSize: 11,
                  fontWeight: isViewed ? FontWeight.normal : FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 300.ms);
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
    final bool hasUnread = unreadCount > 0;

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      behavior: HitTestBehavior.opaque,
      child: Stack(
        children: [
          // Row content
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
            child: Row(
              children: [
                // Avatar with orange online dot
                Stack(
                  children: [
                    AppAvatar(
                      name: name,
                      size: 52,
                      imageUrl: isGroup ? null : imageUrl,
                      isOnline: false,
                      icon: isGroup ? Icons.group_rounded : null,
                    ),
                    if (isOnline && !isGroup)
                      Positioned(
                        right: 1,
                        bottom: 1,
                        child: Container(
                          width: 13,
                          height: 13,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF8C00),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.black, width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFFF8C00).withOpacity(0.5),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 13),

                // Name + message
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        name,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: hasUnread ? FontWeight.bold : FontWeight.w500,
                          letterSpacing: 0.1,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          if (!hasUnread) ...[
                            Icon(Icons.done_all, size: 14, color: Colors.blue.shade300),
                            const SizedBox(width: 4),
                          ],
                          Expanded(
                            child: Text(
                              message,
                              style: TextStyle(
                                color: hasUnread
                                    ? Colors.white.withOpacity(0.9)
                                    : Colors.white.withOpacity(0.38),
                                fontSize: 13,
                                fontWeight: hasUnread ? FontWeight.w500 : FontWeight.normal,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 10),

                // Right: time + badge
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (time.isNotEmpty)
                      Text(
                        time,
                        style: TextStyle(
                          color: hasUnread
                              ? const Color(0xFFFF8C00)
                              : Colors.white.withOpacity(0.30),
                          fontSize: 11,
                          fontWeight: hasUnread ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    if (hasUnread) ...[
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF3B30),
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFF3B30).withOpacity(0.4),
                              blurRadius: 6,
                            ),
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
                    ] else if (isPinned) ...[
                      const SizedBox(height: 6),
                      Icon(Icons.push_pin_rounded, size: 13, color: Colors.white.withOpacity(0.25)),
                    ],
                  ],
                ),
              ],
            ),
          ),

          // Orange left accent bar for unread
          if (hasUnread)
            Positioned(
              left: 0,
              top: 10,
              bottom: 10,
              width: 3,
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFFF8C00),
                  borderRadius: BorderRadius.circular(2),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF8C00).withOpacity(0.6),
                      blurRadius: 6,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}


class _HeaderIcon extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _HeaderIcon({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 18),
      ),
    );
  }
}
