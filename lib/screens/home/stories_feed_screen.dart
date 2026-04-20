import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../theme/app_theme.dart';
import '../../widgets/glass_container.dart';
import '../../widgets/app_widgets.dart';
import '../../services/story_service.dart';
import '../../services/auth_service.dart';
import '../../providers/story_provider.dart';
import '../../models/story_model.dart';
import 'dart:ui';
import 'dart:io';
import 'story_viewer_screen.dart';

class StoriesFeedScreen extends StatefulWidget {
  const StoriesFeedScreen({super.key});

  @override
  State<StoriesFeedScreen> createState() => _StoriesFeedScreenState();
}

class _StoriesFeedScreenState extends State<StoriesFeedScreen> {
  final StoryService _storyService = StoryService();
  final ImagePicker _picker = ImagePicker();
  bool _isUploading = false;

  // Placeholder gradient colors for story rings
  static const List<List<Color>> _ringGradients = [
    [Color(0xFFB14FFF), Color(0xFF6C63FF)],
    [Color(0xFF43CFFF), Color(0xFF4F8EFF)],
    [Color(0xFFFF9F43), Color(0xFFFF6B6B)],
    [Color(0xFFFFD93D), Color(0xFFFF9F43)],
    [Color(0xFF6BCB77), Color(0xFF43CFFF)],
    [Color(0xFFFF6B6B), Color(0xFFB14FFF)],
  ];

  // Mock discover stories (public/trending)
  static final List<_MockStory> _mockDiscover = [
    _MockStory(name: 'Alex Rivera',    username: 'alex.rv',     avatar: 'https://i.pravatar.cc/150?img=3',  photo: 'https://picsum.photos/seed/story1/400/700',  time: '2m ago',  views: '2.1k', likes: '384',  sound: 'Original Sound · alex.rv'),
    _MockStory(name: 'Mia Chen',       username: 'mia.chen',    avatar: 'https://i.pravatar.cc/150?img=5',  photo: 'https://picsum.photos/seed/story2/400/700',  time: '8m ago',  views: '890',  likes: '142',  sound: 'Aesthetic Vibes · lofi'),
    _MockStory(name: 'Jordan Lee',     username: 'jordan_lee',  avatar: 'https://i.pravatar.cc/150?img=8',  photo: 'https://picsum.photos/seed/story3/400/700',  time: '15m ago', views: '4.5k', likes: '912',  sound: 'Summer Hit · Trending'),
    _MockStory(name: 'Sofia Martin',   username: 'sofia.m',     avatar: 'https://i.pravatar.cc/150?img=9',  photo: 'https://picsum.photos/seed/story4/400/700',  time: '23m ago', views: '1.3k', likes: '256',  sound: 'Original Sound · sofia.m'),
    _MockStory(name: 'Ethan Brooks',   username: 'ethan_b',     avatar: 'https://i.pravatar.cc/150?img=11', photo: 'https://picsum.photos/seed/story5/400/700',  time: '41m ago', views: '678',  likes: '98',   sound: 'Chill Wave · playlist'),
    _MockStory(name: 'Chloe Adams',    username: 'chloeadams',  avatar: 'https://i.pravatar.cc/150?img=16', photo: 'https://picsum.photos/seed/story6/400/700',  time: '1h ago',  views: '3.2k', likes: '601',  sound: 'Original Sound · chloeadams'),
    _MockStory(name: 'Liam Torres',    username: 'liam.t',      avatar: 'https://i.pravatar.cc/150?img=12', photo: 'https://picsum.photos/seed/story7/400/700',  time: '1h ago',  views: '520',  likes: '77',   sound: 'Night Drive · lofi'),
    _MockStory(name: 'Ava Johnson',    username: 'ava.j',       avatar: 'https://i.pravatar.cc/150?img=20', photo: 'https://picsum.photos/seed/story8/400/700',  time: '2h ago',  views: '7.8k', likes: '1.4k', sound: 'Pop Hit 2024 · Trending'),
    _MockStory(name: 'Noah Williams',  username: 'noahw',       avatar: 'https://i.pravatar.cc/150?img=14', photo: 'https://picsum.photos/seed/story9/400/700',  time: '2h ago',  views: '2.9k', likes: '430',  sound: 'Original Sound · noahw'),
    _MockStory(name: 'Isabella Scott', username: 'bella.s',     avatar: 'https://i.pravatar.cc/150?img=21', photo: 'https://picsum.photos/seed/story10/400/700', time: '3h ago',  views: '1.1k', likes: '189',  sound: 'Soft Piano · relaxing'),
  ];

