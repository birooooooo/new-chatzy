import 'package:flutter/material.dart';
import 'dart:ui';
import 'dart:async';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../providers/chat_provider.dart';
import '../../services/ai_service.dart';
import '../../models/message_model.dart';
import '../../widgets/glass_container.dart';

class AiChatbotScreen extends StatefulWidget {
  const AiChatbotScreen({super.key});

  @override
  State<AiChatbotScreen> createState() => _AiChatbotScreenState();
}

class _AiChatbotScreenState extends State<AiChatbotScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  final AiService _aiService = AiService();
  bool _isTyping = false;

  // @ mention state
  List<String> _mentionSuggestions = [];
  String _mentionQuery = '';
  OverlayEntry? _mentionOverlay;

  // Welcome Animation State
  String _welcomeText = "";
  int _currentMessageIndex = 0;
  int _currentCharIndex = 0;
  bool _isDeleting = false;
  Timer? _welcomeTimer;

  final List<String> _welcomeMessages = [
    "Welcome to Chatzy AI!",
    "How can I help you today?",
    "Ask me anything!"
  ];

  @override
  void initState() {
    super.initState();
    _startWelcomeAnimation();
    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _welcomeTimer?.cancel();
    _removeMentionOverlay();
    _controller.removeListener(_onTextChanged);
    _focusNode.dispose();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // ── @ mention logic ────────────────────────────────────────────────────────

  void _onTextChanged() {
    final text = _controller.text;
    final cursor = _controller.selection.baseOffset;
    if (cursor < 0) return;

    // Find if cursor is right after an @ symbol
    final textBeforeCursor = text.substring(0, cursor);
    final atIndex = textBeforeCursor.lastIndexOf('@');
    if (atIndex == -1) {
      _removeMentionOverlay();
      return;
    }
    // Only trigger if @ is at start or after a space
    final charBefore = atIndex > 0 ? textBeforeCursor[atIndex - 1] : ' ';
    if (charBefore != ' ' && charBefore != '\n') {
      _removeMentionOverlay();
      return;
    }
    final query = textBeforeCursor.substring(atIndex + 1);
    // Stop if there's a space in the query (mention ended)
    if (query.contains(' ')) {
      _removeMentionOverlay();
      return;
    }
    _mentionQuery = query;
    _updateMentionSuggestions(query);
  }

  void _updateMentionSuggestions(String query) {
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    final names = chatProvider.chats
        .where((c) => c.name.isNotEmpty && c.name != 'AI')
        .map((c) => c.name)
        .where((n) => n.toLowerCase().startsWith(query.toLowerCase()))
        .toList();

    if (names.isEmpty) {
      _removeMentionOverlay();
      return;
    }
    setState(() => _mentionSuggestions = names);
    _showMentionOverlay();
  }

  void _showMentionOverlay() {
    _removeMentionOverlay();
    final overlay = Overlay.of(context);
    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    _mentionOverlay = OverlayEntry(
      builder: (ctx) => _MentionSuggestionBox(
        names: _mentionSuggestions,
        onSelect: _insertMention,
      ),
    );
    overlay.insert(_mentionOverlay!);
  }

  void _removeMentionOverlay() {
    _mentionOverlay?.remove();
    _mentionOverlay = null;
    if (mounted) setState(() => _mentionSuggestions = []);
  }

  void _insertMention(String name) {
    final text = _controller.text;
    final cursor = _controller.selection.baseOffset;
    if (cursor < 0) return;
    final atIndex = text.lastIndexOf('@', cursor - 1);
    if (atIndex == -1) return;
    final newText = text.replaceRange(atIndex, cursor, '@$name ');
    _controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: atIndex + name.length + 2),
    );
    _removeMentionOverlay();
    _focusNode.requestFocus();
  }

  void _showContactPicker() {
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    final names = chatProvider.chats
        .where((c) => c.name.isNotEmpty && c.name != 'AI')
        .map((c) => c.name)
        .toList();
    if (names.isEmpty) return;

    // Insert @ at cursor to trigger the flow
    final text = _controller.text;
    final cursor = _controller.selection.baseOffset.clamp(0, text.length);
    final prefix = cursor > 0 && text[cursor - 1] != ' ' ? ' @' : '@';
    final newText = text.replaceRange(cursor, cursor, prefix);
    _controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: cursor + prefix.length),
    );
    _focusNode.requestFocus();
  }

  void _startWelcomeAnimation() {
    // Faster speed for "wiring and editing" feel
    _welcomeTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      _updateWelcomeText();
    });
  }

  void _updateWelcomeText() {
    final String fullText = _welcomeMessages[_currentMessageIndex];
    
    setState(() {
      if (!_isDeleting) {
        if (_currentCharIndex < fullText.length) {
          _currentCharIndex++;
        } else {
          _isDeleting = true;
          _welcomeTimer?.cancel();
          Future.delayed(const Duration(seconds: 1), () {
            if (mounted) _startWelcomeAnimation();
          });
        }
      } else {
        if (_currentCharIndex > 0) {
          _currentCharIndex -= 2; // Delete faster
          if (_currentCharIndex < 0) _currentCharIndex = 0;
        } else {
          _isDeleting = false;
          _currentMessageIndex = (_currentMessageIndex + 1) % _welcomeMessages.length;
        }
      }
      _welcomeText = fullText.substring(0, _currentCharIndex);
    });
  }

  void _sendMessage(String text) {
    if (text.trim().isEmpty) return;

    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    chatProvider.addMessage('ai_chatbot', text);
    
    _controller.clear();
    _scrollToBottom();

    setState(() {
      _isTyping = true;
    });

    final contextHistory = chatProvider.getAllChatsContext();
    final history = chatProvider.getMessages('ai_chatbot');

    _aiService.getChatResponse(text, history, contextHistory).then((response) {
      if (mounted) {
        chatProvider.addMessage('ai_chatbot', response, senderId: 'ai_chatbot');
        setState(() {
          _isTyping = false;
        });
        _scrollToBottom();
      }
    }).catchError((e) {
      if (mounted) {
        chatProvider.addMessage('ai_chatbot', "Error: $e", senderId: 'ai_chatbot');
        setState(() {
          _isTyping = false;
        });
        _scrollToBottom();
      }
    });
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Global Doodle Background
          Positioned.fill(
            child: Opacity(
              opacity: Theme.of(context).brightness == Brightness.light ? 0.12 : 0.05,
              child: Image.asset(
                'assets/images/doodle_bg.jpg',
                fit: BoxFit.cover,
              ),
            ),
          ),
          
          Column(
            children: [
              _buildHeader(),
              Expanded(
                child: Consumer<ChatProvider>(
                  builder: (context, chatProvider, child) {
                    final messages = chatProvider.getMessages('ai_chatbot');
                    if (messages.isEmpty) return _buildEmptyState();
                    return _buildMessages(messages);
                  },
                ),
              ),
              if (_isTyping) _buildTypingIndicator(),
              const SizedBox(height: 190), // reserve room for input box + nav bar
            ],
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildInput(),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            _welcomeText,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w300,
              color: Theme.of(context).colorScheme.onSurface,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            width: 2,
            height: 28,
            color: AppTheme.secondary.withOpacity(0.5),
          ).animate(onPlay: (c) => c.repeat())
           .fadeIn(duration: 400.ms)
           .fadeOut(duration: 400.ms),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 10, 20, 5),
      alignment: Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'CHATZY AI',
            style: TextStyle(
              fontSize: 24, 
              fontWeight: FontWeight.bold, 
              letterSpacing: 1.5,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          Text(
            'powered by Gemini',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4), 
              fontSize: 10, // Slightly smaller
              fontStyle: FontStyle.italic,
              height: 1.0, // Tighten line height
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessages(List<MessageModel> messages) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final msg = messages[index];
        final isMe = msg.senderId == 'me';
        
        return Align(
          alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(14),
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
            decoration: BoxDecoration(
              gradient: isMe ? AppTheme.blueGradient : null,
              color: isMe ? null : Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(20),
                topRight: const Radius.circular(20),
                bottomLeft: Radius.circular(isMe ? 20 : 4),
                bottomRight: Radius.circular(isMe ? 4 : 20),
              ),
            ),
            child: Text(
              msg.content, 
              style: TextStyle(
                fontSize: 15,
                color: isMe ? Colors.white : Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
        ).animate().fadeIn(duration: 200.ms).slideX(begin: isMe ? 0.1 : -0.1);
      },
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'AI is thinking...',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.85),
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInput() {
    return Container(
      padding: EdgeInsets.fromLTRB(20, 0, 20, MediaQuery.of(context).padding.bottom + 84),
      child: GlassContainer(
        padding: const EdgeInsets.all(12),
        borderRadius: BorderRadius.circular(32),
        blur: 25,
        border: Border.all(color: Colors.white.withOpacity(0.12), width: 1.5),
        gradient: LinearGradient(
          colors: [Colors.white.withOpacity(0.08), Colors.white.withOpacity(0.02)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              focusNode: _focusNode,
              controller: _controller,
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 15),
              maxLines: null,
              decoration: InputDecoration(
                hintText: 'Ask anything...',
                hintStyle: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                  fontSize: 15,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              onSubmitted: _sendMessage,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                // @ button
                GestureDetector(
                  onTap: _showContactPicker,
                  child: GlassContainer(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    borderRadius: BorderRadius.circular(20),
                    blur: 10,
                    opacity: 0.1,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '@',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const Spacer(),
                // Voice button
                GestureDetector(
                  onTap: () {},
                  child: GlassContainer(
                    width: 42,
                    height: 42,
                    borderRadius: BorderRadius.circular(21),
                    blur: 10,
                    opacity: 0.15,
                    color: Colors.blue.withOpacity(0.2),
                    child: Icon(Icons.graphic_eq_rounded,
                        color: Colors.blue.shade300, size: 20),
                  ),
                ),
                const SizedBox(width: 8),
                // Send button
                GestureDetector(
                  onTap: () => _sendMessage(_controller.text),
                  child: Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: const Color(0xFF4ADE80),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF4ADE80).withOpacity(0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.arrow_upward_rounded,
                        color: Colors.black, size: 22),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Mention suggestion overlay ────────────────────────────────────────────────
class _MentionSuggestionBox extends StatelessWidget {
  final List<String> names;
  final ValueChanged<String> onSelect;

  const _MentionSuggestionBox({required this.names, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom + 84 + 80;
    return Positioned(
      bottom: bottom,
      left: 24,
      right: 24,
      child: Material(
        color: Colors.transparent,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              constraints: const BoxConstraints(maxHeight: 220),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.10),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.18)),
              ),
              child: ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(vertical: 6),
                itemCount: names.length,
                separatorBuilder: (_, __) =>
                    Divider(height: 1, color: Colors.white.withOpacity(0.08)),
                itemBuilder: (_, i) => InkWell(
                  onTap: () => onSelect(names[i]),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: AppTheme.secondary.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              names[i][0].toUpperCase(),
                              style: const TextStyle(
                                  color: AppTheme.secondary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          names[i],
                          style: const TextStyle(color: Colors.white, fontSize: 15),
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
}
