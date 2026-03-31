import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../../widgets/glass_container.dart';
import '../settings/ai_account_settings_screen.dart';
import '../settings/notifications_screen.dart';
import '../settings/privacy_settings_screen.dart';
import '../settings/theme_settings_screen.dart';
import '../settings/about_screen.dart';
import '../profile/profile_screen.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../providers/theme_provider.dart';
import '../../widgets/app_widgets.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            floating: true,
            backgroundColor: Colors.transparent,
            title: Text(
              'Settings',
              style: GoogleFonts.inter(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            automaticallyImplyLeading: false,
          ),
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Profile Card
                _ProfileCard()
                    .animate()
                    .fadeIn(duration: 250.ms)
                    .slideY(begin: 0.1, end: 0),

                const SizedBox(height: 28),

                // Background Selector
                const _BackgroundSelector()
                    .animate()
                    .fadeIn(delay: 60.ms, duration: 250.ms)
                    .slideY(begin: 0.1, end: 0),

                const SizedBox(height: 28),

                // AI Features
                _SettingsSection(
                  title: 'AI Features',
                  items: [
                    _SettingsItem(
                      icon: Icons.smart_toy_rounded,
                      title: 'AI Account',
                      subtitle: 'Manage AI settings',
                      iconColor: AppTheme.secondary,
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(
                          builder: (context) => const AiAccountSettingsScreen(),
                        ));
                      },
                    ),
                  ],
                ).animate()
                    .fadeIn(delay: 120.ms, duration: 250.ms)
                    .slideY(begin: 0.1, end: 0),

                const SizedBox(height: 20),

                // General Settings
                _SettingsSection(
                  title: 'General',
                  items: [
                    _SettingsItem(
                      icon: Icons.notifications_rounded,
                      title: 'Notifications',
                      subtitle: 'Message alerts & sounds',
                      iconColor: AppTheme.warning,
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(
                          builder: (context) => const NotificationsSettingsScreen(),
                        ));
                      },
                    ),
                    _SettingsItem(
                      icon: Icons.privacy_tip_rounded,
                      title: 'Privacy',
                      subtitle: 'Security settings',
                      iconColor: AppTheme.info,
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(
                          builder: (context) => const PrivacySettingsScreen(),
                        ));
                      },
                    ),
                    _SettingsItem(
                      icon: Icons.palette_rounded,
                      title: 'Theme',
                      subtitle: 'App appearance',
                      iconColor: AppTheme.accent,
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(
                          builder: (context) => const ThemeSettingsScreen(),
                        ));
                      },
                    ),
                  ],
                ).animate()
                    .fadeIn(delay: 180.ms, duration: 250.ms)
                    .slideY(begin: 0.1, end: 0),

                const SizedBox(height: 20),

                // Support
                _SettingsSection(
                  title: 'Support',
                  items: [
                    _SettingsItem(
                      icon: Icons.info_rounded,
                      title: 'About',
                      subtitle: 'App version & info',
                      iconColor: Colors.grey,
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(
                          builder: (context) => const AboutScreen(),
                        ));
                      },
                    ),
                  ],
                ).animate()
                    .fadeIn(delay: 240.ms, duration: 250.ms)
                    .slideY(begin: 0.1, end: 0),

                const SizedBox(height: 32),

                // Logout Button
                _LogoutButton()
                    .animate()
                    .fadeIn(delay: 280.ms, duration: 250.ms),

                const SizedBox(height: 24),

                // Version
                Center(
                  child: Text(
                    'CHATZY v1.0.0',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                      fontSize: 12,
                    ),
                  ),
                ),

                const SizedBox(height: 120),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(
          builder: (context) => const ProfileScreen(),
        ));
      },
      child: Consumer<AuthService>(
        builder: (context, authService, child) {
          final user = authService.currentUser;
          return GlassContainer(
            padding: const EdgeInsets.all(16),
            borderRadius: BorderRadius.circular(20),
            blur: 15,
            gradient: AppTheme.primaryGradient,
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
              width: 0.5,
            ),
            child: Row(
              children: [
                AppAvatar(
                  name: user?.name ?? 'User',
                  size: 60,
                  imageUrl: user?.avatar,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user?.name ?? 'User',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user?.email ?? 'No email set',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: Colors.white.withOpacity(0.7)),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _BackgroundSelector extends StatelessWidget {
  const _BackgroundSelector();

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Background Style',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 100,
          child: ListView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            children: [
              _buildOption(context, themeProvider, BackgroundStyle.nebula, 'Nebula'),
              _buildOption(context, themeProvider, BackgroundStyle.deepBlack, 'Pure Black'),
              _buildOption(context, themeProvider, BackgroundStyle.midnightGradient, 'Midnight'),
              _buildOption(context, themeProvider, BackgroundStyle.oceanMist, 'Ocean'),
              _buildOption(context, themeProvider, BackgroundStyle.cyberPurple, 'Cyber'),
              _buildOption(context, themeProvider, BackgroundStyle.glassMesh, 'Glass Mesh'),
              _buildOption(context, themeProvider, BackgroundStyle.pureWhite, 'Pure White'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOption(BuildContext context, ThemeProvider provider, BackgroundStyle style, String label) {
    final isSelected = provider.backgroundStyle == style;
    
    return GestureDetector(
      onTap: () => provider.setBackgroundStyle(style),
      child: Container(
        width: 120,
        margin: const EdgeInsets.only(right: 12),
        child: Column(
          children: [
            Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected ? AppTheme.secondary : Colors.white.withOpacity(0.1),
                    width: isSelected ? 2 : 1,
                  ),
                  boxShadow: isSelected ? [
                    BoxShadow(
                      color: AppTheme.secondary.withOpacity(0.3),
                      blurRadius: 10,
                      spreadRadius: 2,
                    )
                  ] : [],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    decoration: _getStaticDecoration(style),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? (style == BackgroundStyle.pureWhite
                        ? const Color(0xFF1E293B)
                        : Colors.white)
                    : Colors.white.withOpacity(0.5),
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Decoration _getStaticDecoration(BackgroundStyle style) {
    switch (style) {
      case BackgroundStyle.nebula:
        return const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/app_bg.png'),
            fit: BoxFit.cover,
          ),
        );
      case BackgroundStyle.deepBlack:
        return const BoxDecoration(color: Color(0xFF000000));
      case BackgroundStyle.midnightGradient:
        return const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0F172A), Color(0xFF1E1B4B)],
          ),
        );
      case BackgroundStyle.oceanMist:
        return const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF064E3B), Color(0xFF0F766E)],
          ),
        );
      case BackgroundStyle.cyberPurple:
        return const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF2E1065), Color(0xFF4C1D95)],
          ),
        );
      case BackgroundStyle.glassMesh:
        return const BoxDecoration(
          gradient: RadialGradient(
            colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
          ),
        );
      case BackgroundStyle.pureWhite:
        return const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFFFFFF), Color(0xFFF0F4FF)],
          ),
        );
    }
  }
}

