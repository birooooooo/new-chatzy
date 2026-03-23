import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_widgets.dart';
import '../../widgets/animated_human_character.dart';
import 'package:provider/provider.dart';
import '../../providers/chat_provider.dart';
import '../../models/message_model.dart';
import '../../models/user_model.dart';
import 'package:intl/intl.dart';

class GroupChatScreen extends StatefulWidget {
  final String chatId;
  final String groupName;

  const GroupChatScreen({super.key, required this.chatId, required this.groupName});

  @override
  State<GroupChatScreen> createState() => _GroupChatScreenState();
}

class _GroupChatScreenState extends State<GroupChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isTyping = false;
  String _characterMood = 'happy';

  final List<String> _members = ['You', 'Sarah', 'Mike', 'Emily', 'John', 'Lisa'];

  @override
  void initState() {
    super.initState();
  }

  void _sendMessage(String text) {
    if (text.trim().isEmpty) return;
    
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    chatProvider.addMessage(widget.chatId, text);

    setState(() {
      _messageController.clear();
      _isTyping = false;
      
      if (text.toLowerCase().contains('hi') || text.toLowerCase().contains('hello')) {
        _characterMood = 'waving';
      } else if (text.contains('!') || text.contains('🎉')) {
        _characterMood = 'excited';
      } else {
        _characterMood = 'happy';
      }
    });

    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
        title: GestureDetector(
          onTap: () => _showGroupInfo(),
          child: Row(
            children: [
              AppAvatar(
                name: widget.groupName,
                size: 40,
                icon: Icons.group_rounded,
                isCircle: true,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.groupName,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      '${_members.length} members',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.videocam),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Starting group video call...')),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.call),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Starting group call...')),
              );
            },
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              switch (value) {
                case 'info':
                  _showGroupInfo();
                  break;
                case 'search':
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Search in group')),
                  );
                  break;
                case 'mute':
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Group muted')),
                  );
                  break;
                case 'leave':
                  _showLeaveDialog();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'info', child: Text('Group info')),
              const PopupMenuItem(value: 'search', child: Text('Search')),
              const PopupMenuItem(value: 'mute', child: Text('Mute notifications')),
              const PopupMenuItem(
                value: 'leave',
                child: Text('Leave group', style: TextStyle(color: AppTheme.error)),
              ),
            ],
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // Messages List
              Expanded(
                child: Consumer<ChatProvider>(
                  builder: (context, chatProvider, child) {
                    final messages = chatProvider.getMessages(widget.chatId).reversed.toList();
                    return ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final message = messages[index];
                        final isMe = message.senderId == 'me';
                        final senderName = isMe ? 'You' : (chatProvider.chats.firstWhere((c) => c.id == widget.chatId).participants.firstWhere((p) => p.id == message.senderId, orElse: () => UserModel(id: 'unknown', name: 'Unknown', email: '')).name);
                        final timeStr = DateFormat.jm().format(message.timestamp);

                        final showSender = !isMe && 
                            (index == 0 || messages[index - 1].senderId != message.senderId);
                        
                        return _GroupMessageBubble(
                          text: message.content,
                          sender: senderName,
                          isMe: isMe,
                          time: timeStr,
                          showSender: showSender,
                        )
                            .animate()
                            .fadeIn(duration: 200.ms)
                            .slideY(begin: 0.1, end: 0);
                      },
                    );
                  },
                ),
              ),
              
              // Message Input
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).brightness == Brightness.light 
                        ? Colors.black.withOpacity(0.05) 
                        : Colors.white.withOpacity(0.02),
                      blurRadius: 10,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: SafeArea(
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.attach_file),
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Attach file')),
                          );
                        },
                      ),
                      Expanded(
                        child: TextField(
                          controller: _messageController,
                          decoration: InputDecoration(
                            hintText: 'Type a message...',
                            filled: true,
                            fillColor: Theme.of(context).brightness == Brightness.light
                                ? Colors.black.withOpacity(0.05)
                                : Colors.white.withOpacity(0.06),
                            border: OutlineInputBorder(
                              borderRadius: AppTheme.borderRadiusLarge,
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.emoji_emotions_outlined),
                              color: AppTheme.textSecondary,
                              onPressed: () {},
                            ),
                          ),
                          onChanged: (text) {
                            setState(() => _isTyping = text.isNotEmpty);
                          },
                          onSubmitted: _sendMessage,
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () {
                          if (_isTyping) {
                            _sendMessage(_messageController.text);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Voice message')),
                            );
                          }
                        },
                        child: Container(
                          width: 50,
                          height: 50,
                          decoration: const BoxDecoration(
                            gradient: AppTheme.primaryGradient,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _isTyping ? Icons.send : Icons.mic,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          
          // Animated Character
          Positioned(
            right: 16,
            bottom: 150,
            child: AnimatedHumanCharacter(
              mood: _characterMood,
              size: 70,
            ),
          ),
        ],
      ),
    );
  }

  void _showGroupInfo() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(20),
          child: ListView(
            controller: scrollController,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.textLight.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Center(
                child: AppAvatar(
                  name: widget.groupName,
                  size: 100,
                  icon: Icons.group_rounded,
                  isCircle: true,
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: Text(
                  widget.groupName,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
              Center(
                child: Text(
                  'Group • ${_members.length} members',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _GroupActionButton(
                    icon: Icons.notifications_off,
                    label: 'Mute',
                    onTap: () {},
                  ),
                  const SizedBox(width: 20),
                  _GroupActionButton(
                    icon: Icons.search,
                    label: 'Search',
                    onTap: () {},
                  ),
                  const SizedBox(width: 20),
                  _GroupActionButton(
                    icon: Icons.photo_library,
                    label: 'Media',
                    onTap: () {},
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                'Members',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              ..._members.map((member) => ListTile(
                leading: AppAvatar(
                  name: member,
                  size: 45,
                  isCircle: true,
                ),
                title: Text(member),
                subtitle: Text(member == 'You' ? 'You' : 'Member'),
                trailing: member == 'You' 
                    ? null 
                    : IconButton(
                        icon: const Icon(Icons.more_vert),
                        onPressed: () {},
                      ),
              )),
            ],
          ),
        ),
      ),
    );
  }

  void _showLeaveDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Leave group?'),
        content: Text('Are you sure you want to leave "${widget.groupName}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('You left ${widget.groupName}')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            child: const Text('Leave'),
          ),
        ],
      ),
    );
  }
}

