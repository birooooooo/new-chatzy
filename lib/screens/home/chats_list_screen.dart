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

        const fg = Colors.white;
        final fgSubtle = Colors.white.withOpacity(0.45);
        final chipBg = Colors.white.withOpacity(0.1);
        final iconBg = Colors.white.withOpacity(0.1);
        final searchBg = Colors.white.withOpacity(0.1);

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
                        Text('Chitzy', style: TextStyle(color: fg, fontSize: 28, fontWeight: FontWeight.bold)),
                        const Spacer(),
                        _HeaderIcon(icon: Icons.search_rounded, color: fg, bg: iconBg, onTap: () => setState(() {
                          _isSearching = !_isSearching;
                          if (!_isSearching) _searchController.clear();
                        })),
                        const SizedBox(width: 8),
                        _HeaderIcon(icon: Icons.camera_alt_outlined, color: fg, bg: iconBg, onTap: () {}),
                        const SizedBox(width: 8),
                        _HeaderIcon(icon: Icons.more_vert_rounded, color: fg, bg: iconBg, onTap: () {}),
                      ],
                    ),
                    if (_isSearching) ...[
                      const SizedBox(height: 10),
                      Container(
                        height: 40,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(color: searchBg, borderRadius: BorderRadius.circular(20)),
                        child: TextField(
                          controller: _searchController,
                          autofocus: true,
                          style: TextStyle(color: fg, fontSize: 14),
                          onChanged: (_) => setState(() {}),
                          decoration: InputDecoration(
                            hintText: 'Search...',
                            hintStyle: TextStyle(color: fgSubtle, fontSize: 14),
                            border: InputBorder.none,
                            prefixIcon: Icon(Icons.search, color: fgSubtle, size: 18),
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
                                color: isActive ? fg : chipBg,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(f, style: TextStyle(
                                color: isActive ? Colors.black : fgSubtle,
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
                              builder: (itemContext) => _SwipeableChat(
                                onDelete: () => chatProvider.deleteChat(chat.id),
                                child: _ChatItem(
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
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: items,
                          ),
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
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
              ),
              child: const Icon(Icons.add_rounded, color: Colors.white70, size: 28),
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
    const fg = Colors.white;
    final fgSubtle = Colors.white.withOpacity(0.38);
    final fgMid = Colors.white.withOpacity(0.9);
    final timeColor = Colors.white.withOpacity(0.30);
    final pinColor = Colors.white.withOpacity(0.25);
    const onlineBorder = Colors.black;

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      behavior: HitTestBehavior.opaque,
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
            child: Row(
              children: [
                // Avatar
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
                            border: Border.all(color: onlineBorder, width: 2),
                            boxShadow: [BoxShadow(color: const Color(0xFFFF8C00).withOpacity(0.5), blurRadius: 4)],
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
                          color: fg,
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
                                color: hasUnread ? fgMid : fgSubtle,
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
                          color: hasUnread ? const Color(0xFFFF8C00) : timeColor,
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
                          boxShadow: [BoxShadow(color: const Color(0xFFFF3B30).withOpacity(0.4), blurRadius: 6)],
                        ),
                        child: Text(
                          unreadCount > 99 ? '99+' : unreadCount.toString(),
                          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ] else if (isPinned) ...[
                      const SizedBox(height: 6),
                      Icon(Icons.push_pin_rounded, size: 13, color: pinColor),
                    ],
                  ],
                ),
              ],
            ),
          ),

          // Orange left accent bar for unread
          if (hasUnread)
            Positioned(
              left: 0, top: 10, bottom: 10, width: 3,
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFFF8C00),
                  borderRadius: BorderRadius.circular(2),
                  boxShadow: [BoxShadow(color: const Color(0xFFFF8C00).withOpacity(0.6), blurRadius: 6)],
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
  final Color color;
  final Color bg;
  const _HeaderIcon({required this.icon, required this.onTap, required this.color, required this.bg});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
        child: Icon(icon, color: color, size: 18),
      ),
    );
  }
}

