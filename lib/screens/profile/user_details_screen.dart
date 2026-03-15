import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../theme/app_theme.dart';

class UserDetailsScreen extends StatelessWidget {
  final String userName;
  final bool isOnline;
  final String? imageUrl;
  final String? chatId;

  const UserDetailsScreen({
    super.key,
    required this.userName,
    this.isOnline = false,
    this.imageUrl,
    this.chatId,
  });

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
      body: CustomScrollView(
        slivers: [
          // App Bar with Image
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_back_ios, color: Colors.white),
              ),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.3),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.more_vert, color: Colors.white),
                ),
                onPressed: () {
                  _showOptionsMenu(context);
                },
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 40),
                      Stack(
                        children: [
                          Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 4),
                              image: imageUrl != null 
                                  ? DecorationImage(
                                      image: NetworkImage(imageUrl!),
                                      fit: BoxFit.cover,
                                    )
                                  : null,
                            ),
                            child: imageUrl == null 
                                ? const Icon(Icons.person, size: 60, color: AppTheme.primary)
                                : null,
                          ),
                          if (isOnline)
                            Positioned(
                              right: 8,
                              bottom: 8,
                              child: Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: AppTheme.online,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 3),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        userName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isOnline ? 'Online' : 'Last seen 2 hours ago',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Quick Actions
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _ActionButton(
                        icon: Icons.chat,
                        label: 'Message',
                        color: AppTheme.primary,
                        onTap: () {
                          Navigator.pop(context);
                        },
                      ),
                      _ActionButton(
                        icon: Icons.call,
                        label: 'Call',
                        color: AppTheme.success,
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Calling $userName...')),
                          );
                        },
                      ),
                      _ActionButton(
                        icon: Icons.videocam,
                        label: 'Video',
                        color: AppTheme.info,
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Video calling $userName...')),
                          );
                        },
                      ),
                      _ActionButton(
                        icon: Icons.search,
                        label: 'Search',
                        color: Colors.orange,
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Search in chat')),
                          );
                        },
                      ),
                    ],
                  )
                      .animate()
                      .fadeIn(duration: 300.ms),

                  const SizedBox(height: 24),

                  // Info Section
                  Container(
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: AppTheme.borderRadiusMedium,
                      boxShadow: AppTheme.softShadow,
                    ),
                    child: Column(
                      children: [
                        _InfoTile(
                          icon: Icons.info,
                          title: 'About',
                          value: 'Hey there! I\'m using ChatApp',
                        ),
                        const Divider(height: 1),
                        _InfoTile(
                          icon: Icons.phone,
                          title: 'Phone',
                          value: '+1 234 567 8900',
                        ),
                        const Divider(height: 1),
                        _InfoTile(
                          icon: Icons.email,
                          title: 'Email',
                          value: 'user@example.com',
                        ),
                      ],
                    ),
                  )
                      .animate()
                      .fadeIn(delay: 100.ms, duration: 300.ms),

                  const SizedBox(height: 24),

                  const SizedBox(height: 24),
                  
                  // Media Tabs Header
                  const TabBar(
                    indicatorColor: AppTheme.secondary,
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.grey,
                    tabs: [
                      Tab(text: 'Media'),
                      Tab(text: 'Docs'),
                      Tab(text: 'Links'),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Tab Content
                  SizedBox(
                    height: 300,
                    child: TabBarView(
                      children: [
                        _buildMediaGrid(context),
                        _buildDocsList(context),
                        _buildLinksList(context),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  const SizedBox(height: 24),

                  // Settings Section
                  Container(
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: AppTheme.borderRadiusMedium,
                      boxShadow: AppTheme.softShadow,
                    ),
                    child: Column(
                      children: [
                        ListTile(
                          leading: const Icon(Icons.notifications, color: AppTheme.primary),
                          title: const Text('Mute Notifications'),
                          trailing: Switch(
                            value: false,
                            onChanged: (value) {},
                          ),
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: const Icon(Icons.wallpaper, color: AppTheme.primary),
                          title: const Text('Custom Wallpaper'),
                          trailing: const Icon(Icons.chevron_right, color: AppTheme.textLight),
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Change wallpaper')),
                            );
                          },
                        ),
                      ],
                    ),
                  )
                      .animate()
                      .fadeIn(delay: 300.ms, duration: 300.ms),

                  const SizedBox(height: 24),

                  // Danger Zone
                  Container(
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: AppTheme.borderRadiusMedium,
                      boxShadow: AppTheme.softShadow,
                    ),
                    child: Column(
                      children: [
                        ListTile(
                          leading: const Icon(Icons.block, color: AppTheme.error),
                          title: const Text('Block User', style: TextStyle(color: AppTheme.error)),
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Block $userName?')),
                            );
                          },
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: const Icon(Icons.report, color: AppTheme.error),
                          title: const Text('Report User', style: TextStyle(color: AppTheme.error)),
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Report submitted')),
                            );
                          },
                        ),
                      ],
                    ),
                  )
                      .animate()
                      .fadeIn(delay: 400.ms, duration: 300.ms),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
      ),
    );
  }

  Widget _buildMediaGrid(BuildContext context) {
    if (chatId == null) return const Center(child: Text("No shared media", style: TextStyle(color: Colors.grey)));
    
    // In a real app, you'd listen to the provider or a stream
    // For now, let's mock the filtering logic
    return GridView.builder(
      padding: EdgeInsets.zero,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: 6,
      itemBuilder: (context, index) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            image: const DecorationImage(
              image: NetworkImage('https://images.unsplash.com/photo-1511367461989-f85a21fda167?w=500&auto=format&fit=crop&q=60'),
              fit: BoxFit.cover,
            ),
          ),
        );
      },
    );
  }

  Widget _buildDocsList(BuildContext context) {
    return ListView.builder(
      padding: EdgeInsets.zero,
      itemCount: 3,
      itemBuilder: (context, index) {
        return ListTile(
          leading: const Icon(Icons.insert_drive_file_outlined, color: AppTheme.secondary),
          title: Text('Document_$index.pdf', style: const TextStyle(color: Colors.white, fontSize: 14)),
          subtitle: const Text('1.2 MB • Oct 12', style: TextStyle(color: Colors.grey, fontSize: 12)),
          trailing: const Icon(Icons.download_rounded, color: Colors.grey, size: 20),
        );
      },
    );
  }

  Widget _buildLinksList(BuildContext context) {
    return ListView.builder(
      padding: EdgeInsets.zero,
      itemCount: 2,
      itemBuilder: (context, index) {
        return ListTile(
          leading: const Icon(Icons.link_rounded, color: AppTheme.info),
          title: const Text('https://github.com/google/flutter', style: TextStyle(color: AppTheme.info, fontSize: 14)),
          subtitle: const Text('Flutter - Let yourself grow', style: TextStyle(color: Colors.grey, fontSize: 12)),
        );
      },
    );
  }

  void _showOptionsMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.share),
              title: const Text('Share Contact'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Share contact')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Edit Contact'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Edit contact')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: AppTheme.error),
              title: const Text('Delete Chat', style: TextStyle(color: AppTheme.error)),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Chat deleted')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
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
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(height: 8),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _InfoTile({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.primary),
      title: Text(title, style: Theme.of(context).textTheme.bodySmall),
      subtitle: Text(value, style: Theme.of(context).textTheme.titleMedium),
    );
  }
}
