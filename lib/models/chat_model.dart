import 'user_model.dart';
import 'message_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

enum ChatType {
  private,
  group,
  ai,
}

class ChatModel {
  final String id;
  final String name;
  final ChatType type;
  final List<UserModel> participants;
  final MessageModel? lastMessage;
  final Map<String, dynamic> unreadCounts; // Changed from int to Map for per-user tracking
  final bool isPinned;
  final bool isMuted;
  final String? avatar;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final bool isTyping;
  final String? typingUserId;
  final List<String> adminIds;

  ChatModel({
    required this.id,
    required this.name,
    this.type = ChatType.private,
    required this.participants,
    this.lastMessage,
    this.unreadCounts = const {}, // Changed default
    this.isPinned = false,
    this.isMuted = false,
    this.avatar,
    this.createdAt,
    this.updatedAt,
    this.isTyping = false,
    this.typingUserId,
    this.adminIds = const [],
  });

  // Getter for total or individual unread count
  int getUnreadCount(String? userId) {
    if (userId == null) return 0;
    final count = unreadCounts[userId];
    if (count is int) return count;
    return 0;
  }

  bool get isGroup => type == ChatType.group;
  bool get isAI => type == ChatType.ai;
  List<String> get participantIds => participants.map((u) => u.id).toList();

  String getDisplayName(String currentUserId) {
    if (type == ChatType.private) {
      final otherUser = participants.firstWhere(
        (u) => u.id != currentUserId,
        orElse: () => participants.isNotEmpty ? participants.first : UserModel(id: '', name: 'User', email: ''),
      );
      return otherUser.name;
    }
    return name;
  }

  String? getDisplayAvatar(String currentUserId) {
    if (type == ChatType.private) {
      final otherUser = participants.firstWhere(
        (u) => u.id != currentUserId,
        orElse: () => participants.isNotEmpty ? participants.first : UserModel(id: '', name: 'User', email: ''),
      );
      return otherUser.avatar;
    }
    return avatar;
  }

  ChatModel copyWith({
    String? id,
    String? name,
    ChatType? type,
    List<UserModel>? participants,
    MessageModel? lastMessage,
    Map<String, dynamic>? unreadCounts, // Updated
    bool? isPinned,
    bool? isMuted,
    String? avatar,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isTyping,
    String? typingUserId,
    List<String>? adminIds,
  }) {
    return ChatModel(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      participants: participants ?? this.participants,
      lastMessage: lastMessage ?? this.lastMessage,
      unreadCounts: unreadCounts ?? this.unreadCounts, // Updated
      isPinned: isPinned ?? this.isPinned,
      isMuted: isMuted ?? this.isMuted,
      avatar: avatar ?? this.avatar,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isTyping: isTyping ?? this.isTyping,
      typingUserId: typingUserId ?? this.typingUserId,
      adminIds: adminIds ?? this.adminIds,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type.index,
      'avatar': avatar,
      'unreadCounts': unreadCounts, // Updated
      'isPinned': isPinned ? 1 : 0,
      'isMuted': isMuted ? 1 : 0,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'typingUserId': typingUserId,
      'adminIds': adminIds.join(','),
    };
  }

  factory ChatModel.fromMap(Map<String, dynamic> map, List<UserModel> participants, MessageModel? lastMessage) {
    return ChatModel(
      id: map['id'],
      name: map['name'],
      type: ChatType.values[map['type'] ?? 0],
      participants: participants,
      lastMessage: lastMessage,
      unreadCounts: (map['unreadCounts'] as Map?)?.cast<String, dynamic>() ?? {}, // Updated
      isPinned: map['isPinned'] == 1,
      isMuted: map['isMuted'] == 1,
      avatar: map['avatar'],
      createdAt: map['createdAt'] != null ? DateTime.parse(map['createdAt']) : null,
      updatedAt: map['updatedAt'] != null ? DateTime.parse(map['updatedAt']) : null,
      typingUserId: map['typingUserId'],
      adminIds: map['adminIds'] != null && (map['adminIds'] as String).isNotEmpty 
          ? (map['adminIds'] as String).split(',') 
          : [],
    );
  }

  // Firestore serialization
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'type': type.index,
      'avatar': avatar,
      'participants': participants.map((p) => p.toMap()).toList(),
      'participantIds': participants.map((p) => p.id).toList(), // For queries
      'unreadCount': unreadCounts, // Keeping standard key used in marksMessagesAsRead
      'isPinned': isPinned,
      'isMuted': isMuted,
      'lastMessage': lastMessage?.toMap(),
      'typingUserId': typingUserId,
      'adminIds': adminIds,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  factory ChatModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ChatModel(
      id: doc.id,
      name: data['name'] ?? '',
      type: ChatType.values[data['type'] ?? 0],
      avatar: data['avatar'],
      participants: (data['participants'] as List?)
          ?.map((p) => UserModel.fromMap(p as Map<String, dynamic>))
          .toList() ?? [],
      unreadCounts: data['unreadCount'] is Map ? (data['unreadCount'] as Map).cast<String, dynamic>() : {},
      isPinned: data['isPinned'] ?? false,
      isMuted: data['isMuted'] ?? false,
      lastMessage: data['lastMessage'] != null 
          ? MessageModel.fromMap(data['lastMessage'] as Map<String, dynamic>) 
          : null,
      createdAt: data['createdAt'] is Timestamp 
          ? (data['createdAt'] as Timestamp).toDate()
          : null,
      updatedAt: data['updatedAt'] is Timestamp 
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
      typingUserId: data['typingUserId'],
      adminIds: (data['adminIds'] as List?)?.cast<String>() ?? [],
    );
  }
}
