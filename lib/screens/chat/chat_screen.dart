import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:ui';
import 'dart:async';
import 'dart:io';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../models/message_model.dart';
import '../../services/ai_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/character_3d.dart';
import '../../widgets/real_3d_character.dart';
import '../../widgets/huggy_3d_character.dart';
import '../../widgets/glass_container.dart';
import '../../providers/character_provider.dart';
import '../../providers/chat_provider.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart'; // Added missing import
import 'chat_settings_screen.dart';
import '../profile/user_details_screen.dart';
import '../../widgets/voice_recorder.dart';
import '../../widgets/audio_message_bubble.dart';
import '../../widgets/swipe_to_reply.dart';
import '../../widgets/poll_widget.dart';
import '../../widgets/app_widgets.dart';

class ChatScreen extends StatefulWidget {
  final String chatId;
  final String chatName;
  final bool isOnline;
  final String? imageUrl;

  const ChatScreen({
    super.key,
    required this.chatId,
    required this.chatName,
    this.isOnline = false,
    this.imageUrl,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with TickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  
  bool _showSuggestions = false;
  bool _isTyping = false;
  String _partnerMood = 'happy';
  MessageModel? _replyingTo;
  bool _isRecording = false;
  bool _hasStartedChatting = false;
  
  final AiService _aiService = AiService();
  Timer? _debounceTimer;
  Timer? _resetTimer;
  
  // Messages now come from ChatProvider
  final List<String> _suggestions = [
    'Sounds great! 👍',
    'I\'ll check it out',
    'Thanks for sharing!',
    'Let me think about it',
    'Perfect, see you then!',
  ];

  @override
  void initState() {
    super.initState();
    _messageController.addListener(_onTextChanged);
    
    // Subscribe to real-time messages for this chat
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final chatProvider = Provider.of<ChatProvider>(context, listen: false);
      chatProvider.subscribeToMessages(widget.chatId, autoMarkAsRead: true);
      chatProvider.markMessagesAsRead(widget.chatId);
    });
  }

