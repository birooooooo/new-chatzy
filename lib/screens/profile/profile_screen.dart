import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../theme/app_theme.dart';
import '../../widgets/glass_container.dart';
import 'dart:ui';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const EditProfileScreen()),
              );
            },
          ),
        ],
      ),
      body: Consumer<AuthService>(
        builder: (context, authService, child) {
          final user = authService.currentUser;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Profile Header
                GlassContainer(
                  padding: const EdgeInsets.all(24),
                  borderRadius: BorderRadius.circular(32),
                  blur: 20,
                  gradient: AppTheme.primaryGradient,
                  border: Border.all(color: Colors.white.withOpacity(0.2), width: 0.5),
                  child: Column(
                    children: [
                      Stack(
                        children: [
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white.withOpacity(0.2), width: 4),
                              image: user?.avatar != null 
                                  ? DecorationImage(image: NetworkImage(user!.avatar!), fit: BoxFit.cover) 
                                  : null,
                            ),
                            child: user?.avatar == null 
                                ? const Icon(Icons.person, size: 50, color: Colors.white)
                                : null,
                          ),
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: const BoxDecoration(
                                color: AppTheme.secondary,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.camera_alt, size: 16, color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        user?.name ?? 'User',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user?.email ?? 'No email set',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                )
                    .animate()
                    .fadeIn(duration: 300.ms)
                    .slideY(begin: 0.1, end: 0),

                const SizedBox(height: 24),

                // Stats
                Row(
                  children: [
                    const Expanded(
                      child: _StatCard(
                        icon: Icons.chat,
                        value: '156',
                        label: 'Chats',
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: _StatCard(
                        icon: Icons.group,
                        value: '12',
                        label: 'Groups',
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: _StatCard(
                        icon: Icons.photo,
                        value: '89',
                        label: 'Media',
                      ),
                    ),
                  ],
                )
                    .animate()
                    .fadeIn(delay: 100.ms, duration: 300.ms),

                const SizedBox(height: 24),

                // Info Section
                GlassContainer(
                  borderRadius: BorderRadius.circular(24),
                  opacity: 0.05,
                  blur: 15,
                  border: Border.all(color: Colors.white.withOpacity(0.1), width: 0.5),
                  child: Column(
                    children: [
                      _InfoTile(
                        icon: Icons.info_outline,
                        title: 'About',
                        value: 'Hey there! I\'m using ChatApp',
                        onTap: () {},
                      ),
                      _InfoTile(
                        icon: Icons.email_outlined,
                        title: 'Email',
                        value: user?.email ?? 'N/A',
                        onTap: () {},
                      ),
                      _InfoTile(
                        icon: Icons.cake_outlined,
                        title: 'Birthday',
                        value: 'January 15, 1990',
                        onTap: () {},
                      ),
                      _InfoTile(
                        icon: Icons.location_on_outlined,
                        title: 'Location',
                        value: 'New York, USA',
                        onTap: () {},
                      ),
                    ],
                  ),
                )
                    .animate()
                    .fadeIn(delay: 200.ms, duration: 300.ms),

                const SizedBox(height: 24),

                // Quick Actions
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Share profile')),
                          );
                        },
                        icon: const Icon(Icons.share),
                        label: const Text('Share Profile'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Show QR code')),
                          );
                        },
                        icon: const Icon(Icons.qr_code),
                        label: const Text('QR Code'),
                      ),
                    ),
                  ],
                )
                    .animate()
                    .fadeIn(delay: 300.ms, duration: 300.ms),

                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      padding: const EdgeInsets.all(16),
      borderRadius: BorderRadius.circular(20),
      opacity: 0.05,
      blur: 10,
      border: Border.all(color: Colors.white.withOpacity(0.1), width: 0.5),
      child: Column(
        children: [
          Icon(icon, color: AppTheme.secondary),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final VoidCallback onTap;

  const _InfoTile({
    required this.icon,
    required this.title,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.secondary, size: 22),
      title: Text(title, style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13)),
      subtitle: Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
      trailing: Icon(Icons.chevron_right, color: Colors.white.withOpacity(0.3), size: 20),
      onTap: onTap,
    );
  }
}
