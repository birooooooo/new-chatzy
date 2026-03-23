import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:flutter_animate/flutter_animate.dart';
import '../../theme/app_theme.dart';
import '../../widgets/huggy_3d_character.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _isCharLoaded = false;

  @override
  void initState() {
    super.initState();
    // Simulate loading since o3d doesn't expose a robust onLoad callback
    Future.delayed(1200.ms, () {
      if (mounted) setState(() => _isCharLoaded = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Native Animated Background Elements
          Positioned(
            top: MediaQuery.of(context).size.height * 0.15,
            left: MediaQuery.of(context).size.width * 0.1,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.primary.withOpacity(0.4),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primary.withOpacity(0.4),
                    blurRadius: 100,
                    spreadRadius: 50,
                  ),
                ],
              ),
            ),
          ).animate(onPlay: (controller) => controller.repeat(reverse: true))
           .scale(begin: const Offset(0.8, 0.8), end: const Offset(1.2, 1.2), duration: 2.seconds)
           .fadeIn(duration: 1.seconds),

          Positioned(
            bottom: MediaQuery.of(context).size.height * 0.2,
            right: MediaQuery.of(context).size.width * 0.05,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.secondary.withOpacity(0.3),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.secondary.withOpacity(0.3),
                    blurRadius: 120,
                    spreadRadius: 60,
                  ),
                ],
              ),
            ),
          ).animate(onPlay: (controller) => controller.repeat(reverse: true))
           .scale(begin: const Offset(1.1, 1.1), end: const Offset(0.9, 0.9), duration: 2.5.seconds)
           .fadeIn(duration: 1.seconds),


          // Gradient Overlay to blend character into bottom text
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.0),
                    Colors.black.withOpacity(0.2),
                    Colors.black.withOpacity(0.9),
                    Colors.black,
                  ],
                  stops: const [0.0, 0.5, 0.75, 1.0],
                ),
              ),
            ),
          ),

          // Foreground Content
          SafeArea(
            child: Stack(
              children: [
                // Phase 1: Logo and 3D Character
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // The CHATZY Logo
                      Text(
                        'CHATZY',
                        style: TextStyle(
                          fontSize: 56,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 12,
                          shadows: [
                            Shadow(
                              color: AppTheme.secondary.withOpacity(0.5),
                              blurRadius: 20,
                              offset: const Offset(0, 0),
                            ),
                          ],
                        ),
                      )
                          .animate()
                          .fadeIn(duration: 800.ms)
                          .scale(begin: const Offset(0.8, 0.8), curve: Curves.easeOutBack),
                      
                      const SizedBox(height: 20),
                      
                      // Tagline (Fades out when Huggy jumps)
                      Text(
                        'The Next Generation of Chat',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.secondaryLight.withOpacity(0.7),
                          letterSpacing: 2,
                        ),
                      )
                          .animate()
                          .fadeIn(delay: 400.ms, duration: 600.ms)
                          .fadeOut(delay: 2000.ms, duration: 400.ms),
                    ],
                  ),
                ),

                // Phase 2: Huggy 3D Character jumping on logo
                Center(
                  child: AnimatedOpacity(
                    opacity: _isCharLoaded ? 1.0 : 0.0,
                    duration: 500.ms,
                    child: Huggy3DCharacter(
                      mood: 'happy',
                      size: 350,
                    )
                    .animate(target: _isCharLoaded ? 1.0 : 0.0)
                    // Jump from top with Rotation
                    .moveY(begin: -500, end: -80, duration: 1200.ms, curve: Curves.bounceOut)
                    .rotate(begin: 0, end: 1, duration: 1000.ms) // 360 flip
                    // Impact: Squash and Stretch
                    .scaleY(begin: 1.0, end: 0.7, delay: 800.ms, duration: 150.ms, curve: Curves.easeOut)
                    .then()
                    .scaleY(begin: 0.7, end: 1.0, duration: 300.ms, curve: Curves.elasticOut)
                    // Shake on impact
                    .shake(delay: 850.ms, duration: 400.ms, hz: 5)
                    // Move to right side as loading completes
                    .moveX(begin: 0, end: 150, delay: 3200.ms, duration: 1000.ms, curve: Curves.easeInOutCubic)
                    .fadeOut(delay: 3800.ms, duration: 400.ms),
                  ),
                ),

                // Progress Indicator at the bottom
                Positioned(
                  bottom: 60,
                  left: 0,
                  right: 0,
                  child: Column(
                    children: [
                      SizedBox(
                        width: 40,
                        height: 40,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          color: AppTheme.secondary,
                          backgroundColor: Colors.white.withOpacity(0.05),
                        ),
                      ).animate().fadeIn(delay: 2000.ms),
                      const SizedBox(height: 16),
                      Text(
                        'INITIALIZING...',
                        style: AppTheme.darkTheme.textTheme.bodySmall?.copyWith(
                          letterSpacing: 4,
                          color: Colors.white30,
                        ),
                      ).animate().fadeIn(delay: 2200.ms),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
