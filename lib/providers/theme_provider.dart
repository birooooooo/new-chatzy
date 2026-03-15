import 'package:flutter/material.dart';

enum BackgroundStyle {
  deepBlack,
  midnightGradient,
  oceanMist,
  cyberPurple,
  glassMesh,
}

class ThemeProvider extends ChangeNotifier {
  BackgroundStyle _backgroundStyle = BackgroundStyle.deepBlack;

  BackgroundStyle get backgroundStyle => _backgroundStyle;

  void setBackgroundStyle(BackgroundStyle style) {
    if (_backgroundStyle != style) {
      _backgroundStyle = style;
      notifyListeners();
    }
  }

  Decoration get backgroundDecoration {
    switch (_backgroundStyle) {
      case BackgroundStyle.deepBlack:
        return const BoxDecoration(color: Color(0xFF000000));
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
          gradient: RadialGradient(
            center: Alignment(-0.8, -0.6),
            radius: 1.5,
            colors: [
              Color(0xFF1E293B),
              Color(0xFF0F172A),
              Color(0xFF020617),
            ],
            stops: [0.0, 0.4, 1.0],
          ),
        );
    }
  }
}
