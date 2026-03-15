import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;
import '../providers/character_provider.dart';

/// Enhanced 3D-style cartoon character widget - BIGGER and more cartoon-like
class Character3D extends StatefulWidget {
  final String mood;
  final bool isFlipped;
  final double size;
  final bool isFemale;

  const Character3D({
    super.key,
    this.mood = 'neutral',
    this.isFlipped = false,
    this.size = 280,
    this.isFemale = false,
  });

  @override
  State<Character3D> createState() => _Character3DState();
}

class _Character3DState extends State<Character3D>
    with TickerProviderStateMixin {
  late AnimationController _idleController;
  late AnimationController _moodController;
  late Animation<double> _idleAnimation;
  late Animation<double> _moodAnimation;

  @override
  void initState() {
    super.initState();
    
    _idleController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
    
    _idleAnimation = Tween<double>(begin: 0, end: 12).animate(
      CurvedAnimation(parent: _idleController, curve: Curves.easeInOut),
    );

    _moodController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _moodAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _moodController, curve: Curves.elasticOut),
    );
    
    _moodController.forward();
  }

  @override
  void didUpdateWidget(Character3D oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.mood != widget.mood) {
      _moodController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _idleController.dispose();
    _moodController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final style = context.watch<CharacterProvider>().style;

    return AnimatedBuilder(
      animation: Listenable.merge([_idleAnimation, _moodAnimation]),
      builder: (context, child) {
        // Lean effect for kiss
        double leanAmount = 0;
        if (widget.mood == 'kiss') {
          // Lean towards partner: if flipped (right side) lean left (-), if not flipped (left side) lean right (+)
          leanAmount = (widget.isFlipped ? -30.0 : 30.0) * _moodAnimation.value;
        }

        return Transform.translate(
          offset: Offset(leanAmount, 0),
          child: Transform.scale(
            scaleX: widget.isFlipped ? -1 : 1,
            child: SizedBox(
              width: widget.size,
              height: widget.size * 1.4,
              child: CustomPaint(
                painter: _CartoonCharacterPainter(
                  mood: widget.mood,
                  moodProgress: _moodAnimation.value,
                  style: style,
                  isFemale: widget.isFemale,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _CartoonCharacterPainter extends CustomPainter {
  final String mood;
  final double moodProgress;
  final CharacterStyle style;
  final bool isFemale;

  _CartoonCharacterPainter({
    required this.mood,
    required this.moodProgress,
    required this.style,
    required this.isFemale,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    
    // -- COLOR PALETTES --
    Color skinBase, skinCheek, hairColor, shirtColor, shirtDark, pantsColor;
    
    switch (style) {
      case CharacterStyle.robot:
        skinBase = const Color(0xFFB0BEC5); // Metallic Grey
        skinCheek = const Color(0xFF78909C); // Darker Grey
        hairColor = const Color(0xFF37474F); // Dark Grey
        shirtColor = const Color(0xFF607D8B); // Blue Grey
        shirtDark = const Color(0xFF455A64);
        pantsColor = const Color(0xFF263238);
        break;
      case CharacterStyle.alien:
        skinBase = const Color(0xFFC5E1A5); // Light Green
        skinCheek = const Color(0xFFAED581); // Green
        hairColor = Colors.transparent; // Bald
        shirtColor = const Color(0xFF7E57C2); // Purple Space Suit
        shirtDark = const Color(0xFF5E35B1);
        pantsColor = const Color(0xFF311B92);
        break;
      case CharacterStyle.ninja:
        skinBase = const Color(0xFFFFD5B8); // Normal skin (masked)
        skinCheek = const Color(0xFFFFB6A3);
        hairColor = const Color(0xFF212121); // Black Hood
        shirtColor = const Color(0xFF212121); // Dark Suit
        shirtDark = const Color(0xFF000000);
        pantsColor = const Color(0xFF212121);
        break;
      case CharacterStyle.classic:
      default:
        skinBase = isFemale ? const Color(0xFFFFE0BD) : const Color(0xFFFFD5B8);
        skinCheek = const Color(0xFFFFB6A3);
        hairColor = isFemale ? const Color(0xFFC4713B) : const Color(0xFF3D2314); // Auburn for girl
        shirtColor = isFemale ? const Color(0xFFF06292) : const Color(0xFF4A90D9); // Pink for girl
        shirtDark = isFemale ? const Color(0xFFD81B60) : const Color(0xFF3A7BC8);
        pantsColor = isFemale ? const Color(0xFF4527A0) : const Color(0xFF2D3748);
        break;
    }

    final skinHighlight = Color.lerp(skinBase, Colors.white, 0.4)!;
    final skinShadow = Color.lerp(skinBase, Colors.black, 0.15)!;
    
    // BODY
    _drawBody(canvas, size, centerX, shirtColor, shirtDark);
    
    // NECK
    if (style == CharacterStyle.classic) {
      _drawNeck(canvas, size, centerX, skinBase, skinShadow);
    }

    // ARMS
    _drawArms(canvas, size, centerX, skinBase, skinShadow);
    
    // HEAD (includes ears, face, hair)
    _drawHead(canvas, size, centerX, skinBase, skinCheek, skinHighlight, skinShadow, hairColor);
    
    // LEGS
    _drawLegs(canvas, size, centerX, pantsColor);
  }

  void _drawNeck(Canvas canvas, Size size, double centerX, Color skinBase, Color skinShadow) {
    final neckWidth = size.width * 0.15;
    final neckHeight = size.height * 0.08;
    final neckY = size.height * 0.38;

    final neckPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [skinShadow, skinBase],
      ).createShader(Rect.fromLTWH(centerX - neckWidth / 2, neckY, neckWidth, neckHeight));

    canvas.drawRect(
      Rect.fromCenter(center: Offset(centerX, neckY + neckHeight / 2), width: neckWidth, height: neckHeight),
      neckPaint,
    );
  }

  void _drawBody(Canvas canvas, Size size, double centerX, Color shirtColor, Color shirtDark) {
    final bodyWidth = size.width * 0.55;
    final bodyHeight = size.height * 0.32;
    final bodyY = size.height * 0.52;
    
    // Body shadow
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(centerX + 4, bodyY + 4), width: bodyWidth, height: bodyHeight),
        const Radius.circular(25),
      ),
      Paint()..color = Colors.black.withOpacity(0.15)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );
    
    // Main body with gradient for realism
    final bodyPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [shirtColor, shirtDark],
      ).createShader(Rect.fromCenter(center: Offset(centerX, bodyY), width: bodyWidth, height: bodyHeight));
    
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(centerX, bodyY), width: bodyWidth, height: bodyHeight),
        const Radius.circular(25),
      ),
      bodyPaint,
    );
    
    // Style Specific Details
    if (style == CharacterStyle.robot) {
        // Control panel
        canvas.drawRRect(
            RRect.fromRectAndRadius(
                Rect.fromCenter(center: Offset(centerX, bodyY), width: bodyWidth * 0.4, height: bodyHeight * 0.4),
                const Radius.circular(8)
            ),
            Paint()..color = const Color(0xFF263238),
        );
        // glowing buttons
        canvas.drawCircle(Offset(centerX - 15, bodyY), 5, Paint()..color = Colors.redAccent..maskFilter = const MaskFilter.blur(BlurStyle.solid, 2));
        canvas.drawCircle(Offset(centerX + 15, bodyY), 5, Paint()..color = Colors.greenAccent..maskFilter = const MaskFilter.blur(BlurStyle.solid, 2));

    } else if (style == CharacterStyle.ninja) {
        // Belt
        canvas.drawRect(
            Rect.fromLTWH(centerX - bodyWidth/2, bodyY + bodyHeight * 0.2, bodyWidth, 15),
            Paint()..color = const Color(0xFFD32F2F),
        );
    } else {
        // Collar detail (Classic/Alien)
        final collarPaint = Paint()
          ..color = Colors.white.withOpacity(0.3)
          ..strokeWidth = 3
          ..style = PaintingStyle.stroke;
          
        canvas.drawArc(
          Rect.fromCenter(center: Offset(centerX, bodyY - bodyHeight * 0.42), width: bodyWidth * 0.45, height: 25),
          0, math.pi,
          false,
          collarPaint,
        );

        if (style == CharacterStyle.classic) {
          // Buttons
          final buttonPaint = Paint()..color = Colors.white.withOpacity(0.5);
          canvas.drawCircle(Offset(centerX, bodyY - bodyHeight * 0.15), 4, buttonPaint);
          canvas.drawCircle(Offset(centerX, bodyY + bodyHeight * 0.05), 4, buttonPaint);
          
          // Pocket
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromLTWH(centerX + bodyWidth * 0.1, bodyY - bodyHeight * 0.1, bodyWidth * 0.25, bodyHeight * 0.3),
              const Radius.circular(4),
            ),
            Paint()..color = shirtDark.withOpacity(0.5),
          );
        }
    }
  }

  void _drawEars(Canvas canvas, double centerX, double headY, double headRadius, Color skinBase, Color skinShadow) {
    final earWidth = headRadius * 0.25;
    final earHeight = headRadius * 0.45;
    final earY = headY;

    final earPaint = Paint()
      ..shader = RadialGradient(
        colors: [skinBase, skinShadow],
      ).createShader(Rect.fromLTWH(centerX - headRadius - earWidth, earY - earHeight / 2, earWidth * 2, earHeight));

    // Left Ear
    canvas.drawOval(
      Rect.fromCenter(center: Offset(centerX - headRadius * 0.95, earY), width: earWidth, height: earHeight),
      earPaint,
    );
    // Inner structure
    canvas.drawArc(
      Rect.fromCenter(center: Offset(centerX - headRadius * 0.92, earY), width: earWidth * 0.6, height: earHeight * 0.6),
      math.pi / 2, math.pi, false,
      Paint()..color = skinShadow.withOpacity(0.5)..style = PaintingStyle.stroke..strokeWidth = 2,
    );

    // Right Ear
    canvas.drawOval(
      Rect.fromCenter(center: Offset(centerX + headRadius * 0.95, earY), width: earWidth, height: earHeight),
      earPaint,
    );
    // Inner structure
    canvas.drawArc(
      Rect.fromCenter(center: Offset(centerX + headRadius * 0.92, earY), width: earWidth * 0.6, height: earHeight * 0.6),
      -math.pi / 2, math.pi, false,
      Paint()..color = skinShadow.withOpacity(0.5)..style = PaintingStyle.stroke..strokeWidth = 2,
    );
  }

  void _drawHead(Canvas canvas, Size size, double centerX, Color skinBase, Color skinCheek, Color skinHighlight, Color skinShadow, Color hairColor) {
    var headY = size.height * 0.22;
    // Alien has a taller head
    if (style == CharacterStyle.alien) {
        headY -= 15;
    }
    
    final headRadius = size.width * 0.3; 
    
    // Draw ears before head base
    if (style == CharacterStyle.classic) {
      _drawEars(canvas, centerX, headY, headRadius, skinBase, skinShadow);
    }

    // Head shadow
    canvas.drawCircle(
      Offset(centerX + 5, headY + 5),
      headRadius,
      Paint()..color = Colors.black.withOpacity(0.2)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );
    
    // Head base with gradient for 3D effect
    final headPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.3, -0.4),
        colors: [
            skinHighlight, 
            skinBase, 
            skinShadow
        ],
        stops: const [0, 0.4, 1],
      ).createShader(Rect.fromCircle(center: Offset(centerX, headY), radius: headRadius));
    
    // Alien Head Shape (Oval)
    if (style == CharacterStyle.alien) {
         canvas.drawOval(Rect.fromCenter(center: Offset(centerX, headY), width: headRadius * 2, height: headRadius * 2.4), headPaint);
    } else {
        canvas.drawCircle(Offset(centerX, headY), headRadius, headPaint);
    }

    // Ninja Mask
    if (style == CharacterStyle.ninja) {
        final maskPaint = Paint()..color = const Color(0xFF212121);
        canvas.drawArc(Rect.fromCircle(center: Offset(centerX, headY), radius: headRadius), 0, math.pi, false, maskPaint);
        // Mask opening
         canvas.drawRRect(
            RRect.fromRectAndRadius(
                Rect.fromCenter(center: Offset(centerX, headY - 10), width: headRadius * 1.6, height: headRadius * 0.6),
                const Radius.circular(10)
            ),
             Paint()..color = const Color(0xFFFFD5B8), // Skin showing through
        );
    }
    
    // Cheeks (cartoon blush) - Not for Robots or Ninjas
    if (style != CharacterStyle.robot && style != CharacterStyle.ninja) {
        canvas.drawCircle(
        Offset(centerX - headRadius * 0.55, headY + headRadius * 0.25),
        headRadius * 0.18,
        Paint()..color = skinCheek.withOpacity(0.4)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
        );
        canvas.drawCircle(
        Offset(centerX + headRadius * 0.55, headY + headRadius * 0.25),
        headRadius * 0.18,
        Paint()..color = skinCheek.withOpacity(0.4)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
        );
    }
    
    // Hair
    if (hairColor != Colors.transparent && style != CharacterStyle.ninja) {
         _drawHair(canvas, centerX, headY, headRadius, hairColor);
    }
    
    // Eyes
    _drawEyes(canvas, centerX, headY, headRadius);

    // Eyebrows
    _drawEyebrows(canvas, centerX, headY, headRadius, hairColor);

    // Mouth
    if (style != CharacterStyle.ninja || mood == 'waving' || mood == 'happy' || mood == 'kiss') {
         // Ninja only shows mouth if really happy/talking, otherwise masked
         _drawMouth(canvas, centerX, headY, headRadius);
    }
    
    // Nose (small dot) - Not for Robots
    if (style != CharacterStyle.robot && style != CharacterStyle.alien && style != CharacterStyle.ninja) {
        canvas.drawCircle(
        Offset(centerX, headY + headRadius * 0.15),
        headRadius * 0.06,
        Paint()..color = skinCheek,
        );
    }
    
    // Eyelashes for female character
    if (isFemale && mood != 'sleeping') {
      _drawEyelashes(canvas, centerX, headY, headRadius);
    }
  }

  void _drawEyelashes(Canvas canvas, double centerX, double headY, double headRadius) {
    final leftEyeX = centerX - headRadius * 0.35;
    final rightEyeX = centerX + headRadius * 0.35;
    final eyeY = headY - headRadius * 0.08;
    final eyeRadius = headRadius * 0.2;

    final lashPaint = Paint()
      ..color = const Color(0xFF2D3436)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    for (final eyeX in [leftEyeX, rightEyeX]) {
      final isRight = eyeX > centerX;
      final sign = isRight ? 1 : -1;
      
      // Top lashes
      for (int i = 0; i < 3; i++) {
        final angle = -math.pi / 4 - (i * math.pi / 8);
        final start = Offset(
          eyeX + math.cos(angle * sign) * eyeRadius,
          eyeY + math.sin(angle) * eyeRadius,
        );
        final end = Offset(
          start.dx + math.cos(angle * sign) * 8,
          start.dy + math.sin(angle) * 8,
        );
        canvas.drawLine(start, end, lashPaint);
      }
    }
  }

  void _drawHair(Canvas canvas, double centerX, double headY, double headRadius, Color hairColor) {
    if (style == CharacterStyle.robot) {
        // Antenna instead of hair
        final paint = Paint()..color = const Color(0xFFB0BEC5)..strokeWidth = 4;
        canvas.drawLine(Offset(centerX, headY - headRadius), Offset(centerX, headY - headRadius - 30), paint);
        canvas.drawCircle(Offset(centerX, headY - headRadius - 30), 8, Paint()..color = Colors.redAccent);
        return;
    }
    
    final hairPaint = Paint()..color = hairColor;
    final hairShadow = Color.lerp(hairColor, Colors.black, 0.3)!;
    final hairHighlight = Color.lerp(hairColor, Colors.white, 0.15)!;
    
    // Main hair shape
    final hairPath = Path();
    hairPath.moveTo(centerX - headRadius * 0.95, headY - headRadius * 0.2);
    hairPath.quadraticBezierTo(centerX - headRadius * 0.6, headY - headRadius * 1.4, centerX, headY - headRadius * 1.1);
    hairPath.quadraticBezierTo(centerX + headRadius * 0.6, headY - headRadius * 1.4, centerX + headRadius * 0.95, headY - headRadius * 0.2);
    hairPath.quadraticBezierTo(centerX + headRadius * 0.7, headY - headRadius * 0.6, centerX + headRadius * 0.3, headY - headRadius * 0.85);
    hairPath.quadraticBezierTo(centerX, headY - headRadius * 0.95, centerX - headRadius * 0.3, headY - headRadius * 0.85);
    hairPath.quadraticBezierTo(centerX - headRadius * 0.7, headY - headRadius * 0.6, centerX - headRadius * 0.95, headY - headRadius * 0.2);
    hairPath.close();

    // Texture strands and Female hair features
    if (style == CharacterStyle.classic) {
      // Background layer (shadow)
      canvas.drawPath(hairPath, Paint()..color = hairShadow..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5));
      
      // Main layer with volume
      canvas.drawPath(hairPath, hairPaint);

      if (isFemale) {
        // Ponytail / Long hair extension
        final ponyPath = Path();
        ponyPath.moveTo(centerX + headRadius * 0.8, headY - headRadius * 0.2);
        ponyPath.quadraticBezierTo(centerX + headRadius * 1.5, headY + headRadius * 0.5, centerX + headRadius * 1.2, headY + headRadius * 1.2);
        ponyPath.quadraticBezierTo(centerX + headRadius * 0.8, headY + headRadius * 0.8, centerX + headRadius * 0.7, headY + headRadius * 0.3);
        canvas.drawPath(ponyPath, hairPaint);
        
        // Hair tie
        canvas.drawCircle(Offset(centerX + headRadius * 0.85, headY - headRadius * 0.05), 5, Paint()..color = Colors.lightBlueAccent);
      }

      // Texture strands
      final strandPaint = Paint()..color = hairHighlight.withOpacity(0.3)..style = PaintingStyle.stroke..strokeWidth = 2;
      for (int i = 0; i < 5; i++) {
        final strandPath = Path();
        final offset = (i - 2) * (headRadius * 0.15);
        strandPath.moveTo(centerX + offset - headRadius * 0.2, headY - headRadius * 1.1);
        strandPath.quadraticBezierTo(centerX + offset, headY - headRadius * 0.8, centerX + offset + headRadius * 0.2, headY - headRadius * 0.2);
        canvas.drawPath(strandPath, strandPaint);
      }
    } else {
      canvas.drawPath(hairPath, hairPaint);
    }
    
    // Hair highlight stroke
    canvas.drawPath(
      hairPath,
      Paint()
        ..color = Colors.white.withOpacity(0.1)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
  }

  void _drawEyes(Canvas canvas, double centerX, double headY, double headRadius) {
    final leftEyeX = centerX - headRadius * 0.35;
    final rightEyeX = centerX + headRadius * 0.35;
    // Alien large eyes
    final eyeRadius = style == CharacterStyle.alien ? headRadius * 0.35 : headRadius * 0.2; 
    final eyeY = style == CharacterStyle.alien ? headY : headY - headRadius * 0.08;

    // Eye whites with outline
    for (final eyeX in [leftEyeX, rightEyeX]) {
      // White (or Black for Alien)
      final eyeColor = style == CharacterStyle.alien ? Colors.black : Colors.white;
      canvas.drawCircle(Offset(eyeX, eyeY), eyeRadius, Paint()..color = eyeColor);
      
      // Outline
      if (style != CharacterStyle.alien) {
        canvas.drawCircle(
            Offset(eyeX, eyeY),
            eyeRadius,
            Paint()..color = const Color(0xFF2D3436)..style = PaintingStyle.stroke..strokeWidth = 2,
        );
      }
    }
    

    
    // Pupils with shine or closed eyes for sleeping
    for (final eyeX in [leftEyeX, rightEyeX]) {
      if (mood == 'sleeping' || mood == 'kiss') {
        // Closed eyes
        canvas.drawArc(
          Rect.fromCenter(center: Offset(eyeX, eyeY), width: eyeRadius*1.5, height: eyeRadius),
          0,
          math.pi,
          false,
          Paint()..color = const Color(0xFF2D3436)..style = PaintingStyle.stroke..strokeWidth = 3,
        );
      } else if (style == CharacterStyle.alien) {
          // Alien reflection
          canvas.drawCircle(Offset(eyeX - eyeRadius * 0.3, eyeY - eyeRadius * 0.3), eyeRadius * 0.2, Paint()..color = Colors.white.withOpacity(0.3));
      } else if (style == CharacterStyle.robot) {
          // Glowing Robot eyes
          canvas.drawCircle(Offset(eyeX, eyeY), eyeRadius * 0.6, Paint()..color = Colors.cyanAccent..maskFilter = const MaskFilter.blur(BlurStyle.solid, 4));
      } else {
        // Iris (Classic detail)
        if (style == CharacterStyle.classic) {
          canvas.drawCircle(
            Offset(eyeX, eyeY),
            eyeRadius * 0.7,
            Paint()..shader = RadialGradient(
              colors: [const Color(0xFF2980B9), const Color(0xFF1F3A93)],
            ).createShader(Rect.fromCircle(center: Offset(eyeX, eyeY), radius: eyeRadius * 0.7)),
          );
        }

        // Pupil
        canvas.drawCircle(Offset(eyeX, eyeY), eyeRadius * (style == CharacterStyle.classic ? 0.35 : 0.5), Paint()..color = const Color(0xFF2D3436));
        
        // Main Shine
        canvas.drawCircle(
          Offset(eyeX - eyeRadius * 0.2, eyeY - eyeRadius * 0.2),
          eyeRadius * 0.2,
          Paint()..color = Colors.white,
        );
        // Small secondary shine
        if (style == CharacterStyle.classic) {
          canvas.drawCircle(
            Offset(eyeX + eyeRadius * 0.15, eyeY + eyeRadius * 0.15),
            eyeRadius * 0.1,
            Paint()..color = Colors.white.withOpacity(0.5),
          );
        }
      }
    }
  }

  void _drawEyebrows(Canvas canvas, double centerX, double headY, double headRadius, Color hairColor) {
    final eyebrowPaint = Paint()
      ..color = hairColor
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    
    final leftEyeX = centerX - headRadius * 0.35;
    final rightEyeX = centerX + headRadius * 0.35;
    final browY = headY - headRadius * 0.35;
    final eyeRadius = headRadius * 0.2;
    
    if (mood == 'happy' || mood == 'waving') {
      // Happy arched brows
      final leftBrow = Path()
        ..moveTo(leftEyeX - eyeRadius, browY + 5)
        ..quadraticBezierTo(leftEyeX, browY - 8, leftEyeX + eyeRadius, browY + 5);
      canvas.drawPath(leftBrow, eyebrowPaint);
      
      final rightBrow = Path()
        ..moveTo(rightEyeX - eyeRadius, browY + 5)
        ..quadraticBezierTo(rightEyeX, browY - 8, rightEyeX + eyeRadius, browY + 5);
      canvas.drawPath(rightBrow, eyebrowPaint);
    } else if (mood == 'thinking') {
      // One raised eyebrow
      canvas.drawLine(Offset(leftEyeX - eyeRadius, browY + 8), Offset(leftEyeX + eyeRadius, browY - 8), eyebrowPaint);
      canvas.drawLine(Offset(rightEyeX - eyeRadius, browY), Offset(rightEyeX + eyeRadius, browY), eyebrowPaint);
    } else if (mood == 'surprised') {
      // High arched brows
      final leftBrow = Path()
        ..moveTo(leftEyeX - eyeRadius, browY - 14)
        ..quadraticBezierTo(leftEyeX, browY - 24, leftEyeX + eyeRadius, browY - 14);
      canvas.drawPath(leftBrow, eyebrowPaint);
      
      final rightBrow = Path()
        ..moveTo(rightEyeX - eyeRadius, browY - 14)
        ..quadraticBezierTo(rightEyeX, browY - 24, rightEyeX + eyeRadius, browY - 14);
      canvas.drawPath(rightBrow, eyebrowPaint);      
    } else if (mood == 'angry') {
      // Angry V shape
      canvas.drawLine(Offset(leftEyeX - eyeRadius, browY - 5), Offset(leftEyeX + eyeRadius, browY + 5), eyebrowPaint);
      canvas.drawLine(Offset(rightEyeX - eyeRadius, browY + 5), Offset(rightEyeX + eyeRadius, browY - 5), eyebrowPaint);
    } else if (mood == 'sleeping') {
      // Relaxed flat brows
      canvas.drawLine(Offset(leftEyeX - eyeRadius, browY + 2), Offset(leftEyeX + eyeRadius, browY + 2), eyebrowPaint);
      canvas.drawLine(Offset(rightEyeX - eyeRadius, browY + 2), Offset(rightEyeX + eyeRadius, browY + 2), eyebrowPaint);
    } else if (mood == 'sad') {
      // Sad droopy brows
      canvas.drawLine(Offset(leftEyeX - eyeRadius, browY - 5), Offset(leftEyeX + eyeRadius, browY + 5), eyebrowPaint);
      canvas.drawLine(Offset(rightEyeX - eyeRadius, browY + 5), Offset(rightEyeX + eyeRadius, browY - 5), eyebrowPaint);
    } else {
      // Neutral straight brows
      canvas.drawLine(Offset(leftEyeX - eyeRadius, browY), Offset(leftEyeX + eyeRadius, browY), eyebrowPaint);
      canvas.drawLine(Offset(rightEyeX - eyeRadius, browY), Offset(rightEyeX + eyeRadius, browY), eyebrowPaint);
    }
  }

  void _drawMouth(Canvas canvas, double centerX, double headY, double headRadius) {
    final mouthY = headY + headRadius * 0.5;
    final mouthWidth = headRadius * 0.45;
    
    final mouthPaint = Paint()
      ..color = const Color(0xFFE17055)
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    
    if (mood == 'happy' || mood == 'waving') {
      // Big smile
      final smilePath = Path()
        ..moveTo(centerX - mouthWidth, mouthY - 5)
        ..quadraticBezierTo(centerX, mouthY + mouthWidth * 0.8, centerX + mouthWidth, mouthY - 5);
      canvas.drawPath(smilePath, mouthPaint);
      
      // Teeth hint
      canvas.drawArc(
        Rect.fromCenter(center: Offset(centerX, mouthY + 5), width: mouthWidth * 1.2, height: mouthWidth * 0.4),
        0, math.pi,
        false,
        Paint()..color = Colors.white..strokeWidth = 2..style = PaintingStyle.fill,
      );
    } else if (mood == 'surprised') {
      // O mouth
      canvas.drawCircle(Offset(centerX, mouthY + 5), mouthWidth * 0.5, Paint()..color = const Color(0xFFE17055)..style = PaintingStyle.fill);
      canvas.drawCircle(Offset(centerX, mouthY + 5), mouthWidth * 0.2, Paint()..color = const Color(0xFF7c1e0e)..style = PaintingStyle.fill);
    } else if (mood == 'angry') {
      // Hard frown/grit
      canvas.drawLine(Offset(centerX - mouthWidth * 0.6, mouthY + 5), Offset(centerX + mouthWidth * 0.6, mouthY + 5), mouthPaint);
    } else if (mood == 'sleeping') {
       // Small o
       canvas.drawCircle(Offset(centerX, mouthY + 2), mouthWidth * 0.2, Paint()..color = const Color(0xFFE17055)..style = PaintingStyle.stroke..strokeWidth = 3);
    } else if (mood == 'sad') {
      // Sad frown
      final frownPath = Path()
        ..moveTo(centerX - mouthWidth * 0.7, mouthY + 8)
        ..quadraticBezierTo(centerX, mouthY - 8, centerX + mouthWidth * 0.7, mouthY + 8);
      canvas.drawPath(frownPath, mouthPaint);
    } else if (mood == 'kiss') {
      // Small heart for mouth
      _drawHeart(canvas, Offset(centerX, mouthY), mouthWidth * 0.4, Colors.pinkAccent);
    } else {
      // Neutral line
      canvas.drawLine(
        Offset(centerX - mouthWidth * 0.5, mouthY),
        Offset(centerX + mouthWidth * 0.5, mouthY),
        mouthPaint,
      );
    }
    
    // Floating hearts for kiss mood
    if (mood == 'kiss') {
      final heartPos = Offset(centerX + (isFemale ? -30 : 30), headY - headRadius - 20 - (moodProgress * 40));
      _drawHeart(canvas, heartPos, 15 * moodProgress, Colors.redAccent.withOpacity(1.0 - moodProgress));
    }
  }

  void _drawHeart(Canvas canvas, Offset position, double size, Color color) {
    final paint = Paint()..color = color;
    final path = Path();
    path.moveTo(position.dx, position.dy + size * 0.3);
    path.cubicTo(position.dx - size, position.dy - size, position.dx - size * 1.5, position.dy + size * 0.5, position.dx, position.dy + size);
    path.cubicTo(position.dx + size * 1.5, position.dy + size * 0.5, position.dx + size, position.dy - size, position.dx, position.dy + size * 0.3);
    canvas.drawPath(path, paint);
  }

  void _drawArms(Canvas canvas, Size size, double centerX, Color skinColor, Color skinShadow) {
    final armPaint = Paint()
      ..color = skinColor
      ..strokeWidth = size.width * 0.1
      ..strokeCap = StrokeCap.round;
    
    final shadowPaint = Paint()
      ..color = skinShadow.withOpacity(0.3)
      ..strokeWidth = size.width * 0.1
      ..strokeCap = StrokeCap.round;

    // Left arm
    final leftArmStart = Offset(centerX - size.width * 0.25, size.height * 0.43);
    Offset leftArmEnd;
    
    if (mood == 'waving') {
      final waveOffset = math.sin(moodProgress * math.pi * 3) * 15;
      leftArmEnd = Offset(centerX - size.width * 0.45, size.height * 0.2 + waveOffset);
    } else if (mood == 'thinking') {
      leftArmEnd = Offset(centerX - size.width * 0.15, size.height * 0.28);
    } else {
      leftArmEnd = Offset(centerX - size.width * 0.38, size.height * 0.58);
    }
    
    // Draw shadow first
    canvas.drawLine(leftArmStart + const Offset(3, 3), leftArmEnd + const Offset(3, 3), shadowPaint);
    canvas.drawLine(leftArmStart, leftArmEnd, armPaint);
    
    // Hand
    _drawHand(canvas, leftArmEnd, size.width * 0.1, skinColor, skinShadow, -0.2);
    
    // Right arm
    final rightArmStart = Offset(centerX + size.width * 0.25, size.height * 0.43);
    final rightArmEnd = Offset(centerX + size.width * 0.38, size.height * 0.58);
    
    canvas.drawLine(rightArmStart + const Offset(3, 3), rightArmEnd + const Offset(3, 3), shadowPaint);
    canvas.drawLine(rightArmStart, rightArmEnd, armPaint);
    
    // Hand
    _drawHand(canvas, rightArmEnd, size.width * 0.1, skinColor, skinShadow, 0.2);
  }

  void _drawHand(Canvas canvas, Offset position, double size, Color skinColor, Color skinShadow, double rotation) {
    canvas.save();
    canvas.translate(position.dx, position.dy);
    canvas.rotate(rotation);
    
    final palmHeight = size * 0.6;
    final palmWidth = size * 0.7;
    
    // Palm
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset.zero, width: palmWidth, height: palmHeight),
        Radius.circular(palmHeight * 0.5),
      ),
      Paint()..color = skinColor,
    );

    // Fingers
    final fingerPaint = Paint()
      ..color = skinColor
      ..strokeWidth = size * 0.15
      ..strokeCap = StrokeCap.round;
      
    final fingerShadow = Paint()
      ..color = skinShadow.withOpacity(0.3)
      ..strokeWidth = size * 0.15
      ..strokeCap = StrokeCap.round;

    final fingerLength = size * 0.45;
    
    for (int i = 0; i < 4; i++) {
        final x = -palmWidth/2 + (i + 0.5) * (palmWidth/5) + palmWidth/10;
        final angle = -math.pi/6 + (i * math.pi/9);
        
        final start = Offset(x, -palmHeight * 0.2);
        final end = Offset(x + math.sin(angle) * fingerLength, -palmHeight * 0.3 - math.cos(angle) * fingerLength);
        
        canvas.drawLine(start + const Offset(1, 1), end + const Offset(1, 1), fingerShadow);
        canvas.drawLine(start, end, fingerPaint);
    }
    
    // Thumb
    final thumbStart = Offset(-palmWidth * 0.4, 0);
    final thumbEnd = Offset(-palmWidth * 0.8, palmHeight * 0.2);
    canvas.drawLine(thumbStart + const Offset(1, 1), thumbEnd + const Offset(1, 1), fingerShadow);
    canvas.drawLine(thumbStart, thumbEnd, fingerPaint);

    canvas.restore();
  }

  void _drawLegs(Canvas canvas, Size size, double centerX, Color pantsColor) {
    final legPaint = Paint()..color = pantsColor;
    final shoePaint = Paint()..color = const Color(0xFF1A1A2E);
    
    // Left leg
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(centerX - size.width * 0.13, size.height * 0.78), width: size.width * 0.16, height: size.height * 0.22),
        const Radius.circular(10),
      ),
      legPaint,
    );
    
    // Right leg
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(centerX + size.width * 0.13, size.height * 0.78), width: size.width * 0.16, height: size.height * 0.22),
        const Radius.circular(10),
      ),
      legPaint,
    );
    
    // Shoes
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(centerX - size.width * 0.24, size.height * 0.87, size.width * 0.2, size.height * 0.06),
        const Radius.circular(6),
      ),
      shoePaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(centerX + size.width * 0.04, size.height * 0.87, size.width * 0.2, size.height * 0.06),
        const Radius.circular(6),
      ),
      shoePaint,
    );
  }

  @override
  bool shouldRepaint(covariant _CartoonCharacterPainter oldDelegate) {
    return mood != oldDelegate.mood || moodProgress != oldDelegate.moodProgress;
  }
}
