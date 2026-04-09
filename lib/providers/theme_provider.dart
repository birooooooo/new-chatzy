import 'package:flutter/material.dart';

enum BackgroundStyle {
  nebula,
  deepBlack,
}

class ThemeProvider extends ChangeNotifier {
  BackgroundStyle _backgroundStyle = BackgroundStyle.nebula;
  bool _isDarkMode = true;

  BackgroundStyle get backgroundStyle => _backgroundStyle;
  bool get isDarkMode => _isDarkMode;
  bool get isLightTheme => !_isDarkMode;

  void setBackgroundStyle(BackgroundStyle style) {
    if (_backgroundStyle != style) {
      _backgroundStyle = style;
      notifyListeners();
    }
  }

  void setDarkMode(bool value) {
    if (_isDarkMode != value) {
      _isDarkMode = value;
      notifyListeners();
    }
  }

  Decoration get backgroundDecoration {
    if (!_isDarkMode) {
      return const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF0F4FF), Color(0xFFFFFFFF)],
        ),
      );
    }
    switch (_backgroundStyle) {
      case BackgroundStyle.nebula:
        return const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/app_bg.png'),
            fit: BoxFit.cover,
          ),
        );
      case BackgroundStyle.deepBlack:
        return const BoxDecoration(color: Color(0xFF000000));
    }
  }
}
