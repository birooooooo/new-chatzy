import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';

enum MessageType {
  text,
  image,
  video,
  audio,
  file,
  sticker,
  aiSuggestion,
  translated,
}

enum MessageStatus {
  sending,
  sent,
  delivered,
  read,
  failed,
  pending,
}

class MessageModel {
  final String id;
  final String chatId;
  final String senderId;
  final String content;
  final MessageType type;
  MessageStatus status;
  final DateTime timestamp;
  final String? replyToId;
  final String? translatedContent;
  final String? translatedLanguage;
  final String? aiSuggestion;
  final Map<String, String> reactions; // Changed from List<String> to Map for userId->emoji

  MessageModel({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.content,
    this.type = MessageType.text,
    this.status = MessageStatus.sent,
    required this.timestamp,
    this.replyToId,
    this.translatedContent,
    this.translatedLanguage,
    this.aiSuggestion,
    Map<String, String>? reactions,
  }) : reactions = reactions ?? {};

  bool get isTranslated => translatedContent != null;

  MessageModel copyWith({
    String? id,
    String? chatId,
    String? senderId,
    String? content,
    MessageType? type,
    MessageStatus? status,
    DateTime? timestamp,
    String? replyToId,
    String? translatedContent,
    String? translatedLanguage,
    String? aiSuggestion,
    Map<String, String>? reactions,
  }) {
    return MessageModel(
      id: id ?? this.id,
      chatId: chatId ?? this.chatId,
      senderId: senderId ?? this.senderId,
      content: content ?? this.content,
      type: type ?? this.type,
      status: status ?? this.status,
      timestamp: timestamp ?? this.timestamp,
      replyToId: replyToId ?? this.replyToId,
      translatedContent: translatedContent ?? this.translatedContent,
      translatedLanguage: translatedLanguage ?? this.translatedLanguage,
      aiSuggestion: aiSuggestion ?? this.aiSuggestion,
      reactions: reactions ?? this.reactions,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'chatId': chatId,
      'senderId': senderId,
      'content': content,
      'type': type.index,
      'status': status.index,
      'timestamp': timestamp.toIso8601String(),
      'replyToId': replyToId,
      'translatedContent': translatedContent,
      'translatedLanguage': translatedLanguage,
      'aiSuggestion': aiSuggestion,
      'reactions': jsonEncode(reactions),
    };
  }

  factory MessageModel.fromMap(Map<String, dynamic> map) {
    return MessageModel(
      id: map['id'] ?? '',
      chatId: map['chatId'] ?? '',
      senderId: map['senderId'] ?? '',
      content: map['content'] ?? '',
      type: MessageType.values[map['type'] ?? 0],
      status: MessageStatus.values[map['status'] ?? 1],
      timestamp: map['timestamp'] is String 
          ? DateTime.parse(map['timestamp'])
          : DateTime.now(),
      replyToId: map['replyToId'],
      translatedContent: map['translatedContent'],
      translatedLanguage: map['translatedLanguage'],
      aiSuggestion: map['aiSuggestion'],
      reactions: map['reactions'] != null 
          ? (map['reactions'] is String 
              ? Map<String, String>.from(jsonDecode(map['reactions']))
              : Map<String, String>.from(map['reactions']))
          : {},
    );
  }

  // Firestore serialization
  Map<String, dynamic> toFirestore() {
    return {
      'chatId': chatId,
      'senderId': senderId,
      'content': content,
      'type': type.index,
      'status': status.index,
      'timestamp': Timestamp.fromDate(timestamp),
      'replyToId': replyToId,
      'translatedContent': translatedContent,
      'translatedLanguage': translatedLanguage,
      'aiSuggestion': aiSuggestion,
      'reactions': reactions,
    };
  }

  factory MessageModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MessageModel(
      id: doc.id,
      chatId: data['chatId'] ?? '',
      senderId: data['senderId'] ?? '',
      content: data['content'] ?? '',
      type: MessageType.values[data['type'] ?? 0],
      status: MessageStatus.values[data['status'] ?? 1],
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      replyToId: data['replyToId'],
      translatedContent: data['translatedContent'],
      translatedLanguage: data['translatedLanguage'],
      aiSuggestion: data['aiSuggestion'],
      reactions: Map<String, String>.from(data['reactions'] ?? {}),
    );
  }
}
