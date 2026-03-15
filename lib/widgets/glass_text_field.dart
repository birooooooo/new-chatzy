import 'package:flutter/material.dart';
import 'package:chat_app/theme/app_theme.dart';
import 'package:chat_app/widgets/glass_container.dart';

class GlassTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String hintText;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final TextInputType keyboardType;
  final TextInputAction textInputAction;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final FocusNode? focusNode;
  final String? Function(String?)? validator;

  const GlassTextField({
    super.key,
    this.controller,
    required this.hintText,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.textInputAction = TextInputAction.done,
    this.onChanged,
    this.onSubmitted,
    this.focusNode,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      height: 50, // Compact height
      padding: EdgeInsets.zero,
      gradient: AppTheme.glassGradient,
      child: Center(
        child: TextFormField(
          controller: controller,
          focusNode: focusNode,
          obscureText: obscureText,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          onChanged: onChanged,
          onFieldSubmitted: onSubmitted,
          validator: validator,
          style: AppTheme.darkTheme.textTheme.bodyMedium?.copyWith(
            color: Colors.white,
          ),
          cursorColor: AppTheme.secondary,
          decoration: InputDecoration(
            isDense: true,
            hintText: hintText,
            hintStyle: AppTheme.darkTheme.textTheme.bodyMedium?.copyWith(
              color: Colors.white.withOpacity(0.4),
            ),
            prefixIcon: prefixIcon != null ? IconTheme(
              data: IconThemeData(color: Colors.white.withOpacity(0.6), size: 20),
              child: prefixIcon!,
            ) : null,
            suffixIcon: suffixIcon != null ? IconTheme(
              data: IconThemeData(color: Colors.white.withOpacity(0.6), size: 20),
              child: suffixIcon!,
            ) : null,
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            errorBorder: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            fillColor: Colors.transparent,
            filled: false,
          ),
        ),
      ),
    );
  }
}
