import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../theme/app_theme.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('About'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // App Info Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: AppTheme.borderRadiusLarge,
                boxShadow: AppTheme.cardShadow,
              ),
              child: Column(
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.chat_bubble, color: AppTheme.primary, size: 50),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'ChatApp',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Version 1.0.0',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      '🚀 Professional Chat Experience',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            )
                .animate()
                .fadeIn(duration: 300.ms)
                .scale(begin: const Offset(0.95, 0.95), end: const Offset(1, 1)),

            const SizedBox(height: 24),

            // Features
            Container(
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: AppTheme.borderRadiusMedium,
                boxShadow: AppTheme.softShadow,
              ),
              child: Column(
                children: [
                  _FeatureTile(
                    icon: Icons.smart_toy,
                    title: 'AI-Powered',
                    description: 'Smart suggestions and chat analysis',
                    color: AppTheme.accent,
                  ),
                  const Divider(height: 1),
                  _FeatureTile(
                    icon: Icons.translate,
                    title: 'Translation',
                    description: 'Translate messages in real-time',
                    color: AppTheme.info,
                  ),
                  const Divider(height: 1),
                  _FeatureTile(
                    icon: Icons.security,
                    title: 'Secure',
                    description: 'End-to-end encryption',
                    color: AppTheme.success,
                  ),
                  const Divider(height: 1),
                  _FeatureTile(
                    icon: Icons.speed,
                    title: 'Fast',
                    description: 'Lightning-fast message delivery',
                    color: Colors.orange,
                  ),
                ],
              ),
            )
                .animate()
                .fadeIn(delay: 100.ms, duration: 300.ms),

            const SizedBox(height: 24),

            // Links
            Container(
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: AppTheme.borderRadiusMedium,
                boxShadow: AppTheme.softShadow,
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.help, color: AppTheme.primary),
                    title: const Text('Help Center'),
                    trailing: const Icon(Icons.open_in_new, color: AppTheme.textLight, size: 18),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Opening Help Center...')),
                      );
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.privacy_tip, color: AppTheme.primary),
                    title: const Text('Privacy Policy'),
                    trailing: const Icon(Icons.open_in_new, color: AppTheme.textLight, size: 18),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Opening Privacy Policy...')),
                      );
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.description, color: AppTheme.primary),
                    title: const Text('Terms of Service'),
                    trailing: const Icon(Icons.open_in_new, color: AppTheme.textLight, size: 18),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Opening Terms of Service...')),
                      );
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.code, color: AppTheme.primary),
                    title: const Text('Open Source Licenses'),
                    trailing: const Icon(Icons.chevron_right, color: AppTheme.textLight),
                    onTap: () {
                      showLicensePage(
                        context: context,
                        applicationName: 'ChatApp',
                        applicationVersion: '1.0.0',
                      );
                    },
                  ),
                ],
              ),
            )
                .animate()
                .fadeIn(delay: 200.ms, duration: 300.ms),

            const SizedBox(height: 24),

            // Contact & Support
            Container(
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: AppTheme.borderRadiusMedium,
                boxShadow: AppTheme.softShadow,
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.email, color: AppTheme.primary),
                    title: const Text('Contact Support'),
                    subtitle: const Text('support@chatapp.com'),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Opening email client...')),
                      );
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.star, color: AppTheme.accent),
                    title: const Text('Rate Us'),
                    subtitle: const Text('Love the app? Leave a review!'),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Opening App Store...')),
                      );
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.share, color: AppTheme.primary),
                    title: const Text('Share App'),
                    subtitle: const Text('Tell your friends about ChatApp'),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Share dialog opened')),
                      );
                    },
                  ),
                ],
              ),
            )
                .animate()
                .fadeIn(delay: 300.ms, duration: 300.ms),

            const SizedBox(height: 24),

            // Check for Updates
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('You\'re using the latest version!'),
                      backgroundColor: AppTheme.success,
                    ),
                  );
                },
                icon: const Icon(Icons.system_update),
                label: const Text('Check for Updates'),
              ),
            )
                .animate()
                .fadeIn(delay: 400.ms, duration: 300.ms),

            const SizedBox(height: 24),

            // Footer
            Text(
              '© 2024 ChatApp. All rights reserved.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.textLight,
              ),
            )
                .animate()
                .fadeIn(delay: 500.ms, duration: 300.ms),

            const SizedBox(height: 8),

            Text(
              'Made with ❤️',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.textLight,
              ),
            )
                .animate()
                .fadeIn(delay: 600.ms, duration: 300.ms),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _FeatureTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Color color;

  const _FeatureTile({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: color),
      ),
      title: Text(title),
      subtitle: Text(description, style: Theme.of(context).textTheme.bodySmall),
    );
  }
}
