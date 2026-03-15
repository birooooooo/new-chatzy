import 'package:flutter/material.dart';
import '../models/story_model.dart';

/// Manages the list of active stories in the app.
/// In a production app, this would stream data from Firestore via StoryService.
/// For now, it operates with an in-memory list that can be updated when:
/// - A user uploads a story (from StoriesFeedScreen)
/// - Stories expire (24h timer)
class StoryProvider extends ChangeNotifier {
  final List<StoryModel> _stories = [];

  List<StoryModel> get stories => List.unmodifiable(
    _stories.where((s) => !s.isExpired).toList()
  );

  /// Groups stories by userId so we show one circle per person.
  List<StoryModel> get latestPerUser {
    final Map<String, StoryModel> byUser = {};
    for (final story in stories) {
      final existing = byUser[story.userId];
      if (existing == null || story.createdAt.isAfter(existing.createdAt)) {
        byUser[story.userId] = story;
      }
    }
    return byUser.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  bool hasUserPostedStory(String userId) {
    return stories.any((s) => s.userId == userId);
  }

  /// Call this when a user posts a story (from StoriesFeedScreen).
  void addStory(StoryModel story) {
    _stories.add(story);
    notifyListeners();
  }

  /// Call this to mark a story as viewed.
  void markViewed(String storyId, String viewerId) {
    final index = _stories.indexWhere((s) => s.id == storyId);
    if (index != -1) {
      final story = _stories[index];
      if (!story.viewedBy.contains(viewerId)) {
        _stories[index] = story.copyWith(
          viewedBy: [...story.viewedBy, viewerId],
        );
        notifyListeners();
      }
    }
  }

  bool isViewed(String storyId, String currentUserId) {
    final story = _stories.firstWhere(
      (s) => s.id == storyId,
      orElse: () => StoryModel(
        id: '',
        userId: '',
        userName: '',
        content: '',
        createdAt: DateTime.now(),
        expiresAt: DateTime.now(),
      ),
    );
    return story.viewedBy.contains(currentUserId);
  }

  /// Seed some demo stories so the tray is visible during development.
  void seedDemoStories() {
    if (_stories.isNotEmpty) return;
    final now = DateTime.now();
    _stories.addAll([
      StoryModel(
        id: 'story_sarah',
        userId: 'sarah_wilson',
        userName: 'Sarah Wilson',
        userAvatar: 'https://i.pravatar.cc/300?u=SarahWilson',
        type: StoryType.image,
        content: 'https://picsum.photos/seed/sarah/400/700',
        caption: 'Good morning! ☀️',
        createdAt: now.subtract(const Duration(hours: 1)),
        expiresAt: now.add(const Duration(hours: 23)),
      ),
      StoryModel(
        id: 'story_alex',
        userId: 'alex_thompson',
        userName: 'Alex Thompson',
        userAvatar: 'https://i.pravatar.cc/300?u=AlexThompson',
        type: StoryType.image,
        content: 'https://picsum.photos/seed/alex/400/700',
        caption: 'Meeting went great!',
        createdAt: now.subtract(const Duration(hours: 3)),
        expiresAt: now.add(const Duration(hours: 21)),
      ),
      StoryModel(
        id: 'story_jordan',
        userId: 'user_1',
        userName: 'Jordan Smith',
        userAvatar: 'https://i.pravatar.cc/300?u=JordanSmith',
        type: StoryType.image,
        content: 'https://picsum.photos/seed/jordan/400/700',
        createdAt: now.subtract(const Duration(hours: 5)),
        expiresAt: now.add(const Duration(hours: 19)),
      ),
    ]);
    notifyListeners();
  }
}
