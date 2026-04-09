import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';

class StoryViewerScreen extends StatefulWidget {
  final List<StoryViewItem> stories;
  final int initialIndex;

  const StoryViewerScreen({
    super.key,
    required this.stories,
    required this.initialIndex,
  });

  @override
  State<StoryViewerScreen> createState() => _StoryViewerScreenState();
}

class _StoryViewerScreenState extends State<StoryViewerScreen> {
  late PageController _pageController;
  late int _currentIndex;
  bool _isLiked = false;
  bool _isBookmarked = false;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    _pageController.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: PageView.builder(
        controller: _pageController,
        scrollDirection: Axis.vertical,
        itemCount: widget.stories.length,
        onPageChanged: (i) => setState(() {
          _currentIndex = i;
          _isLiked = false;
          _isBookmarked = false;
        }),
        itemBuilder: (context, index) {
          final story = widget.stories[index];
          return _StoryPage(
            story: story,
            isLiked: index == _currentIndex ? _isLiked : false,
            isBookmarked: index == _currentIndex ? _isBookmarked : false,
            onClose: () => Navigator.pop(context),
            onLike: () => setState(() => _isLiked = !_isLiked),
            onBookmark: () => setState(() => _isBookmarked = !_isBookmarked),
          );
        },
      ),
    );
  }
}

class _StoryPage extends StatelessWidget {
  final StoryViewItem story;
  final bool isLiked;
  final bool isBookmarked;
  final VoidCallback onClose;
  final VoidCallback onLike;
  final VoidCallback onBookmark;

  const _StoryPage({
    required this.story,
    required this.isLiked,
    required this.isBookmarked,
    required this.onClose,
    required this.onLike,
    required this.onBookmark,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Full-screen image
        Image.network(
          story.photo,
          fit: BoxFit.cover,
          loadingBuilder: (_, child, progress) {
            if (progress == null) return child;
            return Container(
              color: Colors.grey[900],
              child: const Center(child: CircularProgressIndicator(color: Colors.white54)),
            );
          },
          errorBuilder: (_, __, ___) => Container(
            color: Colors.grey[900],
            child: const Center(child: Icon(Icons.broken_image, color: Colors.white24, size: 60)),
          ),
        ),

        // Bottom gradient
        Positioned(
          left: 0, right: 0, bottom: 0,
          height: 260,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  Colors.black.withOpacity(0.85),
                  Colors.black.withOpacity(0.3),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
          ),
        ),

        // Top: back + title
        Positioned(
          top: 0, left: 0, right: 0,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: onClose,
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.3),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 16),
                    ),
                  ),
                  const Expanded(
                    child: Text(
                      'Spotlight',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {},
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.3),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.ios_share_rounded, color: Colors.white, size: 18),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Right side actions
        Positioned(
          right: 14,
          bottom: 120,
          child: Column(
            children: [
              _ActionButton(
                icon: isBookmarked ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                color: isBookmarked ? const Color(0xFFFFD93D) : Colors.white,
                onTap: onBookmark,
              ),
              const SizedBox(height: 20),
              _ActionButton(
                icon: isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                color: isLiked ? const Color(0xFFFF3B5C) : Colors.white,
                label: story.likes,
                onTap: onLike,
              ),
              const SizedBox(height: 20),
              _ActionButton(
                icon: Icons.reply_rounded,
                color: Colors.white,
                flipH: true,
                onTap: () {},
              ),
              const SizedBox(height: 20),
              _ActionButton(
                icon: Icons.more_horiz_rounded,
                color: Colors.white,
                onTap: () => _showOptions(context),
              ),
            ],
          ),
        ),

        // Bottom left: user info + views + sound
        Positioned(
          left: 16,
          right: 80,
          bottom: 0,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Views
                  Row(
                    children: [
                      const Icon(Icons.play_arrow_rounded, color: Colors.white70, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        story.views,
                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Avatar + username
                  Row(
                    children: [
                      ClipOval(
                        child: Image.network(
                          story.avatar,
                          width: 34,
                          height: 34,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => CircleAvatar(
                            radius: 17,
                            backgroundColor: Colors.white24,
                            child: Text(story.name[0], style: const TextStyle(color: Colors.white)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        '@${story.username}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Sound info
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.35),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.music_note_rounded, color: Colors.white70, size: 13),
                            const SizedBox(width: 6),
                            Text(
                              story.sound,
                              style: const TextStyle(color: Colors.white, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Swipe hint
        const Positioned(
          bottom: 6,
          left: 0, right: 0,
          child: Center(
            child: Icon(Icons.keyboard_arrow_up_rounded, color: Colors.white38, size: 22),
          ),
        ),
      ],
    );
  }

  void _showOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            color: Colors.black.withOpacity(0.6),
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 36, height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                _OptionTile(icon: Icons.flag_outlined, label: 'Report'),
                _OptionTile(icon: Icons.not_interested_rounded, label: 'Not interested'),
                _OptionTile(icon: Icons.block_rounded, label: 'Block user'),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String? label;
  final bool flipH;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.color,
    this.label,
    this.flipH = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.35),
              shape: BoxShape.circle,
            ),
            child: Transform(
              alignment: Alignment.center,
              transform: flipH ? (Matrix4.identity()..scale(-1.0, 1.0, 1.0)) : Matrix4.identity(),
              child: Icon(icon, color: color, size: 24),
            ),
          ),
          if (label != null) ...[
            const SizedBox(height: 4),
            Text(label!, style: const TextStyle(color: Colors.white70, fontSize: 11)),
          ],
        ],
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  final IconData icon;
  final String label;

  const _OptionTile({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: Colors.white70),
      title: Text(label, style: const TextStyle(color: Colors.white)),
      onTap: () => Navigator.pop(context),
    );
  }
}

// ─── Data model ──────────────────────────────────────────────────────────────

class StoryViewItem {
  final String name;
  final String username;
  final String avatar;
  final String photo;
  final String views;
  final String likes;
  final String sound;

  const StoryViewItem({
    required this.name,
    required this.username,
    required this.avatar,
    required this.photo,
    required this.views,
    required this.likes,
    required this.sound,
  });
}
