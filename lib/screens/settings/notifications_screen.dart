import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../theme/app_theme.dart';

class NotificationsSettingsScreen extends StatefulWidget {
  const NotificationsSettingsScreen({super.key});

  @override
  State<NotificationsSettingsScreen> createState() => _NotificationsSettingsScreenState();
}

class _NotificationsSettingsScreenState extends State<NotificationsSettingsScreen> {
  bool _messageNotifications = true;
  bool _groupNotifications = true;
  bool _callNotifications = true;
  bool _showPreview = true;
  bool _vibrate = true;
  bool _sound = true;
  String _messageTone = 'Default';
  String _groupTone = 'Default';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Notifications'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Message Notifications
            _SectionTitle(title: 'Message Notifications')
                .animate()
                .fadeIn(duration: 300.ms),
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
                    title: const Text('Message Notifications'),
                    subtitle: const Text('Show notifications for new messages'),
                    value: _messageNotifications,
                    onChanged: (value) => setState(() => _messageNotifications = value),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    title: const Text('Notification Tone'),
                    subtitle: Text(_messageTone),
                    trailing: const Icon(Icons.chevron_right, color: AppTheme.textLight),
                    onTap: () => _showTonePicker('message'),
                  ),
                ],
              ),
            )
                .animate()
                .fadeIn(delay: 100.ms, duration: 300.ms),

            const SizedBox(height: 24),

            // Group Notifications
            _SectionTitle(title: 'Group Notifications')
                .animate()
                .fadeIn(delay: 200.ms, duration: 300.ms),
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
                    title: const Text('Group Notifications'),
                    subtitle: const Text('Show notifications for group messages'),
                    value: _groupNotifications,
                    onChanged: (value) => setState(() => _groupNotifications = value),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    title: const Text('Notification Tone'),
                    subtitle: Text(_groupTone),
                    trailing: const Icon(Icons.chevron_right, color: AppTheme.textLight),
                    onTap: () => _showTonePicker('group'),
                  ),
                ],
              ),
            )
                .animate()
                .fadeIn(delay: 300.ms, duration: 300.ms),

            const SizedBox(height: 24),

            // Call Notifications
            _SectionTitle(title: 'Call Notifications')
                .animate()
                .fadeIn(delay: 400.ms, duration: 300.ms),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: AppTheme.borderRadiusMedium,
                boxShadow: AppTheme.softShadow,
              ),
              child: SwitchListTile(
                title: const Text('Call Notifications'),
                subtitle: const Text('Show notifications for incoming calls'),
                value: _callNotifications,
                onChanged: (value) => setState(() => _callNotifications = value),
              ),
            )
                .animate()
                .fadeIn(delay: 500.ms, duration: 300.ms),

            const SizedBox(height: 24),

            // Other Settings
            _SectionTitle(title: 'Other')
                .animate()
                .fadeIn(delay: 600.ms, duration: 300.ms),
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
                    title: const Text('Show Preview'),
                    subtitle: const Text('Show message content in notifications'),
                    value: _showPreview,
                    onChanged: (value) => setState(() => _showPreview = value),
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    title: const Text('Vibration'),
                    subtitle: const Text('Vibrate for notifications'),
                    value: _vibrate,
                    onChanged: (value) => setState(() => _vibrate = value),
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    title: const Text('Sound'),
                    subtitle: const Text('Play sound for notifications'),
                    value: _sound,
                    onChanged: (value) => setState(() => _sound = value),
                  ),
                ],
              ),
            )
                .animate()
                .fadeIn(delay: 700.ms, duration: 300.ms),
          ],
        ),
      ),
    );
  }

  void _showTonePicker(String type) {
    final tones = ['Default', 'Chime', 'Bell', 'Ping', 'Pop', 'None'];
    
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select Tone',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            ...tones.map((tone) => ListTile(
              title: Text(tone),
              trailing: (type == 'message' ? _messageTone : _groupTone) == tone
                  ? const Icon(Icons.check, color: AppTheme.primary)
                  : null,
              onTap: () {
                setState(() {
                  if (type == 'message') {
                    _messageTone = tone;
                  } else {
                    _groupTone = tone;
                  }
                });
                Navigator.pop(context);
              },
            )),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        color: AppTheme.primary,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
