import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../theme/app_theme.dart';

class BlockListScreen extends StatefulWidget {
  const BlockListScreen({super.key});

  @override
  State<BlockListScreen> createState() => _BlockListScreenState();
}

class _BlockListScreenState extends State<BlockListScreen> {
  final List<Map<String, String>> _blockedUsers = [
    {'name': 'Spam Account', 'phone': '+1 555 000 0001'},
    {'name': 'Unknown User', 'phone': '+1 555 000 0002'},
    {'name': 'Blocked Contact', 'phone': '+1 555 000 0003'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Blocked Users'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add),
            onPressed: () => _showAddBlockedUserDialog(),
          ),
        ],
      ),
      body: _blockedUsers.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _blockedUsers.length,
              itemBuilder: (context, index) {
                final user = _blockedUsers[index];
                return _BlockedUserItem(
                  name: user['name']!,
                  phone: user['phone']!,
                  onUnblock: () => _unblockUser(index),
                )
                    .animate()
                    .fadeIn(delay: Duration(milliseconds: index * 50))
                    .slideX(begin: 0.05, end: 0);
              },
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.block,
            size: 80,
            color: AppTheme.textLight.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No blocked users',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: AppTheme.textLight,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Blocked contacts can\'t call you or send messages',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.textLight,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      )
          .animate()
          .fadeIn(duration: 300.ms),
    );
  }

  void _unblockUser(int index) {
    final user = _blockedUsers[index];
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Unblock ${user['name']}?'),
        content: const Text('This contact will be able to call you and send messages.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() => _blockedUsers.removeAt(index));
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${user['name']} unblocked')),
              );
            },
            child: const Text('Unblock'),
          ),
        ],
      ),
    );
  }

  void _showAddBlockedUserDialog() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Select a contact to block')),
    );
  }
}

class _BlockedUserItem extends StatelessWidget {
  final String name;
  final String phone;
  final VoidCallback onUnblock;

  const _BlockedUserItem({
    required this.name,
    required this.phone,
    required this.onUnblock,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: AppTheme.borderRadiusMedium,
        boxShadow: AppTheme.softShadow,
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: AppTheme.error.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.person, color: AppTheme.error),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: Theme.of(context).textTheme.titleMedium),
                Text(phone, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          TextButton(
            onPressed: onUnblock,
            child: const Text('Unblock'),
          ),
        ],
      ),
    );
  }
}
