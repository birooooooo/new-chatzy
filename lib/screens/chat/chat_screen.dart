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
import '../../widgets/gif_picker_sheet.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../services/reminder_service.dart';

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

    // Trigger immediate 'waving' so Huggy reacts instantly while API loads
    if (mounted) {
      Provider.of<CharacterProvider>(context, listen: false).setMood('neutral');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Provider.of<CharacterProvider>(context, listen: false).setMood('happy');
        }
      });
    }

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
      // withData: true on all platforms — avoids Android content URI issues
      // where File(path).existsSync() returns false for content:// paths
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'gif', 'pdf', 'doc', 'docx'],
        withData: true,
      );

      if (result == null) return;
      final file = result.files.single;
      final bytes = file.bytes;
      if (bytes == null) return;

      final ext = file.extension?.toLowerCase() ?? '';
      final isImage = ['jpg', 'jpeg', 'png', 'gif'].contains(ext);
      final type = isImage ? MessageType.image : MessageType.file;

      final chatProvider = Provider.of<ChatProvider>(context, listen: false);

      // Upload bytes directly — works on Android, iOS, and Web
      final url = await chatProvider.storageService.uploadChatImageBytes(
        bytes, widget.chatId, file.name,
      );

      if (url != null && mounted) {
        chatProvider.addMessage(widget.chatId, url, type: type);
        if (_scrollController.hasClients) {
          _scrollController.animateTo(0,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut);
        }
      }
    } catch (e) {
      debugPrint('Error picking file: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to send file')),
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
    final isMe = message.senderId == 'me' ||
        message.senderId ==
            Provider.of<ChatProvider>(context, listen: false).currentUserId;

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'dismiss',
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 180),
      transitionBuilder: (_, anim, __, child) => FadeTransition(
        opacity: anim,
        child: ScaleTransition(
            scale: Tween(begin: 0.95, end: 1.0).animate(anim), child: child),
      ),
      pageBuilder: (ctx, _, __) => _MessageActionOverlay(
        message: message,
        isMe: isMe,
        chatId: widget.chatId,
        chatName: widget.chatName,
        onReply: () {
          _safeSetState(() => _replyingTo = message);
          _focusNode.requestFocus();
        },
        onTranslate: () => _translateMessage(message),
        onSuggestSelect: (text) {
          _messageController.text = text;
          _focusNode.requestFocus();
        },
        onRemind: (DateTime at) => _scheduleReminder(message, at),
        aiService: _aiService,
      ),
    );
  }

  Widget _divider() => const Divider(height: 1, color: Colors.white10, indent: 16, endIndent: 16);

  Future<void> _translateMessage(MessageModel message) async {
    if (message.content.isEmpty) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    try {
      final model = _aiService;
      final prompt =
          'Translate the following message to English. '
          'If it is already in English, translate it to Arabic. '
          'Return ONLY the translated text, nothing else.\n\n"${message.content}"';
      final result = await model.freePrompt(prompt);
      if (!mounted) return;
      Navigator.pop(context); // close loader
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: const Color(0xFF1A1A2E),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(children: [
            Icon(Icons.translate_rounded, color: Color(0xFF4ADE80)),
            SizedBox(width: 8),
            Text('Translation', style: TextStyle(color: Colors.white)),
          ]),
          content: Text(result, style: const TextStyle(color: Colors.white70, fontSize: 15)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close', style: TextStyle(color: Color(0xFF4ADE80))),
            ),
          ],
        ),
      );
    } catch (_) {
      if (mounted) Navigator.pop(context);
    }
  }

  Future<void> _suggestReply(MessageModel message) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    try {
      final prompt =
          'Someone sent this message in a chat: "${message.content}"\n'
          'Give me 3 short natural reply suggestions (1 line each). '
          'Return them numbered 1. 2. 3. only, no extra text.';
      final result = await _aiService.freePrompt(prompt);
      if (!mounted) return;
      Navigator.pop(context);

      final suggestions = result
          .split('\n')
          .where((l) => l.trim().isNotEmpty)
          .take(3)
          .map((l) => l.replaceAll(RegExp(r'^\d+\.\s*'), '').trim())
          .toList();

      showModalBottomSheet(
        context: context,
        backgroundColor: const Color(0xFF1A1A2E),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (_) => Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(children: [
                Icon(Icons.auto_awesome_rounded, color: Color(0xFF60A5FA), size: 18),
                SizedBox(width: 8),
                Text('Suggested Replies',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15)),
              ]),
              const SizedBox(height: 16),
              ...suggestions.map((s) => GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      _messageController.text = s;
                      _focusNode.requestFocus();
                    },
                    child: Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.07),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: Text(s, style: const TextStyle(color: Colors.white, fontSize: 14)),
                    ),
                  )),
            ],
          ),
        ),
      );
    } catch (_) {
      if (mounted) Navigator.pop(context);
    }
  }

  Future<void> _showReminderPicker(MessageModel message) async {
    final now = DateTime.now();

    // Quick preset options
    final presets = [
      ('In 30 minutes', now.add(const Duration(minutes: 30))),
      ('In 1 hour', now.add(const Duration(hours: 1))),
      ('In 3 hours', now.add(const Duration(hours: 3))),
      ('Tomorrow morning', DateTime(now.year, now.month, now.day + 1, 9, 0)),
      ('Custom time...', null as DateTime?),
    ];

    await showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A2E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(children: [
              Icon(Icons.alarm_add_rounded, color: Color(0xFFFBBF24), size: 18),
              SizedBox(width: 8),
              Text('Remind Me Later',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15)),
            ]),
            const SizedBox(height: 6),
            Text(
              '"${message.content.length > 50 ? '${message.content.substring(0, 50)}…' : message.content}"',
              style: const TextStyle(color: Colors.white38, fontSize: 12),
            ),
            const SizedBox(height: 16),
            ...presets.map((preset) {
              final (label, time) = preset;
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFBBF24).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.alarm_rounded, color: Color(0xFFFBBF24), size: 18),
                ),
                title: Text(label, style: const TextStyle(color: Colors.white, fontSize: 14)),
                subtitle: time != null
                    ? Text(
                        '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
                        style: const TextStyle(color: Colors.white38, fontSize: 11),
                      )
                    : null,
                onTap: () async {
                  Navigator.pop(ctx);
                  if (time == null) {
                    // Custom time picker
                    final picked = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.now(),
                    );
                    if (picked == null || !mounted) return;
                    var scheduled = DateTime(now.year, now.month, now.day, picked.hour, picked.minute);
                    if (scheduled.isBefore(now)) {
                      scheduled = scheduled.add(const Duration(days: 1));
                    }
                    await _scheduleReminder(message, scheduled);
                  } else {
                    await _scheduleReminder(message, time);
                  }
                },
              );
            }),
          ],
        ),
      ),
    );
  }

  Future<void> _scheduleReminder(MessageModel message, DateTime at) async {
    final granted = await ReminderService.requestPermission();
    if (!granted || !mounted) return;

    final preview = message.content.length > 60
        ? '${message.content.substring(0, 60)}…'
        : message.content;

    await ReminderService.scheduleReminder(
      id: message.id.hashCode.abs(),
      title: '💬 Reminder from ${widget.chatName}',
      body: preview,
      scheduledTime: at,
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Reminder set for ${at.hour.toString().padLeft(2, '0')}:${at.minute.toString().padLeft(2, '0')}',
        ),
        backgroundColor: const Color(0xFFFBBF24),
        behavior: SnackBarBehavior.floating,
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

  Future<void> _showGifPicker() async {
    final gif = await GifPickerSheet.show(context);
    if (gif == null || !mounted) return;
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    chatProvider.addMessage(
      widget.chatId,
      gif.originalUrl,
      type: MessageType.gif,
    );
    if (_scrollController.hasClients) {
      _scrollController.animateTo(0,
          duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    }
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
                    if (type == MessageType.image || type == MessageType.gif) {
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
                        else if (type == MessageType.gif)
                          _buildGifContent(context)
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

  /// Renders an animated GIF bubble — like Telegram: no background box,
  /// full-width animated image with a small "GIF" badge and time overlay.
  Widget _buildGifContent(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Stack(
        children: [
          // Animated GIF via CachedNetworkImage
          SizedBox(
            width: 240,
            height: 180,
            child: CachedNetworkImage(
              imageUrl: text,
              fit: BoxFit.cover,
              placeholder: (_, __) => Container(
                color: Colors.white.withOpacity(0.06),
                child: const Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white38),
                  ),
                ),
              ),
              errorWidget: (_, __, ___) => Container(
                color: Colors.white.withOpacity(0.06),
                child: const Icon(Icons.broken_image_outlined,
                    color: Colors.white38, size: 36),
              ),
            ),
          ),

          // Dark gradient at bottom for time readability
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 36,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withOpacity(0.6),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // "GIF" badge — top left, like Telegram
          Positioned(
            top: 7,
            left: 7,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.55),
                borderRadius: BorderRadius.circular(5),
              ),
              child: const Text(
                'GIF',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                ),
              ),
            ),
          ),

          // Time + status — bottom right, like Telegram
          Positioned(
            bottom: 6,
            right: 8,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  time,
                  style: const TextStyle(
                      color: Colors.white70, fontSize: 10),
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

// ── Telegram-style message action overlay ────────────────────────────────────
class _MessageActionOverlay extends StatefulWidget {
  final MessageModel message;
  final bool isMe;
  final String chatId;
  final String chatName;
  final VoidCallback onReply;
  final VoidCallback onTranslate;
  final void Function(String) onSuggestSelect;
  final void Function(DateTime) onRemind;
  final AiService aiService;

  const _MessageActionOverlay({
    required this.message,
    required this.isMe,
    required this.chatId,
    required this.chatName,
    required this.onReply,
    required this.onTranslate,
    required this.onSuggestSelect,
    required this.onRemind,
    required this.aiService,
  });

  @override
  State<_MessageActionOverlay> createState() => _MessageActionOverlayState();
}

class _MessageActionOverlayState extends State<_MessageActionOverlay> {
  bool _showReminder = false;
  bool _showSuggest = false;
  bool _loadingSuggestions = false;
  bool _suggestError = false;
  List<String> _suggestions = [];

  static const _presets = [
    ('In 30 minutes', Duration(minutes: 30)),
    ('In 1 hour',     Duration(hours: 1)),
    ('In 3 hours',    Duration(hours: 3)),
  ];

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pop(context),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            color: Colors.black.withOpacity(0.55),
            child: SafeArea(
              child: Center(
                child: GestureDetector(
                  onTap: () {},
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: widget.isMe
                          ? CrossAxisAlignment.end
                          : CrossAxisAlignment.start,
                      children: [
                        // Message bubble preview
                        Container(
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.72,
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            gradient: widget.isMe ? AppTheme.blueGradient : null,
                            color: widget.isMe
                                ? null
                                : Colors.white.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Text(
                            widget.message.content,
                            style: const TextStyle(
                                color: Colors.white, fontSize: 14),
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Emoji row — hidden when sub-view is open
                        if (!_showReminder && !_showSuggest)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1F2937),
                            borderRadius: BorderRadius.circular(28),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.4),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ...['❤️', '👍', '👎', '🔥', '🥰', '👏', '😁']
                                  .map((e) => GestureDetector(
                                        onTap: () {
                                          Provider.of<ChatProvider>(context,
                                                  listen: false)
                                              .addReaction(widget.chatId,
                                                  widget.message.id, e);
                                          Navigator.pop(context);
                                        },
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 5),
                                          child: Text(e,
                                              style: const TextStyle(
                                                  fontSize: 22)),
                                        ),
                                      )),
                              Container(
                                width: 1, height: 24,
                                color: Colors.white12,
                                margin:
                                    const EdgeInsets.symmetric(horizontal: 4),
                              ),
                              const Icon(Icons.keyboard_arrow_down_rounded,
                                  color: Colors.white54, size: 22),
                            ],
                          ),
                        ),
                        if (!_showReminder && !_showSuggest)
                          const SizedBox(height: 8),

                        // Card — switches between main menu, reminder, suggest
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          child: _showReminder
                              ? _reminderCard()
                              : _showSuggest
                                  ? _suggestCard()
                                  : _mainMenuCard(),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _mainMenuCard() {
    return Container(
      key: const ValueKey('main'),
      width: 220,
      decoration: BoxDecoration(
        color: const Color(0xFF1F2937),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _TgAction(
            icon: Icons.reply_rounded,
            label: 'Reply',
            onTap: () {
              Navigator.pop(context);
              widget.onReply();
            },
          ),
          _div(),
          _TgAction(
            icon: Icons.copy_rounded,
            label: 'Copy',
            onTap: () => Navigator.pop(context),
          ),
          _div(),
          _TgAction(
            icon: Icons.translate_rounded,
            label: 'Translate',
            onTap: () {
              Navigator.pop(context);
              widget.onTranslate();
            },
          ),
          _div(),
          _TgAction(
            icon: Icons.auto_awesome_rounded,
            label: 'Suggest Reply',
            onTap: () {
              setState(() => _showSuggest = true);
              _fetchSuggestions();
            },
          ),
          _div(),
          _TgAction(
            icon: Icons.alarm_add_rounded,
            label: 'Remind Me Later',
            onTap: () => setState(() => _showReminder = true),
          ),
          if (widget.isMe) ...[
            _div(),
            _TgAction(
              icon: Icons.delete_outline_rounded,
              label: 'Delete',
              color: Colors.redAccent,
              onTap: () => Navigator.pop(context),
            ),
          ],
          _div(),
          _TgAction(
            icon: Icons.check_circle_outline_rounded,
            label: 'Select',
            onTap: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Future<void> _fetchSuggestions() async {
    setState(() {
      _loadingSuggestions = true;
      _suggestError = false;
      _suggestions = [];
    });
    try {
      final prompt =
          'Someone sent this chat message: "${widget.message.content}"\n'
          'Give exactly 3 short natural reply suggestions (max 10 words each).\n'
          'Return ONLY the 3 replies, one per line, no numbering, no extra text.';
      final text = await widget.aiService.freePrompt(prompt);
      if (!mounted) return;
      final lines = text
          .split('\n')
          .map((l) => l.trim())
          .where((l) => l.isNotEmpty)
          .take(3)
          .toList();
      setState(() {
        _suggestions = lines;
        _loadingSuggestions = false;
        _suggestError = lines.isEmpty;
      });
    } catch (e) {
      debugPrint('Suggest reply error: $e');
      if (mounted) setState(() { _loadingSuggestions = false; _suggestError = true; });
    }
  }

  Widget _suggestCard() {
    return Container(
      key: const ValueKey('suggest'),
      width: 280,
      decoration: BoxDecoration(
        color: const Color(0xFF1F2937),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header with back button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded,
                      color: Colors.white70, size: 16),
                  onPressed: () => setState(() {
                    _showSuggest = false;
                    _suggestions = [];
                    _suggestError = false;
                  }),
                  padding: EdgeInsets.zero,
                  constraints:
                      const BoxConstraints(minWidth: 32, minHeight: 32),
                ),
                const Icon(Icons.auto_awesome_rounded,
                    color: Color(0xFF60A5FA), size: 15),
                const SizedBox(width: 6),
                const Text('Suggest Reply',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          _div(),
          if (_loadingSuggestions)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 22, height: 22,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Color(0xFF60A5FA)),
                  ),
                  SizedBox(height: 10),
                  Text('Thinking...',
                      style:
                          TextStyle(color: Colors.white38, fontSize: 12)),
                ],
              ),
            )
          else if (_suggestError || _suggestions.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 18),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Could not get suggestions.',
                      style: TextStyle(color: Colors.white38, fontSize: 13)),
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: _fetchSuggestions,
                    child: const Text('Try again',
                        style: TextStyle(
                            color: Color(0xFF60A5FA),
                            fontSize: 13,
                            fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            )
          else
            ..._suggestions.asMap().entries.map((entry) {
              final i = entry.key;
              final s = entry.value;
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  InkWell(
                    onTap: () {
                      Navigator.pop(context);
                      widget.onSuggestSelect(s);
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 13),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(s,
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 14)),
                          ),
                          const Icon(Icons.send_rounded,
                              color: Color(0xFF60A5FA), size: 16),
                        ],
                      ),
                    ),
                  ),
                  if (i < _suggestions.length - 1) _div(),
                ],
              );
            }),
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  Widget _reminderCard() {
    final now = DateTime.now();
    return Container(
      key: const ValueKey('reminder'),
      width: 220,
      decoration: BoxDecoration(
        color: const Color(0xFF1F2937),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header with back button
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded,
                      color: Colors.white70, size: 16),
                  onPressed: () => setState(() => _showReminder = false),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                      minWidth: 32, minHeight: 32),
                ),
                const Text('Remind me',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          _div(),
          // Presets
          ..._presets.map((p) {
            final (label, dur) = p;
            final time = now.add(dur);
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _TgAction(
                  icon: Icons.alarm_rounded,
                  label: label,
                  subtitle:
                      '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
                  onTap: () {
                    Navigator.pop(context);
                    widget.onRemind(time);
                  },
                ),
                _div(),
              ],
            );
          }),
          // Tomorrow morning
          _TgAction(
            icon: Icons.wb_sunny_outlined,
            label: 'Tomorrow morning',
            subtitle: '09:00',
            onTap: () {
              final tomorrow = DateTime(
                  now.year, now.month, now.day + 1, 9, 0);
              Navigator.pop(context);
              widget.onRemind(tomorrow);
            },
          ),
          _div(),
          // Custom time
          _TgAction(
            icon: Icons.schedule_rounded,
            label: 'Custom time...',
            onTap: () async {
              Navigator.pop(context);
              final picked = await showTimePicker(
                context: context,
                initialTime: TimeOfDay.now(),
              );
              if (picked == null) return;
              var scheduled = DateTime(
                  now.year, now.month, now.day,
                  picked.hour, picked.minute);
              if (scheduled.isBefore(now)) {
                scheduled =
                    scheduled.add(const Duration(days: 1));
              }
              widget.onRemind(scheduled);
            },
          ),
        ],
      ),
    );
  }

  Widget _div() => const Divider(
      height: 1, color: Colors.white10, indent: 16, endIndent: 16);
}

class _TgAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? subtitle;
  final Color color;
  final VoidCallback onTap;

  const _TgAction({
    required this.icon,
    required this.label,
    this.subtitle,
    this.color = Colors.white,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(label,
                      style: TextStyle(
                          color: color,
                          fontSize: 15,
                          fontWeight: FontWeight.w400)),
                  if (subtitle != null)
                    Text(subtitle!,
                        style: const TextStyle(
                            color: Colors.white38, fontSize: 11)),
                ],
              ),
            ),
            Icon(icon, color: color.withOpacity(0.65), size: 20),
          ],
        ),
      ),
    );
  }
}
