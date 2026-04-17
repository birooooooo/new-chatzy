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
        color: color ?? Colors.black.withOpacity(0.15),
        borderRadius: effectiveBorderRadius,
        border: border ?? Border.all(
          color: Colors.white.withOpacity(0.18),
          width: 0.8,
        ),
        gradient: gradient ?? LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(opacity + 0.08),
            Colors.white.withOpacity(opacity),
          ],
        ),
      ),
      child: child,
    );
    
    // Only apply BackdropFilter when blur > 0 — each filter costs a full GPU pass
    Widget glassEffect = ClipRRect(
      borderRadius: effectiveBorderRadius,
      child: blur > 0
          ? BackdropFilter(
              filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
              child: content,
            )
          : content,
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
