class UserModel {
  final String id;
  final String name;
  final String email;
  final String? avatar;
  final String? bio;
  final String? phone;
  final bool isOnline;
  final DateTime? lastSeen;
  final bool isBlocked;
  final String? customNickname;
  final bool isMuted;
  final String? username;
  final List<String> searchKeywords;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.avatar,
    this.bio,
    this.phone,
    this.isOnline = false,
    this.lastSeen,
    this.isBlocked = false,
    this.customNickname,
    this.isMuted = false,
    this.username,
    this.searchKeywords = const [],
  });

  String get displayName => customNickname ?? name;

  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    String? avatar,
    String? bio,
    String? phone,
    bool? isOnline,
    DateTime? lastSeen,
    bool? isBlocked,
    String? customNickname,
    bool? isMuted,
    String? username,
    List<String>? searchKeywords,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      avatar: avatar ?? this.avatar,
      bio: bio ?? this.bio,
      phone: phone ?? this.phone,
      isOnline: isOnline ?? this.isOnline,
      lastSeen: lastSeen ?? this.lastSeen,
      isBlocked: isBlocked ?? this.isBlocked,
      customNickname: customNickname ?? this.customNickname,
      isMuted: isMuted ?? this.isMuted,
      username: username ?? this.username,
      searchKeywords: searchKeywords ?? this.searchKeywords,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'avatar': avatar,
      'bio': bio,
      'phone': phone,
      'isOnline': isOnline ? 1 : 0,
      'lastSeen': lastSeen?.toIso8601String(),
      'isBlocked': isBlocked ? 1 : 0,
      'customNickname': customNickname,
      'isMuted': isMuted ? 1 : 0,
      'username': username,
      'searchKeywords': searchKeywords,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'],
      name: map['name'],
      email: map['email'],
      avatar: map['avatar'],
      bio: map['bio'],
      phone: map['phone'],
      isOnline: map['isOnline'] == 1,
      lastSeen: map['lastSeen'] != null ? DateTime.parse(map['lastSeen']) : null,
      isBlocked: map['isBlocked'] == 1,
      customNickname: map['customNickname'],
      isMuted: map['isMuted'] == 1,
      username: map['username'],
      searchKeywords: List<String>.from(map['searchKeywords'] ?? []),
    );
  }
}