  // Convert mock stories to viewer items
  static List<StoryViewItem> get _viewerItems => _mockDiscover.map((m) => StoryViewItem(
    name: m.name,
    username: m.username,
    avatar: m.avatar,
    photo: m.photo,
    views: m.views,
    likes: m.likes,
    sound: m.sound,
  )).toList();

  // Mock friends stories
  static final List<_MockStory> _mockFriends = [
    _MockStory(name: 'Jake',   username: 'jake',   avatar: 'https://i.pravatar.cc/150?img=6',  photo: '', time: ''),
    _MockStory(name: 'Priya',  username: 'priya',  avatar: 'https://i.pravatar.cc/150?img=47', photo: '', time: ''),
    _MockStory(name: 'Marcus', username: 'marcus', avatar: 'https://i.pravatar.cc/150?img=13', photo: '', time: ''),
    _MockStory(name: 'Luna',   username: 'luna',   avatar: 'https://i.pravatar.cc/150?img=44', photo: '', time: ''),
    _MockStory(name: 'Omar',   username: 'omar',   avatar: 'https://i.pravatar.cc/150?img=15', photo: '', time: ''),
  ];

  Future<void> _pickAndUploadStory() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;

    setState(() => _isUploading = true);

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final storyProvider = Provider.of<StoryProvider>(context, listen: false);
      final user = authService.currentUser;

