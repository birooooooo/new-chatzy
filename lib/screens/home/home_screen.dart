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
    final themeProvider = Provider.of<ThemeProvider>(context);
    
    return Container(
      decoration: themeProvider.backgroundDecoration,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: IndexedStack(
          index: _currentIndex,
          children: _screens,
        ),
        bottomNavigationBar: _buildGlassNavBar(),
      ),
    );
  }

  Widget _buildGlassNavBar() {
    return GlassContainer(
      margin: EdgeInsets.zero,
      borderRadius: BorderRadius.zero,
      blur: 25,
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.white.withOpacity(0.10),
          Colors.white.withOpacity(0.06),
        ],
      ),
      border: Border(
        top: BorderSide(
          color: Colors.white.withOpacity(0.10),
          width: 0.5,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.only(
          top: 10,
          bottom: MediaQuery.of(context).padding.bottom + 10,
          left: 8,
          right: 8,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(0, Icons.home_outlined, 'Home'),
            _buildNavItem(1, Icons.contact_page_outlined, 'Contacts'),
            _buildCenterNavItem(),
            _buildNavItem(3, Icons.auto_stories_outlined, 'Stories'),
            _buildNavItem(4, Icons.person_outline, 'Profile'),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
            child: Icon(
              icon,
              color: isSelected ? AppTheme.secondary : Colors.white.withOpacity(0.4),
              size: 26,
            ),
          ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: isSelected ? 20 : 0,
            height: 3,
            decoration: BoxDecoration(
              color: AppTheme.secondary,
              borderRadius: BorderRadius.circular(2),
              boxShadow: isSelected ? [
                BoxShadow(
                  color: AppTheme.secondary.withOpacity(0.5),
                  blurRadius: 8,
                  offset: const Offset(0, 1),
                )
              ] : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCenterNavItem() {
    final isSelected = _currentIndex == 2; // AI Chat
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = 2),
      child: GlassContainer(
        width: 58,
        height: 58,
        borderRadius: BorderRadius.circular(20), // Liquid squircle look
        gradient: isSelected
            ? AppTheme.primaryGradient
            : LinearGradient(
                colors: [Colors.white.withOpacity(0.15), Colors.white.withOpacity(0.05)],
              ),
        border: Border.all(
          color: Colors.white.withOpacity(isSelected ? 0.25 : 0.08),
          width: 0.8,
        ),
        child: const Center(
          child: Icon(
            Icons.psychology_outlined,
            color: Colors.white,
            size: 28,
          ),
        ),
      ),
    );
  }
}


