import 'package:flutter/material.dart';
import 'dart:ui';
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
  final AiService _aiService = AiService();
  bool _isTyping = false;

  final List<String> _quickPrompts = [
    '💡 Suggest a reply',
    '🌍 Translate message',
    '✍️ Improve my writing',
    '📝 Summarize chat',
  ];

  void _sendMessage(String text) {
    if (text.trim().isEmpty) return;

    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    
    // Add user message to provider
    chatProvider.addMessage('ai_chatbot', text);
    
    _controller.clear();
    _scrollToBottom();

    setState(() {
      _isTyping = true;
    });

    // Get context from other chats
    final contextHistory = chatProvider.getAllChatsContext();
    final history = chatProvider.getMessages('ai_chatbot');

    // Get real AI response
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
    return Column(
      children: [
        // Header
        _buildHeader(),
        
        // Messages or empty state
        Expanded(
          child: Consumer<ChatProvider>(
            builder: (context, chatProvider, child) {
              final messages = chatProvider.getMessages('ai_chatbot');
              return messages.isEmpty ? _buildEmptyState() : _buildMessages(messages);
            },
          ),
        ),
        
        // Typing indicator
        if (_isTyping)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    gradient: AppTheme.blueGradient,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.smart_toy_rounded, size: 14, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Text('AI is thinking...', style: TextStyle(color: Colors.white.withOpacity(0.5))),
              ],
            ),
          ),
        
        // Input
        _buildInput(),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: AppTheme.blueGradient,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.secondary.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(Icons.smart_toy_rounded, color: Colors.white, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'CHATZY AI',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1),
                ),
                Text(
                  'Your intelligent assistant',
                  style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.secondary.withOpacity(0.2),
                    Colors.purple.withOpacity(0.2),
                  ],
                ),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(30),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Icon(Icons.smart_toy_rounded, size: 50, color: AppTheme.secondary),
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'How can I help you?',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              'Ask me anything or try a quick action',
              style: TextStyle(color: Colors.white.withOpacity(0.5)),
            ),
            const SizedBox(height: 32),
            
            // Quick prompts
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _quickPrompts.map((prompt) {
                return GestureDetector(
                  onTap: () => _sendMessage(prompt),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.white.withOpacity(0.1),
                          Colors.white.withOpacity(0.05),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withOpacity(0.15)),
                    ),
                    child: Text(prompt, style: const TextStyle(fontSize: 14)),
                  ),
                ).animate()
                    .fadeIn(delay: Duration(milliseconds: 100 * _quickPrompts.indexOf(prompt)))
                    .scale(begin: const Offset(0.9, 0.9), end: const Offset(1, 1));
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessages(List<MessageModel> messages) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 180), // Extra padding for input bar + nav bar
      itemCount: messages.length,
      itemBuilder: (context, index) {
        // AI screen usually shows latest at top or bottom? 
        // Existing code: index 0 is first message.
        // My provider: insert(0) means latest is index 0.
        // To match existing look (scrolling down), we should reverse the list or use reverse: true.
        // Existing code didn't use reverse: true but scrolled to bottom.
        
        final msg = messages[messages.length - 1 - index]; // Show in order
        final isMe = msg.senderId == 'me';
        
        return Align(
          alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: EdgeInsets.only(
              bottom: 12,
              left: isMe ? 60 : 0,
              right: isMe ? 0 : 60,
            ),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: isMe
                  ? AppTheme.blueGradient
                  : LinearGradient(
                      colors: [
                        Colors.white.withOpacity(0.1),
                        Colors.white.withOpacity(0.05),
                      ],
                    ),
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(18),
                topRight: const Radius.circular(18),
                bottomLeft: Radius.circular(isMe ? 18 : 4),
                bottomRight: Radius.circular(isMe ? 4 : 18),
              ),
              border: isMe ? null : Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: Text(msg.content, style: const TextStyle(fontSize: 15)),
          ),
        ).animate()
            .fadeIn(duration: 200.ms)
            .slideX(begin: isMe ? 0.1 : -0.1, end: 0);
      },
    );
  }

  Widget _buildInput() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 110), // Positioned above the glass nav bar
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withOpacity(0.1),
                    Colors.white.withOpacity(0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withOpacity(0.15)),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: 'Ask AI anything...',
                      hintStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    ),
                    onSubmitted: _sendMessage,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () => _sendMessage(_controller.text),
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: AppTheme.blueGradient,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.secondary.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(Icons.send_rounded, color: Colors.white, size: 22),
            ),
          ),
        ],
      ),
    );
  }
}
