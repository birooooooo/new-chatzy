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
    final themeProvider = Provider.of<ThemeProvider>(context);
    
    return LiquidGlassLayer(
      settings: LiquidGlassSettings(
        glassColor: themeProvider.isLightTheme 
            ? Colors.white.withOpacity(0.1) 
            : Colors.black.withOpacity(0.1),
        blur: 30,
        thickness: 20,
        refractiveIndex: 1.1,
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            // Background Liquid Glass Shape
            Positioned.fill(
              child: IgnorePointer(
                child: Center(
                  child: LiquidGlass.auto(
                    shape: const LiquidOval(),
                    child: Container(
                      width: 300,
                      height: 300,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            themeProvider.accentColor.withOpacity(0.3),
                            themeProvider.accentColor.withOpacity(0.1),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            IndexedStack(
              index: _currentIndex,
              children: _screens,
            ),
          ],
        ),
        bottomNavigationBar: _buildGlassNavBar(),
      ),
    );
  }

  Widget _buildGlassNavBar() {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    
    return GlassContainer(
      height: 65 + bottomPadding,
      borderRadius: BorderRadius.zero, // Make it perfectly rectangular to connect directly with edges
      blur: 20,
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: themeProvider.isLightTheme 
          ? [
              Colors.white.withOpacity(0.95),
              Colors.white.withOpacity(0.85),
            ]
          : [
              const Color(0xFF1A1A1A).withOpacity(0.95),
              const Color(0xFF121212).withOpacity(0.85),
            ],
      ),
      border: Border.all(color: Colors.transparent, width: 0), // Explicitly remove all borders
      child: Padding(
        padding: EdgeInsets.only(
          left: 10, 
          right: 10, 
          top: 10,
          bottom: bottomPadding > 0 ? bottomPadding : 10, // Adjust for safe area
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
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isAiItem = index == 2;
    
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? (isAiItem ? 12 : 16) : 12,
          vertical: isSelected ? (isAiItem ? 6 : 8) : 10,
        ),
        decoration: BoxDecoration(
          color: isSelected 
            ? (themeProvider.isLightTheme 
                ? Colors.black.withOpacity(0.08) 
                : Colors.white.withOpacity(0.12))
            : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isAiItem && isSelected)
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    "AI",
                    style: TextStyle(
                      color: themeProvider.isLightTheme ? Colors.black : Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      height: 1.1,
                      letterSpacing: -0.5,
                    ),
                  ),
                  Text(
                    "chatzy",
                    style: TextStyle(
                      color: themeProvider.isLightTheme 
                          ? Colors.black.withOpacity(0.6) 
                          : Colors.white.withOpacity(0.6),
                      fontWeight: FontWeight.w400,
                      fontSize: 9,
                      height: 1.1,
                    ),
                  ),
                ],
              ).animate().fadeIn(duration: 300.ms).scale(begin: const Offset(0.9, 0.9), end: const Offset(1, 1))
            else ...[
              if (isAiItem)
                Text(
                  "AI",
                  style: TextStyle(
                    color: isSelected 
                      ? (themeProvider.isLightTheme ? Colors.black : Colors.white)
                      : (themeProvider.isLightTheme 
                          ? Colors.black.withOpacity(0.4) 
                          : Colors.white.withOpacity(0.4)),
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    letterSpacing: -0.5,
                  ),
                )
              else
                Icon(
                  icon,
                  color: isSelected 
                    ? (themeProvider.isLightTheme ? Colors.black : Colors.white)
                    : (themeProvider.isLightTheme 
                        ? Colors.black.withOpacity(0.4) 
                        : Colors.white.withOpacity(0.4)),
                  size: 24,
                ),
              if (isSelected && !isAiItem) ...[
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    color: themeProvider.isLightTheme ? Colors.black : Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ).animate().fadeIn(duration: 300.ms).slideX(begin: -0.2, end: 0),
              ],
            ],
          ],
        ),
      ),
    );
  }
}


