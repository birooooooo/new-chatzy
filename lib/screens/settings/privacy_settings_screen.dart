import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../theme/app_theme.dart';

class PrivacySettingsScreen extends StatefulWidget {
  const PrivacySettingsScreen({super.key});

  @override
  State<PrivacySettingsScreen> createState() => _PrivacySettingsScreenState();
}

class _PrivacySettingsScreenState extends State<PrivacySettingsScreen> {
  String _lastSeen = 'Everyone';
  String _profilePhoto = 'My Contacts';
  String _about = 'My Contacts';
  String _status = 'My Contacts';
  bool _readReceipts = true;
  bool _twoFactorAuth = false;
  bool _fingerprintLock = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Privacy'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Who can see my personal info
            _SectionTitle(title: 'Who can see my personal info')
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
                  _PrivacyOption(
                    title: 'Last Seen',
                    value: _lastSeen,
                    onTap: () => _showPrivacyPicker('Last Seen', _lastSeen, (v) => setState(() => _lastSeen = v)),
                  ),
                  const Divider(height: 1),
                  _PrivacyOption(
                    title: 'Profile Photo',
                    value: _profilePhoto,
                    onTap: () => _showPrivacyPicker('Profile Photo', _profilePhoto, (v) => setState(() => _profilePhoto = v)),
                  ),
                  const Divider(height: 1),
                  _PrivacyOption(
                    title: 'About',
                    value: _about,
                    onTap: () => _showPrivacyPicker('About', _about, (v) => setState(() => _about = v)),
                  ),
                  const Divider(height: 1),
                  _PrivacyOption(
                    title: 'Status',
                    value: _status,
                    onTap: () => _showPrivacyPicker('Status', _status, (v) => setState(() => _status = v)),
                  ),
                ],
              ),
            )
                .animate()
                .fadeIn(delay: 100.ms, duration: 300.ms),

            const SizedBox(height: 24),

            // Messaging
            _SectionTitle(title: 'Messaging')
                .animate()
                .fadeIn(delay: 200.ms, duration: 300.ms),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: AppTheme.borderRadiusMedium,
                boxShadow: AppTheme.softShadow,
              ),
              child: SwitchListTile(
                title: const Text('Read Receipts'),
                subtitle: const Text('Let others know when you\'ve read their messages'),
                value: _readReceipts,
                onChanged: (value) => setState(() => _readReceipts = value),
              ),
            )
                .animate()
                .fadeIn(delay: 300.ms, duration: 300.ms),

            const SizedBox(height: 24),

            // Security
            _SectionTitle(title: 'Security')
                .animate()
                .fadeIn(delay: 400.ms, duration: 300.ms),
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
                    title: const Text('Two-Factor Authentication'),
                    subtitle: const Text('Add extra security to your account'),
                    value: _twoFactorAuth,
                    onChanged: (value) {
                      setState(() => _twoFactorAuth = value);
                      if (value) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('2FA setup will be configured')),
                        );
                      }
                    },
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    title: const Text('Fingerprint Lock'),
                    subtitle: const Text('Require fingerprint to open app'),
                    value: _fingerprintLock,
                    onChanged: (value) => setState(() => _fingerprintLock = value),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    title: const Text('Change PIN'),
                    subtitle: const Text('Update your security PIN'),
                    trailing: const Icon(Icons.chevron_right, color: AppTheme.textLight),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Change PIN')),
                      );
                    },
                  ),
                ],
              ),
            )
                .animate()
                .fadeIn(delay: 500.ms, duration: 300.ms),

            const SizedBox(height: 24),

            // Advanced
            _SectionTitle(title: 'Advanced')
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
                  ListTile(
                    leading: const Icon(Icons.download, color: AppTheme.primary),
                    title: const Text('Download My Data'),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Preparing data download...')),
                      );
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.delete_forever, color: AppTheme.error),
                    title: const Text('Delete Account', style: TextStyle(color: AppTheme.error)),
                    onTap: () => _showDeleteAccountDialog(),
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

  void _showPrivacyPicker(String title, String currentValue, Function(String) onChanged) {
    final options = ['Everyone', 'My Contacts', 'Nobody'];
    
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
              title,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            ...options.map((option) => ListTile(
              title: Text(option),
              trailing: currentValue == option
                  ? const Icon(Icons.check, color: AppTheme.primary)
                  : null,
              onTap: () {
                onChanged(option);
                Navigator.pop(context);
              },
            )),
          ],
        ),
      ),
    );
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text(
          'This will permanently delete your account and all data. This action cannot be undone.',
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
                const SnackBar(
                  content: Text('Account deletion requested'),
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

class _PrivacyOption extends StatelessWidget {
  final String title;
  final String value;
  final VoidCallback onTap;

  const _PrivacyOption({
    required this.title,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(title),
      subtitle: Text(value),
      trailing: const Icon(Icons.chevron_right, color: AppTheme.textLight),
      onTap: onTap,
    );
  }
}
