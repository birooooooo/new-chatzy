import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../theme/app_theme.dart';

class AnimatedHumanCharacter extends StatefulWidget {
  final String mood;
  final VoidCallback? onTap;
  final double size;

  const AnimatedHumanCharacter({
    super.key,
    this.mood = 'neutral',
    this.onTap,
    this.size = 120,
  });

  @override
  State<AnimatedHumanCharacter> createState() => _AnimatedHumanCharacterState();
}

class _AnimatedHumanCharacterState extends State<AnimatedHumanCharacter>
    with TickerProviderStateMixin {
  late AnimationController _idleController;
  late AnimationController _waveController;
  late AnimationController _bounceController;
  late AnimationController _moodController;
  
  late Animation<double> _idleAnimation;
  late Animation<double> _waveAnimation;
  late Animation<double> _bounceAnimation;
  late Animation<double> _moodAnimation;
  
  String _currentMood = 'neutral';
  bool _isWaving = false;

  @override
  void initState() {
    super.initState();
    _currentMood = widget.mood;
    
    // Idle breathing animation
    _idleController = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    )..repeat(reverse: true);
    
    _idleAnimation = Tween<double>(begin: 0, end: 6).animate(
      CurvedAnimation(parent: _idleController, curve: Curves.easeInOut),
    );

    // Wave animation
    _waveController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    
    _waveAnimation = Tween<double>(begin: 0, end: 0.5).animate(
      CurvedAnimation(parent: _waveController, curve: Curves.elasticOut),
    );

    // Bounce animation for excited mood
    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    
    _bounceAnimation = Tween<double>(begin: 0, end: 15).animate(
      CurvedAnimation(parent: _bounceController, curve: Curves.elasticOut),
    );

    // Mood transition animation
    _moodController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _moodAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _moodController, curve: Curves.easeOut),
    );

    _updateMoodAnimation();
  }

  @override
  void didUpdateWidget(AnimatedHumanCharacter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.mood != widget.mood) {
      _currentMood = widget.mood;
      _updateMoodAnimation();
    }
  }

  void _updateMoodAnimation() {
    switch (_currentMood) {
      case 'waving':
        _startWave();
        break;
      case 'excited':
        _bounceController.forward().then((_) => _bounceController.reverse());
        break;
      case 'happy':
      case 'sad':
      case 'thinking':
        _moodController.forward(from: 0);
        break;
    }
  }

  void _startWave() {
    if (!_isWaving) {
      setState(() => _isWaving = true);
      _waveController.repeat(reverse: true);
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          _waveController.stop();
          _waveController.reset();
          setState(() => _isWaving = false);
        }
      });
    }
  }

  @override
  void dispose() {
    _idleController.dispose();
    _waveController.dispose();
    _bounceController.dispose();
    _moodController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        _startWave();
        widget.onTap?.call();
      },
      child: AnimatedBuilder(
        animation: Listenable.merge([
          _idleAnimation,
          _waveAnimation,
          _bounceAnimation,
          _moodAnimation,
        ]),
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, -_bounceAnimation.value - _idleAnimation.value),
            child: SizedBox(
              width: widget.size,
              height: widget.size * 1.5,
              child: CustomPaint(
                painter: _CharacterPainter(
                  mood: _currentMood,
                  waveProgress: _waveAnimation.value,
                  moodProgress: _moodAnimation.value,
                  isTransparent: true,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _CharacterPainter extends CustomPainter {
  final String mood;
  final double waveProgress;
  final double moodProgress;
  final bool isTransparent;

  _CharacterPainter({
    required this.mood,
    required this.waveProgress,
    required this.moodProgress,
    this.isTransparent = true,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final headY = size.height * 0.18;
    final bodyY = size.height * 0.45;
    
    // Character colors
    final skinColor = const Color(0xFFFFDBB4);
    final hairColor = const Color(0xFF4A3728);
    final shirtColor = AppTheme.secondary;
    final pantsColor = const Color(0xFF3D5A80);
    
    // Head
    final headPaint = Paint()..color = skinColor;
    final headRadius = size.width * 0.22;
    canvas.drawCircle(Offset(centerX, headY), headRadius, headPaint);
    
    // Hair
    final hairPaint = Paint()..color = hairColor;
    final hairPath = Path();
    hairPath.addArc(
      Rect.fromCircle(center: Offset(centerX, headY - 5), radius: headRadius + 3),
      math.pi,
      math.pi,
    );
    canvas.drawPath(hairPath, hairPaint);
    
    // Eyes
    final eyePaint = Paint()..color = Colors.white;
    final pupilPaint = Paint()..color = const Color(0xFF2D3436);
    
    double eyeOffsetY = 0;
    double eyeScale = 1.0;
    
    switch (mood) {
      case 'happy':
        eyeOffsetY = 2 * moodProgress;
        break;
      case 'sad':
        eyeOffsetY = -2 * moodProgress;
        break;
      case 'excited':
        eyeScale = 1.2;
        break;
      case 'thinking':
        eyeOffsetY = -3 * moodProgress;
        break;
    }
    
    final leftEyePos = Offset(centerX - headRadius * 0.35, headY - 3 + eyeOffsetY);
    final rightEyePos = Offset(centerX + headRadius * 0.35, headY - 3 + eyeOffsetY);
    final eyeRadius = headRadius * 0.18 * eyeScale;
    
    canvas.drawCircle(leftEyePos, eyeRadius, eyePaint);
    canvas.drawCircle(rightEyePos, eyeRadius, eyePaint);
    
    final pupilRadius = eyeRadius * 0.5;
    canvas.drawCircle(leftEyePos, pupilRadius, pupilPaint);
    canvas.drawCircle(rightEyePos, pupilRadius, pupilPaint);
    
    // Eyebrows based on mood
    final eyebrowPaint = Paint()
      ..color = hairColor
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    
    switch (mood) {
      case 'happy':
        _drawCurvedEyebrow(canvas, leftEyePos, eyeRadius, true, eyebrowPaint);
        _drawCurvedEyebrow(canvas, rightEyePos, eyeRadius, true, eyebrowPaint);
        break;
      case 'sad':
        _drawCurvedEyebrow(canvas, leftEyePos, eyeRadius, false, eyebrowPaint);
        _drawCurvedEyebrow(canvas, rightEyePos, eyeRadius, false, eyebrowPaint);
        break;
      case 'thinking':
        _drawThinkingEyebrow(canvas, leftEyePos, eyeRadius, eyebrowPaint);
        _drawCurvedEyebrow(canvas, rightEyePos, eyeRadius, true, eyebrowPaint);
        break;
      default:
        _drawStraightEyebrow(canvas, leftEyePos, eyeRadius, eyebrowPaint);
        _drawStraightEyebrow(canvas, rightEyePos, eyeRadius, eyebrowPaint);
    }
    
    // Mouth based on mood
    final mouthPaint = Paint()
      ..color = const Color(0xFFE17055)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    
    final mouthY = headY + headRadius * 0.45;
    
    switch (mood) {
      case 'happy':
      case 'excited':
      case 'waving':
        _drawSmile(canvas, centerX, mouthY, headRadius * 0.35, mouthPaint);
        break;
      case 'sad':
        _drawFrown(canvas, centerX, mouthY, headRadius * 0.25, mouthPaint);
        break;
      case 'thinking':
        _drawThinkingMouth(canvas, centerX, mouthY, headRadius * 0.2, mouthPaint);
        break;
      default:
        _drawNeutralMouth(canvas, centerX, mouthY, headRadius * 0.2, mouthPaint);
    }
    
    // Body (shirt)
    final bodyPaint = Paint()..color = shirtColor;
    final bodyPath = Path();
    bodyPath.moveTo(centerX - size.width * 0.25, bodyY - headRadius * 0.3);
    bodyPath.quadraticBezierTo(
      centerX,
      bodyY - headRadius * 0.5,
      centerX + size.width * 0.25,
      bodyY - headRadius * 0.3,
    );
    bodyPath.lineTo(centerX + size.width * 0.22, bodyY + size.height * 0.2);
    bodyPath.lineTo(centerX - size.width * 0.22, bodyY + size.height * 0.2);
    bodyPath.close();
    canvas.drawPath(bodyPath, bodyPaint);
    
    // Arms
    final armPaint = Paint()
      ..color = skinColor
      ..strokeWidth = size.width * 0.08
      ..strokeCap = StrokeCap.round;
    
    // Left arm (waves if waving)
    final leftArmStart = Offset(centerX - size.width * 0.22, bodyY);
    Offset leftArmEnd;
    
    if (mood == 'waving' || waveProgress > 0) {
      final waveAngle = -math.pi / 6 - waveProgress * math.pi / 4;
      leftArmEnd = Offset(
        leftArmStart.dx + math.cos(waveAngle) * size.width * 0.35,
        leftArmStart.dy + math.sin(waveAngle) * size.width * 0.35,
      );
    } else {
      leftArmEnd = Offset(centerX - size.width * 0.35, bodyY + size.height * 0.15);
    }
    canvas.drawLine(leftArmStart, leftArmEnd, armPaint);
    
    // Right arm
    final rightArmStart = Offset(centerX + size.width * 0.22, bodyY);
    final rightArmEnd = Offset(centerX + size.width * 0.35, bodyY + size.height * 0.15);
    canvas.drawLine(rightArmStart, rightArmEnd, armPaint);
    
    // Legs/Pants
    final pantsPaint = Paint()..color = pantsColor;
    final pantsPath = Path();
    final pantsTop = bodyY + size.height * 0.18;
    
    // Left leg
    pantsPath.addRRect(RRect.fromRectAndRadius(
      Rect.fromLTWH(centerX - size.width * 0.18, pantsTop, size.width * 0.15, size.height * 0.25),
      const Radius.circular(5),
    ));
    
    // Right leg
    pantsPath.addRRect(RRect.fromRectAndRadius(
      Rect.fromLTWH(centerX + size.width * 0.03, pantsTop, size.width * 0.15, size.height * 0.25),
      const Radius.circular(5),
    ));
    
    canvas.drawPath(pantsPath, pantsPaint);
    
    // Shoes
    final shoePaint = Paint()..color = const Color(0xFF2D3436);
    final shoeTop = pantsTop + size.height * 0.23;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(centerX - size.width * 0.2, shoeTop, size.width * 0.17, size.height * 0.06),
        const Radius.circular(3),
      ),
      shoePaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(centerX + size.width * 0.03, shoeTop, size.width * 0.17, size.height * 0.06),
        const Radius.circular(3),
      ),
      shoePaint,
    );
  }

  void _drawSmile(Canvas canvas, double x, double y, double width, Paint paint) {
    final path = Path();
    path.moveTo(x - width, y);
    path.quadraticBezierTo(x, y + width * 0.7, x + width, y);
    canvas.drawPath(path, paint);
  }

  void _drawFrown(Canvas canvas, double x, double y, double width, Paint paint) {
    final path = Path();
    path.moveTo(x - width, y + width * 0.3);
    path.quadraticBezierTo(x, y - width * 0.3, x + width, y + width * 0.3);
    canvas.drawPath(path, paint);
  }

  void _drawNeutralMouth(Canvas canvas, double x, double y, double width, Paint paint) {
    canvas.drawLine(Offset(x - width, y), Offset(x + width, y), paint);
  }

  void _drawThinkingMouth(Canvas canvas, double x, double y, double width, Paint paint) {
    canvas.drawLine(Offset(x - width * 0.5, y), Offset(x + width, y - 3), paint);
  }

  void _drawCurvedEyebrow(Canvas canvas, Offset eyePos, double eyeRadius, bool happy, Paint paint) {
    final y = eyePos.dy - eyeRadius * 1.6;
    final path = Path();
    if (happy) {
      path.moveTo(eyePos.dx - eyeRadius, y + 3);
      path.quadraticBezierTo(eyePos.dx, y - 2, eyePos.dx + eyeRadius, y + 3);
    } else {
      path.moveTo(eyePos.dx - eyeRadius, y - 2);
      path.quadraticBezierTo(eyePos.dx, y + 3, eyePos.dx + eyeRadius, y - 2);
    }
    canvas.drawPath(path, paint);
  }

  void _drawStraightEyebrow(Canvas canvas, Offset eyePos, double eyeRadius, Paint paint) {
    final y = eyePos.dy - eyeRadius * 1.6;
    canvas.drawLine(
      Offset(eyePos.dx - eyeRadius, y),
      Offset(eyePos.dx + eyeRadius, y),
      paint,
    );
  }

  void _drawThinkingEyebrow(Canvas canvas, Offset eyePos, double eyeRadius, Paint paint) {
    final y = eyePos.dy - eyeRadius * 1.6;
    canvas.drawLine(
      Offset(eyePos.dx - eyeRadius, y + 3),
      Offset(eyePos.dx + eyeRadius, y - 3),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _CharacterPainter oldDelegate) {
    return mood != oldDelegate.mood ||
        waveProgress != oldDelegate.waveProgress ||
        moodProgress != oldDelegate.moodProgress;
  }
}
