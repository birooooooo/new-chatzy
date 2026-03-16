import 'package:flutter/material.dart';
import 'dart:ui';
import 'dart:async';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../providers/chat_provider.dart';
import '../../services/ai_service.dart';
import '../../models/message_model.dart';

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
  }

  @override
  void dispose() {
    _welcomeTimer?.cancel();
    _focusNode.dispose();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
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
              const SizedBox(height: 100), // Height of docked input
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
      padding: const EdgeInsets.fromLTRB(20, 60, 20, 10),
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
              fontSize: 11,
              fontStyle: FontStyle.italic,
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
        final msg = messages[messages.length - 1 - index];
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
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'AI is thinking...', 
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
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
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 0), // ZERO bottom space
      decoration: const BoxDecoration(
        color: Colors.transparent, // Transparent for mesh visibility
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: Colors.transparent, // Fully transparent inner box
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: Colors.white.withOpacity(0.15)), // Slightly more contrast
              ),
              child: TextField(
                focusNode: _focusNode,
                controller: _controller,
                style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                decoration: InputDecoration(
                  hintText: 'Ask AI anything...',
                  hintStyle: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                    fontSize: 14,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                ),
                onSubmitted: _sendMessage,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: GestureDetector(
              onTap: () => _sendMessage(_controller.text),
              child: Container(
                width: 52,
                height: 52,
                decoration: const BoxDecoration(
                  gradient: AppTheme.blueGradient,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.send_rounded, color: Colors.white, size: 24),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
