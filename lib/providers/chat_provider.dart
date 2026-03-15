import 'dart:async';
import 'package:flutter/material.dart';
import '../models/chat_model.dart';
import '../models/message_model.dart';
import '../models/user_model.dart';
import 'dart:io';
import '../services/database_service.dart';
import '../services/firestore_service.dart';
import '../services/firebase_storage_service.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';

class ChatProvider extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  final FirebaseStorageService _storageService = FirebaseStorageService();
  final AuthService _authService = AuthService();
  final UserService _userService = UserService();
  final List<ChatModel> _chats = [];
  final Map<String, List<MessageModel>> _messages = {};
  final Map<String, bool> _typingStatuses = {};
  
  StreamSubscription? _chatsSubscription;
  final Map<String, StreamSubscription> _messageSubscriptions = {};
  
  bool _isInitialized = false;
  String? _currentUserId;
  
  String? get currentUserId => _currentUserId;
  UserModel? _currentUserProfile;
  UserModel? get currentUserProfile => _currentUserProfile;

  List<ChatModel> get chats => List.unmodifiable(_chats);
  

  ChatProvider() {
    _loadFromLocalDb();
  }

  /// Initialize with Firebase user ID for real-time sync
  void initialize(String userId) {
    if (_isInitialized && _currentUserId == userId) return;
    
    _currentUserId = userId;
    _isInitialized = true;
    
    debugPrint('ChatProvider: Initializing with user ID: $userId');
    _authService.seedTestUsers(); // Seed test users for testing
    
    // Fetch full user profile from Firestore
    _userService.getUser(userId).then((profile) {
      if (profile != null) {
        _currentUserProfile = profile;
        notifyListeners();
      }
    });

    // Subscribe to user's chats from Firestore
    _chatsSubscription = _firestoreService.getUserChats(userId).listen(
      (firestoreChats) {
        debugPrint('ChatProvider: Received ${firestoreChats.length} chats from Firestore');
        _chats.clear();
        if (firestoreChats.isNotEmpty) {
          _chats.addAll(firestoreChats);
          
          // Sort locally by updatedAt descending (backup: createdAt)
          _chats.sort((a, b) {
            final timeA = a.updatedAt ?? a.createdAt ?? DateTime(2000);
            final timeB = b.updatedAt ?? b.createdAt ?? DateTime(2000);
            return timeB.compareTo(timeA);
          });
          
          // Save to local database for offline access
          for (var chat in firestoreChats) {
            DatabaseService.saveChat(chat);
          }
        }
        notifyListeners();
      },
      onError: (error) {
        debugPrint('ChatProvider: Error loading chats from Firestore: $error');
        // Keep using dummy data or local cache on error
      },
    );
  }

  /// Subscribe to messages for a specific chat
  void subscribeToMessages(String chatId) {
    if (_messageSubscriptions.containsKey(chatId)) return;
    
    debugPrint('ChatProvider: Subscribing to messages for chat: $chatId');
    
    _messageSubscriptions[chatId] = _firestoreService
        .getChatMessages(chatId)
        .listen((firestoreMessages) {
      if (firestoreMessages.isNotEmpty) {
        debugPrint('ChatProvider: Loaded ${firestoreMessages.length} messages for chat $chatId');
        _messages[chatId] = firestoreMessages;
        
        // Save to local DB
        for (var msg in firestoreMessages) {
          DatabaseService.saveMessage(msg);
        }
        
        notifyListeners();
      }
    }, onError: (error) {
      debugPrint('ChatProvider: Error loading messages: $error');
    });
  }

  /// Unsubscribe from messages when leaving a chat
  void unsubscribeFromMessages(String chatId) {
    if (_messageSubscriptions.containsKey(chatId)) {
      _messageSubscriptions[chatId]?.cancel();
      _messageSubscriptions.remove(chatId);
      debugPrint('ChatProvider: Unsubscribed from messages for chat: $chatId');
    }
  }

  Future<void> _loadFromLocalDb() async {
    final localChats = await DatabaseService.getChats();
    if (localChats.isNotEmpty) {
      debugPrint('ChatProvider: Loaded ${localChats.length} chats from local DB');
      // Logic to merge or replace dummy data with local cache
      // For now, let's just log or partially populate
    }
  }



  List<MessageModel> getMessages(String chatId) {
    return _messages[chatId] ?? [];
  }

  bool isTyping(String chatId) {
    // Check if the OTHER person is typing (synced via Firestore chat stream)
    final chatIndex = _chats.indexWhere((c) => c.id == chatId);
    if (chatIndex != -1) {
      final chat = _chats[chatIndex];
      if (chat.typingUserId != null && chat.typingUserId != _currentUserId) {
        return true;
      }
    }
    return false;
  }

  void setTypingStatus(String chatId, bool isTyping) {
    if (_typingStatuses[chatId] == isTyping) return;
    _typingStatuses[chatId] = isTyping;
    // Local notify not strictly needed if we wait for Firestore, but feels faster
    notifyListeners();
    
    if (_isInitialized && _currentUserId != null) {
      _firestoreService.updateTypingStatus(chatId, _currentUserId!, isTyping);
    }
  }

  void addReaction(String chatId, String messageId, String emoji) {
    final msgs = _messages[chatId];
    if (msgs != null) {
      final index = msgs.indexWhere((m) => m.id == messageId);
      if (index != -1) {
        final userId = _currentUserId ?? 'me';
        final currentReactions = Map<String, String>.from(msgs[index].reactions ?? {});
        
        if (currentReactions[userId] == emoji) {
          currentReactions.remove(userId); // Remove if already exists
        } else {
          currentReactions[userId] = emoji; // Add or update
        }
        
        msgs[index] = msgs[index].copyWith(reactions: currentReactions);
        
        // Sync to Firestore
        if (_isInitialized && _currentUserId != null) {
          _firestoreService.addReaction(chatId, messageId, _currentUserId!, emoji);
        }
        
        notifyListeners();
      }
    }
  }

  void addMessage(String chatId, String content, {
    String? senderId,
    MessageType type = MessageType.text,
    String? replyToId,
  }) async {
    final effectiveSenderId = senderId ?? _currentUserId ?? 'me';
    final messageId = DateTime.now().millisecondsSinceEpoch.toString();
    
    // 1. Create initial message (potentially with local file path)
    var message = MessageModel(
      id: messageId,
      chatId: chatId,
      senderId: effectiveSenderId,
      content: content,
      type: type,
      status: MessageStatus.sending, // Initially sending
      timestamp: DateTime.now(),
      replyToId: replyToId,
    );

    // 2. Optimistic Update: Add to local state immediately
    if (!_messages.containsKey(chatId)) {
      _messages[chatId] = [];
    }
    _messages[chatId]!.insert(0, message);

    // Update last message in chat list
    final chatIndex = _chats.indexWhere((c) => c.id == chatId);
    if (chatIndex != -1) {
      _chats[chatIndex] = _chats[chatIndex].copyWith(lastMessage: message);
    }

    notifyListeners();

    // 3. Handle File Upload (if needed)
    if (_isInitialized && _currentUserId != null) {
      bool isMedia = type == MessageType.image || type == MessageType.video || type == MessageType.audio || type == MessageType.file;
      bool isLocalFile = !content.startsWith('http') && !content.startsWith('assets');
      
      if (isMedia && isLocalFile) {
        final file = File(content);
        if (file.existsSync()) {
          debugPrint('ChatProvider: Uploading file: $content');
          String? downloadUrl;
          if (type == MessageType.audio) {
            downloadUrl = await _storageService.uploadChatAudio(file, chatId);
          } else {
            downloadUrl = await _storageService.uploadChatImage(file, chatId);
          }
          
          if (downloadUrl != null) {
            debugPrint('ChatProvider: Upload success: $downloadUrl');
            // Update message with URL
            message = message.copyWith(content: downloadUrl);
            
            // Update local state with URL
            final msgIndex = _messages[chatId]!.indexWhere((m) => m.id == messageId);
            if (msgIndex != -1) {
              _messages[chatId]![msgIndex] = message;
            }
          } else {
            debugPrint('ChatProvider: File upload failed');
            message.status = MessageStatus.failed;
            notifyListeners();
            return; // Stop processing
          }
        }
      }
    }

    // 4. Save to Local DB (with URL if uploaded)
    await DatabaseService.saveMessage(message);

    // 5. Sync with Firestore
    if (_isInitialized) {
      try {
        // Update status to sent before sending
        message.status = MessageStatus.sent;
        
        // Update local state status
        final msgIndex = _messages[chatId]!.indexWhere((m) => m.id == messageId);
        if (msgIndex != -1) {
          _messages[chatId]![msgIndex] = message;
        }
        notifyListeners();
        
        await _firestoreService.sendMessage(chatId, message);
        debugPrint('ChatProvider: Message synced to Firestore');
      } catch (e) {
        debugPrint('ChatProvider: Failed to sync message to Firestore: $e');
        // Mark message as pending
        message.status = MessageStatus.pending;
        
        // Update local
        final msgIndex = _messages[chatId]!.indexWhere((m) => m.id == messageId);
        if (msgIndex != -1) {
          _messages[chatId]![msgIndex] = message;
        }
        notifyListeners();
        
        // Save pending status to local DB
        await DatabaseService.saveMessage(message);
      }
    }
  }

  Future<String> createChat(List<UserModel> otherParticipants) async {
    if (_currentUserId == null) throw Exception("User not logged in");
    
    // Construct current user model using profile or fallback
    final me = _currentUserProfile ?? UserModel(
      id: _currentUserId!,
      name: 'User', // Fallback
      email: '',
    );
    
    final allParticipants = [me, ...otherParticipants];
    // Ensure "Me" is not duplicated if already in list (unlikely but safe)
    final uniqueParticipants = {for (var p in allParticipants) p.id: p}.values.toList();
    
    final newChat = ChatModel(
      id: '', // Generated by Firestore
      name: otherParticipants.map((u) => u.name).join(', '),
      type: otherParticipants.length > 1 ? ChatType.group : ChatType.private,
      participants: uniqueParticipants,
      unreadCount: 0,
      createdAt: DateTime.now(),
      adminIds: [_currentUserId!],
    );

    final chatId = await _firestoreService.createChat(newChat);
    return chatId;
  }

  Future<void> deleteChat(String chatId) async {
    try {
      // 1. Delete from Firestore
      if (_isInitialized) {
        await _firestoreService.deleteChat(chatId);
      }
      
      // 2. Delete from Local DB
      await DatabaseService.deleteChat(chatId);
      
      // 3. Update local state
      _chats.removeWhere((c) => c.id == chatId);
      _messages.remove(chatId);
      _typingStatuses.remove(chatId);
      
      notifyListeners();
      debugPrint('ChatProvider: Chat $chatId deleted successfully');
    } catch (e) {
      debugPrint('ChatProvider: Error deleting chat: $e');
      rethrow;
    }
  }

  String getAllChatsContext() {
    StringBuffer context = StringBuffer();
    context.writeln("User's Conversation History Context:");
    
    for (var chat in _chats) {
      if (chat.type == ChatType.ai) continue;
      
      context.writeln("\nChat with ${chat.name}:");
      final msgs = _messages[chat.id] ?? [];
      // Get last 5 messages for context
      final latestMsgs = msgs.reversed.toList();
      final contextMsgs = latestMsgs.length > 5 ? latestMsgs.sublist(latestMsgs.length - 5) : latestMsgs;
      
      for (var msg in contextMsgs) {
        final sender = msg.senderId == 'me' ? 'User' : chat.name;
        context.writeln("- $sender: ${msg.content}");
      }
    }
    
    if (context.length < 50) {
      return "No recent conversations found.";
    }
    
    return context.toString();
  }

  @override
  void dispose() {
    _chatsSubscription?.cancel();
    _messageSubscriptions.values.forEach((sub) => sub.cancel());
    super.dispose();
  }
}
