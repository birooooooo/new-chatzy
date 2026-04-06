import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/chat_model.dart';
import '../models/message_model.dart';

/// Service for managing Firestore operations for chats and messages
class FirestoreService {
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;
  
  // ===== CHAT OPERATIONS =====
  
  /// Get user's chats as a real-time stream
  Stream<List<ChatModel>> getUserChats(String userId) {
    return _firestore
        .collection('chats')
        .where('participantIds', arrayContains: userId)
        .snapshots()
        .map((snapshot) {
          try {
            return snapshot.docs
                .map((doc) => ChatModel.fromFirestore(doc))
                .toList();
          } catch (e) {
            debugPrint('Error parsing chats: $e');
            return <ChatModel>[];
          }
        });
  }
  
  /// Create a new chat
  Future<String> createChat(ChatModel chat) async {
    try {
      final docRef = await _firestore.collection('chats').add(chat.toFirestore());
      return docRef.id;
    } catch (e) {
      debugPrint('Error creating chat: $e');
      rethrow;
    }
  }
  
  /// Update chat (last message, unread count, etc.)
  Future<void> updateChat(String chatId, Map<String, dynamic> updates) async {
    try {
      await _firestore.collection('chats').doc(chatId).update(updates);
    } catch (e) {
      debugPrint('Error updating chat: $e');
      rethrow;
    }
  }
  
  /// Delete a chat
  Future<void> deleteChat(String chatId) async {
    try {
      await _firestore.collection('chats').doc(chatId).delete();
    } catch (e) {
      debugPrint('Error deleting chat: $e');
      rethrow;
    }
  }
  
  // ===== MESSAGE OPERATIONS =====
  
  /// Get messages for a chat as real-time stream
  Stream<List<MessageModel>> getChatMessages(String chatId) {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .limit(100) // Limit for performance
        .snapshots()
        .map((snapshot) {
          try {
            return snapshot.docs
                .map((doc) => MessageModel.fromFirestore(doc))
                .toList();
          } catch (e) {
            debugPrint('Error parsing messages: $e');
            return <MessageModel>[];
          }
        });
  }
  
  /// Send a message
  Future<void> sendMessage(String chatId, MessageModel message, {List<String> otherParticipantIds = const []}) async {
    try {
      final batch = _firestore.batch();

      // Add message
      final messageRef = _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .doc(message.id);
      batch.set(messageRef, message.toFirestore());

      // Build unread count increments for all other participants
      final Map<String, dynamic> unreadIncrements = {};
      for (final uid in otherParticipantIds) {
        if (uid != message.senderId) {
          unreadIncrements['unreadCount.$uid'] = FieldValue.increment(1);
        }
      }

      // Update chat's last message, timestamp, and unread counts
      final chatRef = _firestore.collection('chats').doc(chatId);
      batch.set(chatRef, {
        'lastMessage': message.toMap(),
        'updatedAt': FieldValue.serverTimestamp(),
        ...unreadIncrements,
      }, SetOptions(merge: true));

      await batch.commit();
    } catch (e) {
      debugPrint('Error sending message: $e');
      rethrow;
    }
  }
  
  /// Update message (for editing)
  Future<void> updateMessage(String chatId, String messageId, String newContent) async {
    try {
      await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .doc(messageId)
          .update({
        'content': newContent,
        'isEdited': true,
      });
    } catch (e) {
      debugPrint('Error updating message: $e');
      rethrow;
    }
  }
  
  /// Delete message
  Future<void> deleteMessage(String chatId, String messageId) async {
    try {
      await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .doc(messageId)
          .delete();
    } catch (e) {
      debugPrint('Error deleting message: $e');
      rethrow;
    }
  }
  
  /// Add reaction to message
  Future<void> addReaction(String chatId, String messageId, String userId, String emoji) async {
    try {
      await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .doc(messageId)
          .update({
        'reactions.$userId': emoji,
      });
    } catch (e) {
      debugPrint('Error adding reaction: $e');
      rethrow;
    }
  }
  
  /// Remove reaction from message
  Future<void> removeReaction(String chatId, String messageId, String userId) async {
    try {
      await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .doc(messageId)
          .update({
        'reactions.$userId': FieldValue.delete(),
      });
    } catch (e) {
      debugPrint('Error removing reaction: $e');
      rethrow;
    }
  }
  
  /// Mark messages as read
  Future<void> markMessagesAsRead(String chatId, String userId) async {
    try {
      await _firestore.collection('chats').doc(chatId).update({
        'unreadCount.$userId': 0,
      });
    } catch (e) {
      debugPrint('Error marking messages as read: $e');
      rethrow;
    }
  }

  /// Update the status of a specific message
  Future<void> updateMessageStatus(String chatId, String messageId, MessageStatus status) async {
    try {
      await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .doc(messageId)
          .update({
        'status': status.index,
      });
    } catch (e) {
      debugPrint('Error updating message status: $e');
      rethrow;
    }
  }

  /// Update typing status for a user in a chat
  Future<void> updateTypingStatus(String chatId, String userId, bool isTyping) async {
    try {
      await _firestore.collection('chats').doc(chatId).update({
        'typingUserId': isTyping ? userId : null,
      });
    } catch (e) {
      debugPrint('Error updating typing status: $e');
    }
  }
}
