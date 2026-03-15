import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';

class StableHuggyCharacter extends StatelessWidget {
  final String mood;
  final double size;

  const StableHuggyCharacter({
    super.key,
    required this.mood,
    this.size = 200,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Aura effect
          Container(
            width: size * 0.8,
            height: size * 0.8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: _getMoodColor().withOpacity(0.3),
                  blurRadius: 50,
                  spreadRadius: 10,
                ),
              ],
            ),
          ).animate(onPlay: (controller) => controller.repeat(reverse: true))
           .scale(begin: const Offset(0.8, 0.8), end: const Offset(1.2, 1.2), duration: 2.seconds),

          // Main "Character" Shape (Stylized Huggy face)
          Container(
            width: size * 0.6,
            height: size * 0.6,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppTheme.primary,
                  AppTheme.primary.withOpacity(0.7),
                ],
              ),
              borderRadius: BorderRadius.circular(size * 0.2),
              border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
            ),
            child: Icon(
              _getMoodIcon(),
              size: size * 0.3,
              color: Colors.white,
            ),
          ).animate(onPlay: (controller) => controller.repeat(reverse: true))
           .shimmer(duration: 3.seconds, color: Colors.white.withOpacity(0.1))
           .moveY(begin: -5, end: 5, duration: 1.5.seconds, curve: Curves.easeInOut),
           
          // Particles
          ...List.generate(3, (i) => _buildParticle(i)),
        ],
      ),
    );
  }

  Widget _buildParticle(int index) {
    return Positioned(
      child: Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          color: _getMoodColor().withOpacity(0.6),
          shape: BoxShape.circle,
        ),
      ).animate(onPlay: (controller) => controller.repeat())
       .fadeOut(delay: (index * 500).ms, duration: 2.seconds)
       .moveY(begin: 0, end: -size * 0.4, duration: 2.seconds, curve: Curves.easeOut),
    );
  }

  IconData _getMoodIcon() {
    switch (mood.toLowerCase()) {
      case 'happy': return Icons.face_retouching_natural;
      case 'sad': return Icons.face_unlock_outlined;
      case 'angry': return Icons.face_sharp;
      case 'surprised': return Icons.face_unlock_rounded;
      case 'thinking': return Icons.psychology;
      default: return Icons.face;
    }
  }

  Color _getMoodColor() {
    switch (mood.toLowerCase()) {
      case 'happy': return Colors.pinkAccent;
      case 'sad': return Colors.blueAccent;
      case 'angry': return Colors.redAccent;
      case 'thinking': return Colors.purpleAccent;
      default: return AppTheme.secondary;
    }
  }
}