  ChatProvider? _chatProvider;
  bool _disposed = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _chatProvider ??= Provider.of<ChatProvider>(context, listen: false);
  }

  @override
  void deactivate() {
    // Unsubscribe BEFORE widgets are deactivated to prevent notifyListeners
    // from reaching Consumer widgets that are being torn down
    _chatProvider?.unsubscribeFromMessages(widget.chatId);
    _chatProvider?.setTypingStatus(widget.chatId, false);
    super.deactivate();
  }

  @override
  void dispose() {
    _disposed = true;
    _debounceTimer?.cancel();
    _resetTimer?.cancel();
    _messageController.removeListener(_onTextChanged);
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final text = _messageController.text;
    if (text.length >= 3 && !_showSuggestions) {
      _safeSetState(() => _showSuggestions = true);
    } else if (text.length < 3 && _showSuggestions) {
      _safeSetState(() => _showSuggestions = false);
    }
    _safeSetState(() => _isTyping = text.isNotEmpty);

    // Sync typing status with provider
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    chatProvider.setTypingStatus(widget.chatId, text.isNotEmpty);

    // Debounce AI Analysis
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
    if (text.isNotEmpty) {
      _debounceTimer = Timer(const Duration(milliseconds: 800), () {
        _analyzeMood(text);
      });
    }
  }

  void _safeSetState(VoidCallback fn) {
    if (!_disposed && mounted) setState(fn);
  }

  Future<void> _analyzeMood(String text) async {
    // Cancel any pending reset
    _resetTimer?.cancel();

    // Call AI Service
    String mood;
    if (text.toLowerCase().contains('kiss')) {
      mood = 'kiss';
    } else {
      mood = await _aiService.analyzeSentiment(text);
    }
    
    if (_disposed || !mounted) return;
    
    Provider.of<CharacterProvider>(context, listen: false).setMood(mood);

    // Auto-Reset to Neutral after 3 seconds if not already neutral
    if (mood != 'neutral') {
      _resetTimer = Timer(const Duration(seconds: 3), () {
        if (mounted) {
          Provider.of<CharacterProvider>(context, listen: false).setMood('neutral');
        }
      });
    }
  }

  Future<void> _showAiRecap() async {
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    final messages = chatProvider.getMessages(widget.chatId);
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        builder: (context, scrollController) => GlassContainer(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  const Icon(Icons.auto_awesome_rounded, color: AppTheme.secondary),
                  const SizedBox(width: 12),
                  Text(
                    'Conversation Recap', 
                    style: GoogleFonts.inter(
                      fontSize: 20, 
                      fontWeight: FontWeight.bold, 
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: FutureBuilder<String>(
                  future: _aiService.summarizeConversation(messages),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator(color: AppTheme.secondary));
                    }
                    return SingleChildScrollView(
                      controller: scrollController,
                      child: Text(
                        snapshot.data ?? 'Error generating summary',
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8), 
                            fontSize: 16, 
                            height: 1.6,
                          ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Got it!'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;

    if (!_hasStartedChatting) {
      _safeSetState(() => _hasStartedChatting = true);
    }

    // Trigger immediate analysis on send to capture the final sentiment
    _analyzeMood(_messageController.text);

    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    chatProvider.addMessage(
      widget.chatId, 
      _messageController.text, 
      replyToId: _replyingTo?.id,
    );

    // Reset typing status on send
    chatProvider.setTypingStatus(widget.chatId, false);

    _safeSetState(() {
      _showSuggestions = false;
      _replyingTo = null;
    });

    _messageController.clear();
    // No need to manual scroll to bottom with reverse: true! 
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'gif', 'pdf', 'doc', 'docx'],
        withData: kIsWeb, // On web we need bytes, not path
      );

      if (result == null) return;
      final file = result.files.single;
      final ext = file.extension?.toLowerCase() ?? '';
      final isImage = ['jpg', 'jpeg', 'png', 'gif'].contains(ext);
      final type = isImage ? MessageType.image : MessageType.file;

      final chatProvider = Provider.of<ChatProvider>(context, listen: false);

      if (kIsWeb) {
        // On web: upload bytes directly to Firebase Storage
        final bytes = file.bytes;
        if (bytes == null) return;
        final storageService = chatProvider.storageService;
        final url = await storageService.uploadChatImageBytes(
          bytes, widget.chatId, file.name,
        );
        if (url != null) {
          chatProvider.addMessage(widget.chatId, url, type: type);
        }
      } else {
        // On mobile/desktop: use file path
        final path = file.path;
        if (path == null) return;
        chatProvider.addMessage(widget.chatId, path, type: type);
      }

      if (_scrollController.hasClients) {
        _scrollController.animateTo(0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut);
      }
    } catch (e) {
      debugPrint('Error picking file: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to pick file')),
        );
      }
    }
  }

  void _useSuggestion(String suggestion) {
    _safeSetState(() {
      _messageController.text = suggestion;
      _messageController.selection = TextSelection.fromPosition(
        TextPosition(offset: suggestion.length),
      );
    });
    _focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(),
      body: Stack(
        children: [
          // Global Doodle Background
          Positioned.fill(
            child: Opacity(
              opacity: themeProvider.isLightTheme ? 0.15 : 0.08, // Subtle opacity for better contrast
              child: Image.asset(
                'assets/images/doodle_bg.jpg',
                fit: BoxFit.cover,
              ),
            ),
          ),
          
          // 3D Background Character
          _build3DCharacters(),
          
          // Gradient Overlay to blend characters into black
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: themeProvider.isLightTheme
                      ? [
                          Colors.white.withOpacity(0.2),
                          Colors.transparent,
                          Colors.white.withOpacity(0.4),
                        ]
                      : [
                          Colors.black.withOpacity(0.7),
                          Colors.transparent,
                          Colors.black.withOpacity(0.8),
                        ],
                  stops: const [0.0, 0.5, 0.9],
                ),
              ),
            ),
          ),

          // Main content
          Column(
            children: [
              Expanded(
                child: Consumer<ChatProvider>(
                  builder: (context, chatProvider, child) {
                    final messages = chatProvider.getMessages(widget.chatId);
                    return _buildMessagesList(messages);
                  },
                ),
              ),
              _buildInputArea(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _build3DCharacters() {
    return Positioned.fill(
      child: Center(
        child: Consumer<CharacterProvider>(
          builder: (context, charProvider, _) => Huggy3DCharacter(
            mood: charProvider.mood, // React to provider mood
            isChatting: _hasStartedChatting,
            size: 320,
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return PreferredSize(
      preferredSize: const Size.fromHeight(kToolbarHeight + 20), // Adjust height as needed
      child: GlassContainer(
        margin: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + 8,
          left: 6,
          right: 6,
        ),
        borderRadius: BorderRadius.circular(24),
        blur: 20,
        gradient: LinearGradient(
          colors: themeProvider.isLightTheme
              ? [Colors.white.withOpacity(0.9), Colors.white.withOpacity(0.7)]
              : [Colors.white.withOpacity(0.1), Colors.white.withOpacity(0.05)],
        ),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              IconButton(
                icon: Icon(
                  Icons.arrow_back_ios_new_rounded, 
                  size: 20, 
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                onPressed: () => Navigator.pop(context),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => UserDetailsScreen(
                        userName: widget.chatName,
                        isOnline: widget.isOnline,
                        imageUrl: widget.imageUrl,
                        chatId: widget.chatId,
                      ),
                    ),
                  );
                },
                child: Row(
                  children: [
                    AppAvatar(
                      name: widget.chatName,
                      size: 38,
                      imageUrl: widget.imageUrl,
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.chatName,
                          style: TextStyle(
                            fontWeight: FontWeight.w600, 
                            fontSize: 16, 
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        Consumer<ChatProvider>(
                          builder: (context, provider, _) {
                            final isTyping = provider.isTyping(widget.chatId);
                            if (isTyping) {
                              return Text(
                                'Typing...',
                                style: TextStyle(color: AppTheme.secondary, fontSize: 12, fontWeight: FontWeight.bold),
                              );
                            }
                            return widget.isOnline
                                ? Text(
                                    'Online',
                                    style: TextStyle(color: AppTheme.success, fontSize: 12),
                                  )
                                : const SizedBox.shrink();
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Spacer(),
              IconButton(
                icon: Icon(Icons.videocam_outlined, size: 22, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8)),
                onPressed: () {},
              ),
              IconButton(
                icon: Icon(Icons.call_outlined, size: 22, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8)),
                onPressed: () {},
              ),
              IconButton(
                icon: Icon(Icons.more_vert_rounded, size: 22, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8)),
                onPressed: () => _showStyleSettings(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMessagesList(List<MessageModel> messages) {
    return ListView.builder(
      controller: _scrollController,
      reverse: true,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 20),
      physics: const BouncingScrollPhysics(),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final chatProvider = Provider.of<ChatProvider>(context, listen: false);
        final message = messages[index];
        final isMe = message.senderId == (chatProvider.currentUserId ?? 'me');
        final isDeleted = false;
        final isEdited = false;
        final timeStr = DateFormat.jm().format(message.timestamp);

        // Grouping: reversed list → index+1 is older (above), index-1 is newer (below)
        final olderMsg = index + 1 < messages.length ? messages[index + 1] : null;
        final newerMsg = index - 1 >= 0 ? messages[index - 1] : null;

        bool _withinHour(MessageModel a, MessageModel b) =>
            a.timestamp.difference(b.timestamp).abs().inMinutes < 60;

        final isGroupedWithAbove = olderMsg != null &&
            olderMsg.senderId == message.senderId &&
            _withinHour(message, olderMsg);

        final isGroupedWithBelow = newerMsg != null &&
            newerMsg.senderId == message.senderId &&
            _withinHour(message, newerMsg);

        final replyMessage = message.replyToId != null
            ? messages.firstWhere(
                (m) => m.id == message.replyToId,
                orElse: () => MessageModel(
                    id: '', chatId: '', senderId: '', content: 'Deleted message', timestamp: DateTime.now()))
            : null;

        return SwipeToReply(
          onReply: () => _safeSetState(() => _replyingTo = message),
          child: GestureDetector(
            onLongPress: () => _showMessageActions(context, message),
            child: _GlassMessageBubble(
              text: isDeleted ? '🚫 This message was deleted' : message.content,
              isMe: isMe,
              time: timeStr,
              isEdited: isEdited,
              isDeleted: isDeleted,
              status: message.status,
              reactions: message.reactions,
              replyToContent: replyMessage?.content,
              replyToName: replyMessage != null
                  ? (replyMessage.senderId == 'me' ? 'Me' : widget.chatName)
                  : null,
              onReactionTap: (emoji) =>
                  chatProvider.addReaction(widget.chatId, message.id, emoji),
              type: message.type,
              filePath: (message.type == MessageType.image ||
                          message.type == MessageType.file) &&
                      !message.content.startsWith('http')
                  ? message.content
                  : null,
              isGroupedWithAbove: isGroupedWithAbove,
              isGroupedWithBelow: isGroupedWithBelow,
            ),
          ),
        ).animate().fadeIn(duration: 200.ms).slideY(begin: 0.1, end: 0);
      },
    );
  }

  void _showMessageActions(BuildContext context, MessageModel message) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => GlassContainer(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        blur: 25,
        gradient: LinearGradient(
          colors: [Colors.black.withOpacity(0.9), Colors.black.withOpacity(0.8)],
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Emoji Reactions Row
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: ['❤️', '😂', '😮', '😢', '😡', '👍', '🙏', '🔥'].map((emoji) {
                  return GestureDetector(
                    onTap: () {
                      Provider.of<ChatProvider>(context, listen: false)
                          .addReaction(widget.chatId, message.id, emoji);
                      Navigator.pop(context);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Text(emoji, style: const TextStyle(fontSize: 24)),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 24),
            ListTile(
              leading: const Icon(Icons.reply_rounded, color: Colors.white),
              title: const Text('Reply', style: TextStyle(color: Colors.white)),
              onTap: () {
                _safeSetState(() => _replyingTo = message);
                Navigator.pop(context);
                _focusNode.requestFocus();
              },
            ),
            ListTile(
              leading: const Icon(Icons.copy_rounded, color: Colors.white),
              title: const Text('Copy Text', style: TextStyle(color: Colors.white)),
              onTap: () {
                // TODO: Clipboard
                Navigator.pop(context);
              },
            ),
            if (message.senderId == 'me')
              ListTile(
                leading: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                title: const Text('Delete', style: TextStyle(color: Colors.redAccent)),
                onTap: () {
                  // TODO: Delete
                  Navigator.pop(context);
                },
              ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // Edit and Delete methods removed as they required the old local state.
  // We've shifted all messaging logic to ChatProvider.

  Widget _buildInputArea() {
    final themeProvider = Provider.of<ThemeProvider>(context);
    if (_isRecording) {
      return Padding(
        padding: EdgeInsets.fromLTRB(6, 10, 6, MediaQuery.of(context).padding.bottom + 10),
        child: VoiceRecorder(
          onCancel: () {
            _safeSetState(() => _isRecording = false);
            Provider.of<CharacterProvider>(context, listen: false).setMood('happy');
          },
          onSend: (path, duration) {
            final chatProvider = Provider.of<ChatProvider>(context, listen: false);
            chatProvider.addMessage(widget.chatId, path, type: MessageType.audio);
            _safeSetState(() => _isRecording = false);
            Provider.of<CharacterProvider>(context, listen: false).setMood('celebrate');
          },
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).padding.bottom + 10,
        left: 6,
        right: 6,
        top: 10,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_replyingTo != null) _buildReplyPreview(),
          if (_showSuggestions) _buildSuggestionButtons(),
          
          GlassContainer(
            borderRadius: BorderRadius.circular(30),
            blur: 20,
            gradient: LinearGradient(
              colors: themeProvider.isLightTheme
                  ? [Colors.black.withOpacity(0.05), Colors.black.withOpacity(0.03)]
                  : [Colors.white.withOpacity(0.12), Colors.white.withOpacity(0.08)],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            child: Row(
              children: [
                IconButton(
                  iconSize: 20,
                  padding: const EdgeInsets.all(6),
                  constraints: const BoxConstraints(),
                  icon: Icon(Icons.add_circle_outline_rounded, color: Colors.white.withOpacity(0.7)),
                  onPressed: () => _pickFile(),
                ),
                IconButton(
                  iconSize: 20,
                  padding: const EdgeInsets.all(6),
                  constraints: const BoxConstraints(),
                  icon: Icon(Icons.gif_box_outlined, color: Colors.white.withOpacity(0.7)),
                  onPressed: () => _showGifPicker(),
                ),
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    focusNode: _focusNode,
                    style: const TextStyle(fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Type here',
                      hintStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4), fontSize: 13),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      isDense: true,
                    ),
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                if (!_isTyping) ...[
                  IconButton(
                    iconSize: 20,
                    padding: const EdgeInsets.all(6),
                    constraints: const BoxConstraints(),
                    icon: Icon(
                      Icons.mic_none_rounded,
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                    ),
                    onPressed: () {
                      _safeSetState(() => _isRecording = true);
                      Provider.of<CharacterProvider>(context, listen: false).setMood('recording');
                    },
                  ),
                ] else ...[
                  GestureDetector(
                    onTap: _sendMessage,
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: AppTheme.info,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.arrow_upward_rounded, color: Colors.white, size: 16),
                    ),
                  ).animate().scale(),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionButtons() {
    return Container(
      height: 36,
      margin: const EdgeInsets.only(bottom: 10),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _suggestions.length,
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () => _useSuggestion(_suggestions[index]),
            child: GlassContainer(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              borderRadius: BorderRadius.circular(18),
              color: Colors.white.withOpacity(0.1),
              child: Text(
                _suggestions[index],
                style: const TextStyle(color: Colors.white, fontSize: 13),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showGifPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => GlassContainer(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        blur: 25,
        gradient: LinearGradient(
          colors: [Colors.black.withOpacity(0.9), Colors.black.withOpacity(0.8)],
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Trending GIFs',
              style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 180,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _buildGifCategory('Funny', 'https://media.giphy.com/media/v1.Y2lkPTc5MGI3NjExNHJocXh4eHh4eHh4eHh4eHh4eHh4eHh4eHh4eHh4eHh4JmVwPXYxX2ludGVybmFsX2dpZl9ieV9pZCZjdD1n/3o7TKSjPBDpX/giphy.gif'),
                  _buildGifCategory('Love', 'https://media.giphy.com/media/v1.Y2lkPTc5MGI3NjExNHJocXh4eHh4eHh4eHh4eHh4eHh4eHh4eHh4eHh4eHh4JmVwPXYxX2ludGVybmFsX2dpZl9ieV9pZCZjdD1n/l41lT9n9qX6i67v6u/giphy.gif'),
                  _buildGifCategory('Reaction', 'https://media.giphy.com/media/v1.Y2lkPTc5MGI3NjExNHJocXh4eHh4eHh4eHh4eHh4eHh4eHh4eHh4eHh4eHh4JmVwPXYxX2ludGVybmFsX2dpZl9ieV9pZCZjdD1n/3o7TKMGfN5O9O/giphy.gif'),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildGifCategory(String label, String url) {
    return GestureDetector(
      onTap: () {
        final chatProvider = Provider.of<ChatProvider>(context, listen: false);
        chatProvider.addMessage(widget.chatId, url, type: MessageType.image);
        Navigator.pop(context);
      },
      child: Container(
        width: 140,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          image: DecorationImage(image: NetworkImage(url), fit: BoxFit.cover),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [Colors.black.withOpacity(0.8), Colors.transparent],
            ),
          ),
          alignment: Alignment.bottomCenter,
          padding: const EdgeInsets.all(12),
          child: Text(
            label,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    ).animate().scale();
  }

  Widget _buildReplyPreview() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 32,
            decoration: BoxDecoration(
              color: AppTheme.secondary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _replyingTo!.senderId == 'me' ? 'Replying to yourself' : 'Replying to ${widget.chatName}',
                  style: TextStyle(
                    color: AppTheme.secondary,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                Text(
                  _replyingTo!.content,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 13),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded, size: 20, color: Colors.white54),
            onPressed: () => _safeSetState(() => _replyingTo = null),
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.2);
  }

  void _showStyleSettings(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Choose Character Style',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Consumer<CharacterProvider>(
              builder: (context, provider, _) {
                return Wrap(
                  spacing: 15,
                  runSpacing: 15,
                  alignment: WrapAlignment.center,
                  children: CharacterStyle.values.map((style) {
                    final isSelected = provider.style == style;
                    return GestureDetector(
                      onTap: () {
                        provider.setStyle(style);
                        Navigator.pop(context);
                      },
                      child: Container(
                        width: 100,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.blue.withOpacity(0.1) : Colors.grey[100],
                          border: Border.all(
                            color: isSelected ? Colors.blue : Colors.transparent,
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            Text(
                              _getStyleEmoji(style),
                              style: const TextStyle(fontSize: 32),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              provider.getStyleName(style),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                color: isSelected ? Colors.blue : Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
  
  String _getStyleEmoji(CharacterStyle style) {
    switch (style) {
      case CharacterStyle.classic: return '👱';
      case CharacterStyle.robot: return '🤖';
      case CharacterStyle.alien: return '👽';
      case CharacterStyle.ninja: return '🥷';
      case CharacterStyle.real3d: return '🧍';
      case CharacterStyle.huggy: return '👹';
    }
  }
}

class _GlassMessageBubble extends StatelessWidget {
  final String text;
  final bool isMe;
  final String time;
  final bool isEdited;
  final bool isDeleted;
  final String? filePath;
  final String? fileType;
  final MessageStatus status;
  final Map<String, String>? reactions;
  final String? replyToContent;
  final String? replyToName;
  final Function(String)? onReactionTap;
  final MessageType type;
  final bool isAdmin;

  final bool isGroupedWithAbove;
  final bool isGroupedWithBelow;

  const _GlassMessageBubble({
    required this.text,
    required this.isMe,
    required this.time,
    this.isEdited = false,
    this.isDeleted = false,
    this.filePath,
    this.fileType,
    this.status = MessageStatus.sent,
    this.reactions,
    this.replyToContent,
    this.replyToName,
    this.onReactionTap,
    this.type = MessageType.text,
    this.isAdmin = false,
    this.isGroupedWithAbove = false,
    this.isGroupedWithBelow = false,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            Stack(
              clipBehavior: Clip.none,
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: AppTheme.secondary.withOpacity(0.1),
                  child: const Icon(Icons.person, size: 16, color: AppTheme.secondary),
                ),
                if (isAdmin)
                  Positioned(
                    right: -4,
                    bottom: -4,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: AppTheme.warning,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.shield, size: 10, color: Colors.white),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
            margin: EdgeInsets.only(
              bottom: isGroupedWithBelow ? 1 : 3,
              top: isGroupedWithAbove ? 1 : 4,
              left: isMe ? 60 : 0,
              right: isMe ? 0 : 60,
            ),
            child: Column(
              crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                // Reply Preview inside bubble
                if (replyToContent != null)
                  _buildCapturedReply(context),
                
                GestureDetector(
                  onTap: () {
                    if (type == MessageType.image) {
                      _openGallery(context);
                    }
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: isMe
                          ? const Color(0xFF1F2C34)
                          : const Color(0xFF202C33),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(isMe ? 22 : (isGroupedWithAbove ? 6 : 22)),
                        topRight: Radius.circular(isMe ? (isGroupedWithAbove ? 6 : 22) : 22),
                        bottomLeft: Radius.circular(isMe ? 22 : (isGroupedWithBelow ? 6 : 22)),
                        bottomRight: Radius.circular(isMe ? (isGroupedWithBelow ? 6 : 22) : 22),
                      ),
                    ),
                    padding: (type == MessageType.image || text.startsWith('POLL:'))
                        ? EdgeInsets.zero
                        : const EdgeInsets.fromLTRB(12, 6, 12, 5),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (text.startsWith('POLL:'))
                          _buildPollContent(context)
                        else if (type == MessageType.image)
                          _buildImageContent(context)
                        else if (type == MessageType.file)
                          _buildFileContent(context)
                        else if (type == MessageType.audio)
                          _buildAudioContent(context)
                        else
                          _buildTextContent(context),
                        // Time + status inside bubble
                        if (type == MessageType.text || type == MessageType.file || type == MessageType.audio)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Text(
                                  time,
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.55),
                                    fontSize: 10,
                                  ),
                                ),
                                if (isMe) ...[
                                  const SizedBox(width: 3),
                                  _buildStatusIcon(),
                                ],
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                
                // Reactions display
                if (reactions != null && reactions!.isNotEmpty)
                  _buildReactionsDisplay(context),
              ],
            ),
          ),
          
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCapturedReply(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      margin: const EdgeInsets.only(bottom: 2),
      constraints: const BoxConstraints(maxWidth: 250),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 3,
            height: 24,
            decoration: BoxDecoration(
              color: AppTheme.secondary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  replyToName ?? 'User',
                  style: TextStyle(color: AppTheme.secondary, fontWeight: FontWeight.bold, fontSize: 11),
                ),
                Text(
                  replyToContent!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageContent(BuildContext context) {
    final imageWidget = filePath != null && File(filePath!).existsSync()
        ? Image.file(File(filePath!), fit: BoxFit.cover)
        : Image.network(text, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, color: Colors.white));

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Stack(
        children: [
          SizedBox(
            width: 240,
            height: 180,
            child: imageWidget,
          ),
          Positioned(
            bottom: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.fullscreen_rounded, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFileContent(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(_getFileIcon(), color: Colors.white, size: 20),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            text,
            style: const TextStyle(color: Colors.white, fontSize: 15),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildAudioContent(BuildContext context) {
    return AudioMessageBubble(
      audioUrl: text,
      isMe: isMe,
      timestamp: DateTime.now(), // Placeholder as we don't have the full DateTime here
    );
  }

  Widget _buildPollContent(BuildContext context) {
    final parts = text.substring(5).split('|');
    if (parts.length >= 2) {
      return PollWidget(
        question: parts[0],
        options: parts.sublist(1),
      );
    }
    return const Padding(
      padding: EdgeInsets.all(12),
      child: Text('Invalid Poll Data', style: TextStyle(color: Colors.red)),
    );
  }

  Widget _buildTextContent(BuildContext context) {
    return Text(
      isDeleted ? '🚫 This message was deleted' : text,
      style: TextStyle(
        color: isDeleted
            ? Theme.of(context).colorScheme.onSurface.withOpacity(0.5)
            : (isMe ? Colors.white : Theme.of(context).colorScheme.onSurface),
        fontSize: 14,
        height: 1.3,
        fontStyle: isDeleted ? FontStyle.italic : FontStyle.normal,
      ),
    );
  }

  Widget _buildReactionsDisplay(BuildContext context) {
    // Unique reactions count
    final uniqueReactions = reactions!.values.toSet().toList();
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Wrap(
        spacing: 4,
        children: uniqueReactions.map((emoji) {
          final count = reactions!.values.where((r) => r == emoji).length;
          return GestureDetector(
            onTap: () => onReactionTap?.call(emoji),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(emoji, style: const TextStyle(fontSize: 14)),
                  if (count > 1) ...[
                    const SizedBox(width: 4),
                    Text(count.toString(), style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 12)),
                  ],
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildStatusIcon() {
    switch (status) {
      case MessageStatus.sending:
      case MessageStatus.pending:
        return const SizedBox(
          width: 12,
          height: 12,
          child: CircularProgressIndicator(
            strokeWidth: 1.5,
            valueColor: AlwaysStoppedAnimation(Colors.white54),
          ),
        );
      case MessageStatus.sent:
        // Single grey check
        return const Icon(Icons.check, size: 14, color: Colors.grey);
      case MessageStatus.delivered:
        // Double grey check
        return const Icon(Icons.done_all, size: 16, color: Colors.grey);
      case MessageStatus.read:
        // Double blue check (iOS/WhatsApp style)
        return const Icon(Icons.done_all, size: 16, color: Color(0xFF34B7F1));
      case MessageStatus.failed:
        return const Icon(Icons.error_outline, size: 14, color: Colors.redAccent);
    }
  }


  IconData _getFileIcon() {
    switch (fileType) {
      case 'pdf': return Icons.picture_as_pdf;
      case 'doc':
      case 'docx': return Icons.description;
      default: return Icons.attach_file;
    }
  }

  void _openGallery(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FullScreenGallery(imageUrl: text, isLocal: filePath != null),
      ),
    );
  }
}

class FullScreenGallery extends StatelessWidget {
  final String imageUrl;
  final bool isLocal;

  const FullScreenGallery({super.key, required this.imageUrl, this.isLocal = false});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Center(
            child: InteractiveViewer(
              child: isLocal 
                  ? Image.file(File(imageUrl)) 
                  : Image.network(imageUrl, fit: BoxFit.contain),
            ),
          ),
          Positioned(
            top: 40,
            left: 20,
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Center(
              child: IconButton(
                icon: const Icon(Icons.download_rounded, color: Colors.white, size: 30),
                onPressed: () {
                  // TODO: Download logic
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