      if (user != null) {
        await _storyService.postStory(
          userId: user.id,
          userName: user.name,
          userAvatar: user.avatar,
          mediaFile: File(image.path),
        );

        final now = DateTime.now();
        storyProvider.addStory(StoryModel(
          id: 'story_${now.millisecondsSinceEpoch}',
          userId: user.id,
          userName: user.name,
          userAvatar: user.avatar,
          type: StoryType.image,
          content: image.path,
          createdAt: now,
          expiresAt: now.add(const Duration(hours: 24)),
        ));

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Story posted successfully!')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error posting story: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Pinned App Bar
            SliverAppBar(
              pinned: true,
              backgroundColor: Colors.transparent,
              surfaceTintColor: Colors.transparent,
              shadowColor: Colors.transparent,
              automaticallyImplyLeading: false,
              title: Text(
                'Stories',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              actions: [
                GestureDetector(
                  onTap: _pickAndUploadStory,
                  child: Container(
                    width: 38,
                    height: 38,
                    margin: const EdgeInsets.only(right: 16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withOpacity(0.2)),
                    ),
                    child: _isUploading
                        ? const Padding(
                            padding: EdgeInsets.all(10),
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 18),
                  ),
                ),
              ],
            ),

            // Friends Section
            SliverToBoxAdapter(
              child: _buildFriendsSection(context, const [])
                  .animate().fadeIn(duration: 300.ms),
            ),

            // Discover Section
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 10),
                child: Text(
                  'Discover',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ).animate().fadeIn(delay: 100.ms),
            ),

            // Discover Grid — always shows mock stories + real ones
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
              sliver: SliverGrid(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final mock = _mockDiscover[index];
                    return _MockDiscoverCard(
                      mock: mock,
                      index: index,
                      allItems: _viewerItems,
                    );
                  },
                  childCount: _mockDiscover.length,
                ),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 0.62,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFriendsSection(BuildContext context, List<StoryModel> stories) {
    final user = Provider.of<AuthService>(context, listen: false).currentUser;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
          child: Text(
            'Friends',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ),
        SizedBox(
          height: 104,
          child: ListView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              // My Story
              _FriendStoryBubble(
                name: 'My Story',
                imageUrl: user?.avatar,
                initials: user?.name ?? 'Me',
                gradientColors: const [Color(0xFFB14FFF), Color(0xFF6C63FF)],
                isMyStory: true,
                isUploading: _isUploading,
                onTap: _pickAndUploadStory,
              ),
              const SizedBox(width: 4),
              // Real friends' stories
              ...stories.asMap().entries.map((entry) {
                final index = entry.key;
                final story = entry.value;
                final colors = _ringGradients[index % _ringGradients.length];
                return Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: _FriendStoryBubble(
                    name: story.userName.split(' ').first,
                    imageUrl: story.userAvatar,
                    initials: story.userName,
                    gradientColors: colors,
                    onTap: () {
                      _storyService.viewStory(
                        story.id,
                        Provider.of<AuthService>(context, listen: false).currentUser!.id,
                      );
                    },
                  ),
                );
              }),
              // Mock friends
              ..._mockFriends.asMap().entries.map((entry) {
                final index = entry.key;
                final mock = entry.value;
                final colors = _ringGradients[(stories.length + index + 1) % _ringGradients.length];
                return Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: _FriendStoryBubble(
                    name: mock.name,
                    imageUrl: mock.avatar,
                    initials: mock.name,
                    gradientColors: colors,
                    onTap: () {},
                  ),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }

}

// ─── Friend Story Bubble ──────────────────────────────────────────────────────

class _FriendStoryBubble extends StatelessWidget {
  final String name;
  final String? imageUrl;
  final String initials;
  final List<Color> gradientColors;
  final bool isMyStory;
  final bool isUploading;
  final VoidCallback onTap;

  const _FriendStoryBubble({
    required this.name,
    required this.imageUrl,
    required this.initials,
    required this.gradientColors,
    this.isMyStory = false,
    this.isUploading = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 72,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Ring + Avatar
            Container(
              width: 66,
              height: 66,
              padding: const EdgeInsets.all(2.5),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: gradientColors,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.black,
                  shape: BoxShape.circle,
                ),
                padding: const EdgeInsets.all(2),
                child: isUploading
                    ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                    : ClipOval(
                        child: isMyStory
                            ? Stack(
                                children: [
                                  AppAvatar(name: initials, size: 58, imageUrl: imageUrl, isCircle: true),
                                  Positioned(
                                    right: 0,
                                    bottom: 0,
                                    child: Container(
                                      width: 20,
                                      height: 20,
                                      decoration: const BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [Color(0xFFB14FFF), Color(0xFF6C63FF)],
                                        ),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.add, size: 13, color: Colors.white),
                                    ),
                                  ),
                                ],
                              )
                            : AppAvatar(name: initials, size: 58, imageUrl: imageUrl, isCircle: true),
                      ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.85),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Mock Story Data ──────────────────────────────────────────────────────────

class _MockStory {
  final String name;
  final String username;
  final String avatar;
  final String photo;
  final String time;
  final String views;
  final String likes;
  final String sound;
  const _MockStory({
    required this.name,
    required this.username,
    required this.avatar,
    required this.photo,
    required this.time,
    this.views = '0',
    this.likes = '0',
    this.sound = 'Original Sound',
  });
}

// ─── Discover Card ────────────────────────────────────────────────────────────

class _MockDiscoverCard extends StatelessWidget {
  final _MockStory mock;
  final int index;
  final List<StoryViewItem> allItems;

  const _MockDiscoverCard({required this.mock, required this.index, required this.allItems});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(context, PageRouteBuilder(
          pageBuilder: (_, __, ___) => StoryViewerScreen(
            stories: allItems,
            initialIndex: index,
          ),
          transitionsBuilder: (_, animation, __, child) => FadeTransition(opacity: animation, child: child),
          transitionDuration: const Duration(milliseconds: 220),
        ));
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.07),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Stack(
            children: [
              // Story image
              Positioned.fill(
                child: Image.network(
                  mock.photo,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: Colors.white.withOpacity(0.05),
                    child: Center(
                      child: Icon(Icons.image_outlined, color: Colors.white.withOpacity(0.2), size: 36),
                    ),
                  ),
                ),
              ),
              // Bottom gradient
              Positioned(
                left: 0, right: 0, bottom: 0,
                height: 90,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withOpacity(0.85),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              // User info at bottom
              Positioned(
                left: 10, right: 10, bottom: 10,
                child: Row(
                  children: [
                    ClipOval(
                      child: Image.network(
                        mock.avatar,
                        width: 28,
                        height: 28,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => CircleAvatar(
                          radius: 14,
                          backgroundColor: Colors.white24,
                          child: Text(
                            mock.name[0],
                            style: const TextStyle(color: Colors.white, fontSize: 11),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            mock.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            mock.time,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.6),
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
