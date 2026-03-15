import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../theme/app_theme.dart';
import '../../widgets/glass_container.dart';
import '../../services/story_service.dart';
import '../../services/auth_service.dart';
import '../../providers/story_provider.dart';
import '../../models/story_model.dart';
import 'dart:ui';
import 'dart:io';

class StoriesFeedScreen extends StatefulWidget {
  const StoriesFeedScreen({super.key});

  @override
  State<StoriesFeedScreen> createState() => _StoriesFeedScreenState();
}

class _StoriesFeedScreenState extends State<StoriesFeedScreen> {
  final StoryService _storyService = StoryService();
  final ImagePicker _picker = ImagePicker();
  bool _isUploading = false;

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

        // Also add to local StoryProvider so the home tray updates instantly
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Stories',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  _buildAddStoryButton(),
                ],
              ),
            ),
          
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
              physics: const BouncingScrollPhysics(),
              children: [
                // My Story Section
                _buildMyStoryCard(context),
                
                const SizedBox(height: 28),
                
                // Stories Section
                const SizedBox(height: 24),
                _buildStoriesContent(context),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

  Widget _buildStoriesContent(BuildContext context) {
    return StreamBuilder<List<StoryModel>>(
      stream: _storyService.getActiveStories(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: Padding(
            padding: EdgeInsets.all(40.0),
            child: CircularProgressIndicator(),
          ));
        }

        final stories = snapshot.data ?? [];
        if (stories.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 40),
                GlassContainer(
                  width: 90,
                  height: 90,
                  borderRadius: BorderRadius.circular(28),
                  blur: 20,
                  child: Icon(
                    Icons.auto_stories_outlined,
                    size: 40,
                    color: Colors.white.withOpacity(0.15),
                  ),
                ).animate()
                  .scale(duration: 600.ms, curve: Curves.easeOutBack)
                  .fadeIn(),
                const SizedBox(height: 24),
                const Text(
                  'Keep up with friends',
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
                    'Stories from your friends will appear here once they post something new.',
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

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Recent Stories',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ).animate().fadeIn(delay: 100.ms),
            const SizedBox(height: 16),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: ScreenSize.isMobile ? 2 : 4,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.7,
              ),
              itemCount: stories.length,
              itemBuilder: (context, index) {
                final story = stories[index];
                return _StoryCard(
                  story: story,
                  onTap: () {
                    _storyService.viewStory(story.id, Provider.of<AuthService>(context, listen: false).currentUser!.id);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Viewing ${story.userName}\'s story')),
                    );
                  },
                ).animate()
                  .fadeIn(delay: Duration(milliseconds: 150 + (index * 50)))
                  .scale(begin: const Offset(0.9, 0.9), end: const Offset(1, 1));
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildAddStoryButton() {
    return GestureDetector(
      onTap: _pickAndUploadStory,
      child: GlassContainer(
        width: 44,
        height: 44,
        borderRadius: BorderRadius.circular(14),
        gradient: AppTheme.primaryGradient,
        child: _isUploading 
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 22),
      ),
    );
  }

  Widget _buildMyStoryCard(BuildContext context) {
    final user = Provider.of<AuthService>(context).currentUser;
    
    return GestureDetector(
      onTap: _pickAndUploadStory,
      child: GlassContainer(
        padding: const EdgeInsets.all(14),
        borderRadius: BorderRadius.circular(20),
        blur: 30,
        opacity: 0.1,
        border: Border.all(color: Colors.white.withOpacity(0.12), width: 0.8),
        child: Row(
          children: [
            Stack(
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: user?.avatar != null 
                      ? ClipOval(child: Image.network(user!.avatar!, fit: BoxFit.cover))
                      : const Icon(Icons.person, size: 28, color: Colors.white),
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: const BoxDecoration(
                      color: AppTheme.secondary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.add, size: 14, color: Colors.white),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'My Story',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _isUploading ? 'Uploading...' : 'Tap to add your story',
                    style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 300.ms);
  }

  Widget _buildMutedStoriesSection(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Muted Stories',
          style: TextStyle(
            color: Colors.white.withOpacity(0.5),
            fontSize: 14,
          ),
        ),
        TextButton(
          onPressed: () {},
          child: const Text('Show', style: TextStyle(color: AppTheme.secondary)),
        ),
      ],
    ).animate().fadeIn(delay: 600.ms, duration: 300.ms);
  }
}

class _StoryCard extends StatelessWidget {
  final StoryModel story;
  final VoidCallback onTap;

  const _StoryCard({
    required this.story,
    required this.onTap,
  });

  String _formatTime(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    return '${diff.inDays}d';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: AppTheme.borderRadiusMedium,
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Stack(
          children: [
            // Story content image
            Positioned.fill(
              child: ClipRRect(
                borderRadius: AppTheme.borderRadiusMedium,
                child: Image.network(
                  story.content,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Center(
                    child: Icon(Icons.broken_image, color: Colors.white.withOpacity(0.2)),
                  ),
                ),
              ),
            ),
            // Gradient overlay
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: AppTheme.borderRadiusMedium,
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.7),
                    ],
                  ),
                ),
              ),
            ),
            // User info
            Positioned(
              top: 12,
              left: 12,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  shape: BoxShape.circle,
                ),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                  child: ClipOval(
                    child: story.userAvatar != null
                        ? Image.network(story.userAvatar!, fit: BoxFit.cover)
                        : Center(
                            child: Text(
                              story.userName[0],
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                  ),
                ),
              ),
            ),
            // Name and time
            Positioned(
              bottom: 12,
              left: 12,
              right: 12,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    story.userName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    _formatTime(story.createdAt),
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 10,
                    ),
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
