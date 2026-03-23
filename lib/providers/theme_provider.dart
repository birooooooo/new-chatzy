import 'package:flutter/material.dart';

enum BackgroundStyle {
  deepBlack,
  midnightGradient,
  oceanMist,
  cyberPurple,
  glassMesh,
  pureWhite,
  nebula,
}

class ThemeProvider extends ChangeNotifier {
  BackgroundStyle _backgroundStyle = BackgroundStyle.nebula;

  BackgroundStyle get backgroundStyle => _backgroundStyle;

  void setBackgroundStyle(BackgroundStyle style) {
    if (_backgroundStyle != style) {
      _backgroundStyle = style;
      notifyListeners();
    }
  }

  /// True when the active theme has a light/white background.
  /// Use this to swap text and icon colours from white to dark.
  bool get isLightTheme => _backgroundStyle == BackgroundStyle.pureWhite;

  Decoration get backgroundDecoration {
    switch (_backgroundStyle) {
      case BackgroundStyle.nebula:
        return const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/app_bg.png'),
            fit: BoxFit.cover,
          ),
        );
      case BackgroundStyle.deepBlack:
        return const BoxDecoration(color: Color(0xFF1B202D));
      case BackgroundStyle.midnightGradient:
        return const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0F172A), Color(0xFF1E1B4B)],
          ),
        );
      case BackgroundStyle.oceanMist:
        return const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF064E3B), Color(0xFF0F766E)],
          ),
        );
      case BackgroundStyle.cyberPurple:
        return const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF2E1065), Color(0xFF4C1D95)],
          ),
        );
      case BackgroundStyle.glassMesh:
        return const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF002D8B), // Vibrant Royal Blue
              Color(0xFF00A3FF), // Bright Sky Blue
            ],
            stops: [0.0, 1.0],
          ),
        );
      case BackgroundStyle.pureWhite:
        return const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFFFFFF), Color(0xFFF0F4FF)],
          ),
        );
    }
  }
}
