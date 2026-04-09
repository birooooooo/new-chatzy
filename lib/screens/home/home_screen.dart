import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/glass_container.dart';
import '../chat/ai_chatbot_screen.dart';
import 'stories_feed_screen.dart';
import 'settings_screen.dart';
import 'contacts_screen.dart';
import 'chats_list_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const ChatsListScreen(),
    const ContactsScreen(),
    const StoriesFeedScreen(),
    const SettingsScreen(),
  ];

  static const _navItems = [
    (Icons.chat_bubble_outline_rounded, 'Chats'),
    (Icons.call_outlined, 'Calls'),
    (Icons.notifications_none_rounded, 'Updates'),
    (Icons.settings_outlined, 'Settings'),
  ];

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;
    final topPad = MediaQuery.of(context).padding.top;
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Screens
          IndexedStack(
            index: _currentIndex,
            children: _screens,
          ),

          // Bottom fade behind nav bar (gradient only — no BackdropFilter)
          Positioned(
            bottom: 0, left: 0, right: 0,
            height: bottomPad + 74,
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withOpacity(0.55),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Nav bar floating on top
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: _buildNavBar(),
          ),
        ],
      ),
    );
  }

  Widget _buildNavBar() {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Padding(
      padding: EdgeInsets.only(
        left: 12,
        right: 12,
        bottom: bottomPadding + 14,
      ),
      child: Row(
        children: [
          // Floating pill nav
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final itemCount = _navItems.length;
                final itemWidth = constraints.maxWidth / itemCount;
                // Clamp index for the pill (only 4 items now)
                final pillIdx = _currentIndex.clamp(0, itemCount - 1);
                final pillLeft = pillIdx * itemWidth + itemWidth * 0.06;
                final pillWidth = itemWidth * 0.88;

                return ClipRRect(
                  borderRadius: BorderRadius.circular(36),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                    child: Container(
                      height: 60,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.white.withOpacity(0.12),
                            Colors.white.withOpacity(0.05),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(36),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.18),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Stack(
                        children: [
                          // Selected pill
                          AnimatedPositioned(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                            left: pillLeft,
                            top: 6,
                            width: pillWidth,
                            height: 48,
                            child: _GlassPill(),
                          ),
                          // Icons & labels
                          Positioned.fill(
                            child: Row(
                              children: [
                                for (int i = 0; i < _navItems.length; i++)
                                  Expanded(child: _buildNavItem(i)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(width: 10),
          // FAB (+)
          GestureDetector(
            onTap: () {},
            child: ClipRRect(
              borderRadius: BorderRadius.circular(30),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white.withOpacity(0.18),
                        Colors.white.withOpacity(0.06),
                      ],
                    ),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withOpacity(0.2),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.add_rounded, color: Colors.white, size: 26),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index) {
    final isSelected = _currentIndex == index;
    final (icon, label) = _navItems[index];

    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedScale(
            scale: isSelected ? 1.12 : 1.0,
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  icon,
                  color: isSelected ? Colors.white : Colors.white.withOpacity(0.5),
                  size: 22,
                ),
                // Notification dot for Chats
                if (index == 0)
                  Positioned(
                    top: -2,
                    right: -3,
                    child: Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: Color(0xFFFF3B30),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 3),
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 220),
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.white.withOpacity(0.5),
              fontSize: 10,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            ),
            child: Text(label),
          ),
        ],
      ),
    );
  }
}

class _GlassPill extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(26),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(26),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withOpacity(0.22),
                    Colors.white.withOpacity(0.07),
                  ],
                ),
                border: Border.all(
                  color: Colors.white.withOpacity(0.25),
                  width: 1,
                ),
              ),
            ),
            // Top lens glow
            Positioned(
              top: -6,
              left: 14,
              right: 14,
              height: 26,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: RadialGradient(
                    center: Alignment.topCenter,
                    radius: 0.85,
                    colors: [
                      Colors.white.withOpacity(0.7),
                      Colors.white.withOpacity(0.2),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.45, 1.0],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
