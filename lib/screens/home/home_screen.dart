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
    const AiChatbotScreen(),
    const StoriesFeedScreen(),
    const SettingsScreen(),
  ];

  static const _navItems = [
    (Icons.chat_bubble_outline_rounded, 'Chats'),
    (Icons.call_outlined, 'Calls'),
    (Icons.auto_awesome_rounded, 'AI'),
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
        left: 24,
        right: 24,
        bottom: bottomPadding + 14,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final itemCount = _navItems.length;
          final itemWidth = constraints.maxWidth / itemCount;
          final pillLeft = _currentIndex * itemWidth + itemWidth * 0.06;
          final pillWidth = itemWidth * 0.88;

          return ClipRRect(
            borderRadius: BorderRadius.circular(36),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
              child: Container(
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.08),
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
                    // Top shimmer highlight
                    Positioned(
                      top: 0, left: 0, right: 0,
                      height: 1,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.transparent,
                              Colors.white.withOpacity(0.35),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                    // Selected pill
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      left: pillLeft,
                      top: 5,
                      width: pillWidth,
                      height: 46,
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
    );
  }

  Widget _buildNavItem(int index) {
    final isSelected = _currentIndex == index;
    final (icon, label) = _navItems[index];
    const activeColor = Colors.white;
    final inactiveColor = Colors.white.withOpacity(0.45);

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
                  color: isSelected ? activeColor : inactiveColor,
                  size: 22,
                ),
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
              color: isSelected ? activeColor : inactiveColor,
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
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
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
          child: Stack(
            children: [
              // Top specular highlight
              Positioned(
                top: 0, left: 10, right: 10, height: 1,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        Colors.white.withOpacity(0.6),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

