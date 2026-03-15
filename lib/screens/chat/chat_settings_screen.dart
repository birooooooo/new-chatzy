import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../theme/app_theme.dart';

class ChatSettingsScreen extends StatefulWidget {
  final String userName;

  const ChatSettingsScreen({super.key, required this.userName});

  @override
  State<ChatSettingsScreen> createState() => _ChatSettingsScreenState();
}

class _ChatSettingsScreenState extends State<ChatSettingsScreen> {
  bool _isMuted = false;
  bool _customNotifications = true;
  String _nickname = '';
  String _wallpaper = 'default';

  @override
  void initState() {
    super.initState();
    _nickname = widget.userName;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Chat Settings'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User Info Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: AppTheme.borderRadiusMedium,
                boxShadow: AppTheme.softShadow,
              ),
              child: Row(
                children: [
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      gradient: AppTheme.primaryGradient,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.person, color: Colors.white, size: 35),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.userName,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Online',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.online,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )
                .animate()
                .fadeIn(duration: 300.ms),

            const SizedBox(height: 24),

            // Nickname Section
            Text(
              'Customization',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppTheme.primary,
                fontWeight: FontWeight.w600,
              ),
            )
                .animate()
                .fadeIn(delay: 100.ms, duration: 300.ms),

            const SizedBox(height: 12),