class _SwipeableChat extends StatefulWidget {
  final Widget child;
  final VoidCallback onDelete;
  const _SwipeableChat({required this.child, required this.onDelete});

  @override
  State<_SwipeableChat> createState() => _SwipeableChatState();
}

class _SwipeableChatState extends State<_SwipeableChat>
    with SingleTickerProviderStateMixin {
  static const double _snapButtonWidth = 72.0;
  static const double _snapThreshold = 36.0;
  double _itemWidth = 0.0;

  late AnimationController _controller;
  late Animation<double> _offsetAnim;
  double _dragOffset = 0.0;
  bool _isOpen = false;
  bool _isPendingDelete = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 240),
    );
    _offsetAnim = Tween<double>(begin: 0, end: 0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _snapTo(double target) {
    _offsetAnim = Tween<double>(begin: _dragOffset, end: target).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _controller.forward(from: 0).then((_) {
      if (mounted) setState(() => _dragOffset = target);
    });
  }

  void _onDragUpdate(DragUpdateDetails details) {
    if (_isPendingDelete) return;
    setState(() {
      _dragOffset = (_dragOffset + details.delta.dx).clamp(-_itemWidth, 80.0);
    });
  }

  void _onDragEnd(DragEndDetails details) {
    if (_isPendingDelete) return;
    final velocity = details.primaryVelocity ?? 0;
    final halfWidth = _itemWidth / 2;

    if (_dragOffset > 40 || velocity > 400) {
      _snapTo(0);
      Future.delayed(const Duration(milliseconds: 150), () {
        if (mounted) _showDeleteDialog();
      });
    } else if (_dragOffset < -halfWidth || velocity < -1000) {
      setState(() => _isPendingDelete = true);
      _snapTo(-halfWidth);
      Future.delayed(const Duration(milliseconds: 180), () {
        if (mounted) _showDeleteDialog();
      });
    } else if (velocity < -300 || _dragOffset < -_snapThreshold) {
      _isOpen = true;
      _snapTo(-_snapButtonWidth);
    } else {
      _isOpen = false;
      _snapTo(0);
    }
  }

  void _confirmDelete() {
    setState(() => _isPendingDelete = false);
    widget.onDelete();
  }

  void _cancelDelete() {
    setState(() => _isPendingDelete = false);
    _snapTo(0);
  }

  void _close() {
    _isOpen = false;
    _snapTo(0);
  }

  void _showDeleteDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E2435),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Chat?',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: const Text(
          'This conversation will be permanently deleted.',
          style: TextStyle(color: Colors.white60, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _cancelDelete();
            },
            child: const Text('No',
                style: TextStyle(color: Colors.white54, fontSize: 15)),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _confirmDelete();
            },
            child: const Text('Yes',
                style: TextStyle(
                    color: Color(0xFFFF3B30),
                    fontSize: 15,
                    fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        _itemWidth = constraints.maxWidth;
        return GestureDetector(
          onHorizontalDragUpdate: _onDragUpdate,
          onHorizontalDragEnd: _onDragEnd,
          onTap: _isOpen ? _close : null,
          child: ClipRect(
            child: Stack(
              children: [
                // Red background revealed on left swipe
                Positioned.fill(
                  child: AnimatedBuilder(
                    animation: _controller,
                    builder: (_, __) {
                      final raw = _controller.isAnimating
                          ? _offsetAnim.value
                          : _dragOffset;
                      final revealed = (-raw).clamp(0.0, double.infinity);
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Container(
                            width: revealed,
                            color: const Color(0xFFFF3B30),
                            child: revealed > 40
                                ? const Center(
                                    child: Icon(Icons.delete_rounded,
                                        color: Colors.white, size: 24),
                                  )
                                : null,
                          ),
                        ],
                      );
                    },
                  ),
                ),
                // Sliding chat row
                AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    final offset = _controller.isAnimating
                        ? _offsetAnim.value
                        : _dragOffset;
                    return Transform.translate(
                      offset: Offset(offset, 0),
                      child: child,
                    );
                  },
                  child: widget.child,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
