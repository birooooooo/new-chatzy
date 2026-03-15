import 'package:flutter/material.dart';

enum CharacterStyle {
  classic,
  robot,
  alien,
  ninja,
  real3d,
  huggy,
}

class CharacterProvider extends ChangeNotifier {
  CharacterStyle _style = CharacterStyle.classic;
  String _mood = 'neutral';

  CharacterStyle get style => _style;
  String get mood => _mood;

  void setMood(String newMood) {
    if (_mood != newMood) {
      _mood = newMood;
      notifyListeners();
    }
  }

  void setStyle(CharacterStyle newStyle) {
    if (_style != newStyle) {
      _style = newStyle;
      notifyListeners();
    }
  }

  String getStyleName(CharacterStyle style) {
    switch (style) {
      case CharacterStyle.classic: return 'Classic Human';
      case CharacterStyle.robot: return 'Cyber Robot';
      case CharacterStyle.alien: return 'Green Alien';
      case CharacterStyle.ninja: return 'Shadow Ninja';
      case CharacterStyle.real3d: return 'Real 10D Person';
      case CharacterStyle.huggy: return 'Huggy Wuggy';
    }
  }
}
