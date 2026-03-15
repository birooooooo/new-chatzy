import 'package:flutter/material.dart';
import 'package:chat_app/theme/app_theme.dart';
import 'package:chat_app/widgets/glass_container.dart';

class GlassButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String text;
  final Color? color;
  final Gradient? gradient;
  final Widget? icon;
  final double? width;
  final double height;
  final bool isLoading;

  const GlassButton({
    super.key,
    this.onPressed,
    required this.text,
    this.color,
    this.gradient,
    this.icon,
    this.width,
    this.height = 50,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onPressed,
      child: GlassContainer(
        width: width,
        height: height,
        borderRadius: AppTheme.borderRadiusMedium,
        gradient: gradient ?? (color != null ? null : AppTheme.primaryGradient),
        color: color,
        border: Border.all(
          color: Colors.white.withOpacity(0.12),
          width: 0.8,
        ),
        child: Center(
          child: isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (icon != null) ...[
                      icon!,
                      const SizedBox(width: 8),
                    ],
                    Text(
                      text,
                      style: AppTheme.darkTheme.textTheme.labelLarge?.copyWith(
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
