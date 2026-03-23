import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/glass_container.dart';
import '../../widgets/glass_text_field.dart';
import '../chat/chat_screen.dart';
import '../chat/ai_chatbot_screen.dart';
import 'stories_feed_screen.dart';
import 'settings_screen.dart';
import 'contacts_screen.dart';
import 'chats_list_screen.dart';
import '../../widgets/liquid_glass/liquid_glass_renderer.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: _buildGlassNavBar(),
    );
  }

  Widget _buildGlassNavBar() {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        bottom: bottomPadding + 20,
      ),
      child: GlassContainer(
        height: 75,
        borderRadius: BorderRadius.circular(37.5),
        blur: 50,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF001C90).withOpacity(0.4),
            const Color(0xFF00D2FF).withOpacity(0.3),
          ],
        ),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 0.8,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildNavItem(0, Icons.home_outlined, 'Home'),
            _buildNavItem(1, Icons.contact_page_outlined, 'Contacts'),
            _buildNavItem(2, Icons.psychology_outlined, 'AI Chat'),
            _buildNavItem(3, Icons.auto_stories_outlined, 'Stories'),
            _buildNavItem(4, Icons.person_outline, 'Profile'),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _currentIndex == index;
    final isAiItem = index == 2;
    
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected 
            ? Colors.white.withOpacity(0.15) 
            : Colors.transparent,
          borderRadius: BorderRadius.circular(25),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isAiItem)
              const Text(
                "AI",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  letterSpacing: -0.5,
                  height: 1.1,
                ),
              )
            else
              Icon(
                icon,
                color: Colors.white,
                size: 24,
              ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w400,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