            Container(
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: AppTheme.borderRadiusMedium,
                boxShadow: AppTheme.softShadow,
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppTheme.accent.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.edit, color: AppTheme.accent),
                    ),
                    title: const Text('Nickname'),
                    subtitle: Text(_nickname),
                    trailing: const Icon(Icons.chevron_right, color: AppTheme.textLight),
                    onTap: () => _showNicknameDialog(),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.purple.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.wallpaper, color: Colors.purple),
                    ),
                    title: const Text('Chat Wallpaper'),
                    subtitle: Text(_wallpaper == 'default' ? 'Default' : 'Custom'),
                    trailing: const Icon(Icons.chevron_right, color: AppTheme.textLight),
                    onTap: () => _showWallpaperPicker(),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.color_lens, color: Colors.orange),
                    ),
                    title: const Text('Chat Theme'),
                    subtitle: const Text('Default Blue'),
                    trailing: const Icon(Icons.chevron_right, color: AppTheme.textLight),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Theme picker opened')),
                      );
                    },
                  ),
                ],
              ),
            )
                .animate()
                .fadeIn(delay: 200.ms, duration: 300.ms),

            const SizedBox(height: 24),

            // Notifications Section
            Text(
              'Notifications',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppTheme.primary,
                fontWeight: FontWeight.w600,
              ),
            )
                .animate()
                .fadeIn(delay: 300.ms, duration: 300.ms),

            const SizedBox(height: 12),

            Container(
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: AppTheme.borderRadiusMedium,
                boxShadow: AppTheme.softShadow,
              ),
              child: Column(
                children: [
                  SwitchListTile(
                    secondary: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppTheme.error.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        _isMuted ? Icons.volume_off : Icons.volume_up,
                        color: AppTheme.error,
                      ),
                    ),
                    title: const Text('Mute Notifications'),
                    subtitle: Text(_isMuted ? 'Muted' : 'Not muted'),
                    value: _isMuted,
                    onChanged: (value) {
                      setState(() => _isMuted = value);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(value 
                              ? '${widget.userName} muted' 
                              : '${widget.userName} unmuted'),
                        ),
                      );
                    },
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    secondary: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppTheme.info.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.notifications, color: AppTheme.info),
                    ),
                    title: const Text('Custom Notifications'),
                    subtitle: const Text('Use different tone'),
                    value: _customNotifications,
                    onChanged: (value) {
                      setState(() => _customNotifications = value);
                    },
                  ),
                ],
              ),
            )
                .animate()
                .fadeIn(delay: 400.ms, duration: 300.ms),

            const SizedBox(height: 24),

            // Actions Section
            Text(
              'Actions',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppTheme.primary,
                fontWeight: FontWeight.w600,
              ),
            )
                .animate()
                .fadeIn(delay: 500.ms, duration: 300.ms),

            const SizedBox(height: 12),

            Container(
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: AppTheme.borderRadiusMedium,
                boxShadow: AppTheme.softShadow,
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppTheme.success.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.search, color: AppTheme.success),
                    ),
                    title: const Text('Search in Chat'),
                    trailing: const Icon(Icons.chevron_right, color: AppTheme.textLight),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Search in chat')),
                      );
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.teal.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.download, color: Colors.teal),
                    ),
                    title: const Text('Export Chat'),
                    trailing: const Icon(Icons.chevron_right, color: AppTheme.textLight),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Exporting chat...')),
                      );
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppTheme.error.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.block, color: AppTheme.error),
                    ),
                    title: Text(
                      'Block ${widget.userName}',
                      style: const TextStyle(color: AppTheme.error),
                    ),
                    onTap: () => _showBlockDialog(),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppTheme.error.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.delete, color: AppTheme.error),
                    ),
                    title: const Text(
                      'Delete Chat',
                      style: TextStyle(color: AppTheme.error),
                    ),
                    onTap: () => _showDeleteDialog(),
                  ),
                ],
              ),
            )
                .animate()
                .fadeIn(delay: 600.ms, duration: 300.ms),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  void _showNicknameDialog() {
    final controller = TextEditingController(text: _nickname);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Set Nickname'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Nickname',
            hintText: 'Enter a custom name',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() => _nickname = controller.text);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Nickname changed to ${controller.text}')),
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showWallpaperPicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Choose Wallpaper',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 100,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _WallpaperOption(
                    color: AppTheme.background,
                    label: 'Default',
                    isSelected: _wallpaper == 'default',
                    onTap: () {
                      setState(() => _wallpaper = 'default');
                      Navigator.pop(context);
                    },
                  ),
                  _WallpaperOption(
                    color: Colors.blue.shade100,
                    label: 'Sky',
                    isSelected: _wallpaper == 'sky',
                    onTap: () {
                      setState(() => _wallpaper = 'sky');
                      Navigator.pop(context);
                    },
                  ),
                  _WallpaperOption(
                    color: Colors.green.shade100,
                    label: 'Nature',
                    isSelected: _wallpaper == 'nature',
                    onTap: () {
                      setState(() => _wallpaper = 'nature');
                      Navigator.pop(context);
                    },
                  ),
                  _WallpaperOption(
                    color: Colors.purple.shade100,
                    label: 'Purple',
                    isSelected: _wallpaper == 'purple',
                    onTap: () {
                      setState(() => _wallpaper = 'purple');
                      Navigator.pop(context);
                    },
                  ),
                  _WallpaperOption(
                    color: Colors.orange.shade100,
                    label: 'Sunset',
                    isSelected: _wallpaper == 'sunset',
                    onTap: () {
                      setState(() => _wallpaper = 'sunset');
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Choose from gallery')),
                  );
                },
                icon: const Icon(Icons.photo_library),
                label: const Text('Choose from Gallery'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showBlockDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Block ${widget.userName}?'),
        content: Text(
          'Blocked contacts will no longer be able to call you or send you messages.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${widget.userName} has been blocked'),
                  backgroundColor: AppTheme.error,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            child: const Text('Block'),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Chat?'),
        content: const Text(
          'This will delete all messages in this chat. This action cannot be undone.',
        ),
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
                const SnackBar(
                  content: Text('Chat deleted'),
                  backgroundColor: AppTheme.error,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _WallpaperOption extends StatelessWidget {
  final Color color;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _WallpaperOption({
    required this.color,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 80,
        margin: const EdgeInsets.only(right: 12),
        child: Column(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? AppTheme.primary : Colors.transparent,
                  width: 3,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.check, color: AppTheme.primary)
                  : null,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
