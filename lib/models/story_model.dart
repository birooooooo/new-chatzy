enum StoryType {
  image,
  video,
  text,
}

class StoryModel {
  final String id;
  final String userId;
  final String userName;
  final String? userAvatar;
  final StoryType type;
  final String content;
  final String? caption;
  final DateTime createdAt;
  final DateTime expiresAt;
  final List<String> viewedBy;
  final List<String> reactions;
  final String? backgroundColor;
  final String? textColor;

  StoryModel({
    required this.id,
    required this.userId,
    required this.userName,
    this.userAvatar,
    this.type = StoryType.image,
    required this.content,
    this.caption,
    required this.createdAt,
    required this.expiresAt,
    this.viewedBy = const [],
    this.reactions = const [],
    this.backgroundColor,
    this.textColor,
  });

  bool get isExpired => DateTime.now().isAfter(expiresAt);
  int get viewCount => viewedBy.length;

  StoryModel copyWith({
    String? id,
    String? userId,
    String? userName,
    String? userAvatar,
    StoryType? type,
    String? content,
    String? caption,
    DateTime? createdAt,
    DateTime? expiresAt,
    List<String>? viewedBy,
    List<String>? reactions,
    String? backgroundColor,
    String? textColor,
  }) {
    return StoryModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userAvatar: userAvatar ?? this.userAvatar,
      type: type ?? this.type,
      content: content ?? this.content,
      caption: caption ?? this.caption,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      viewedBy: viewedBy ?? this.viewedBy,
      reactions: reactions ?? this.reactions,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      textColor: textColor ?? this.textColor,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'userName': userName,
      'userAvatar': userAvatar,
      'type': type.index,
      'content': content,
      'caption': caption,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'expiresAt': expiresAt.millisecondsSinceEpoch,
      'viewedBy': viewedBy,
      'reactions': reactions,
      'backgroundColor': backgroundColor,
      'textColor': textColor,
    };
  }

  factory StoryModel.fromMap(Map<String, dynamic> map, {String? id}) {
    return StoryModel(
      id: id ?? map['id'] ?? '',
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? '',
      userAvatar: map['userAvatar'],
      type: StoryType.values[map['type'] ?? 0],
      content: map['content'] ?? '',
      caption: map['caption'],
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] ?? 0),
      expiresAt: DateTime.fromMillisecondsSinceEpoch(map['expiresAt'] ?? 0),
      viewedBy: List<String>.from(map['viewedBy'] ?? []),
      reactions: List<String>.from(map['reactions'] ?? []),
      backgroundColor: map['backgroundColor'],
      textColor: map['textColor'],
    );
  }
}