class _GroupMessageBubble extends StatelessWidget {
  final String text;
  final String sender;
  final bool isMe;
  final String time;
  final bool showSender;

  const _GroupMessageBubble({
    required this.text,
    required this.sender,
    required this.isMe,
    required this.time,
    this.showSender = true,
  });

  Color get _senderColor {
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.pink,
    ];
    return colors[sender.hashCode % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            showSender
                ? AppAvatar(
                    name: sender,
                    size: 32,
                    isCircle: true,
                  )
                : const SizedBox(width: 32),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                if (showSender && !isMe)
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 4),
                    child: Text(
                      sender,
                      style: TextStyle(
                        color: _senderColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: isMe ? AppTheme.primaryGradient : null,
                    color: isMe ? null : Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(20),
                      topRight: const Radius.circular(20),
                      bottomLeft: Radius.circular(isMe ? 20 : 4),
                      bottomRight: Radius.circular(isMe ? 4 : 20),
                    ),
                    boxShadow: AppTheme.softShadow,
                  ),
                  child: Text(
                    text,
                    style: TextStyle(
                      color: isMe ? Colors.white : Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  time,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          if (isMe) const SizedBox(width: 40),
        ],
      ),
    );
  }
}

class _GroupActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _GroupActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppTheme.primary),
          ),
          const SizedBox(height: 8),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}