class _SettingsSection extends StatelessWidget {
  final String title;
  final List<_SettingsItem> items;

  const _SettingsSection({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        GlassContainer(
          borderRadius: BorderRadius.circular(16),
          opacity: 0.05,
          blur: 10,
          child: Column(
            children: items.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              return Column(
                children: [
                  item,
                  if (index < items.length - 1)
                    Divider(
                      height: 1,
                      indent: 60,
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.06),
                    ),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _SettingsItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color iconColor;
  final VoidCallback onTap;

  const _SettingsItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.15),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: iconColor, size: 22),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle: Text(
        subtitle,
        style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4), fontSize: 12),
      ),
      trailing: Icon(Icons.chevron_right, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3), size: 20),
    );
  }
}

class _LogoutButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: () {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: AppTheme.surface,
            title: const Text('Log Out'),
            content: const Text('Are you sure you want to log out?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () async {
                  final authService = Provider.of<AuthService>(context, listen: false);
                  await authService.signOut();
                  if (context.mounted) {
                    Navigator.pop(context);
                    Navigator.pushReplacementNamed(context, '/login');
                  }
                },
                child: const Text('Log Out', style: TextStyle(color: AppTheme.error)),
              ),
            ],
          ),
        );
      },
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: AppTheme.error.withOpacity(0.5)),
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: const Text(
        'Log Out',
        style: TextStyle(color: AppTheme.error, fontWeight: FontWeight.w600),
      ),
    );
  }
}
