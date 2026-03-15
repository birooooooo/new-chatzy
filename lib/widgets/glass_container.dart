import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:chat_app/theme/app_theme.dart';

class GlassContainer extends StatelessWidget {
  final Widget? child;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final BorderRadius? borderRadius;
  final double blur;
  final double opacity;
  final Color? color;
  final Gradient? gradient;
  final Border? border;
  final VoidCallback? onTap;

  const GlassContainer({
    super.key,
    this.child,
    this.width,
    this.height,
    this.padding,
    this.margin,
    this.borderRadius,
    this.blur = 15,
    this.opacity = 0.1,
    this.color,
    this.gradient,
    this.border,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveBorderRadius = borderRadius ?? AppTheme.borderRadiusMedium;
    
    Widget content = Container(
      width: width,
      height: height,
      padding: padding,
      // margin: margin, // Removed to contain blur inside border
      decoration: BoxDecoration(
        color: color ?? AppTheme.background.withOpacity(0.01), // Very transparent base
        borderRadius: effectiveBorderRadius,
        border: border ?? Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 0.5,
        ),
        gradient: gradient ?? LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(opacity + 0.05),
            Colors.white.withOpacity(opacity),
          ],
        ),
      ),
      child: child,
    );
    
    // Add ClipRRect to constrain the blur to the container
    Widget glassEffect = ClipRRect(
      borderRadius: effectiveBorderRadius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: content,
      ),
    );

    if (margin != null) {
      glassEffect = Padding(
        padding: margin!,
        child: glassEffect,
      );
    }

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: glassEffect,
      );
    }
    
    return glassEffect;
  }
}
