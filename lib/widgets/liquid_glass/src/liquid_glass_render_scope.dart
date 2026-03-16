import 'package:flutter/widgets.dart';
import 'liquid_glass_settings.dart';

class LiquidGlassRenderScope extends InheritedWidget {
  const LiquidGlassRenderScope({
    required this.settings,
    required super.child,
    this.useFake = false,
    super.key,
  });

  final LiquidGlassSettings settings;
  final bool useFake;

  static LiquidGlassRenderScope of(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<LiquidGlassRenderScope>();
    assert(
      scope != null,
      'No liquid glass renderer found in context.',
    );
    return scope!;
  }

  static LiquidGlassRenderScope? maybeOf(
    BuildContext context, {
    bool watch = true,
  }) {
    if (watch) {
      return context
          .dependOnInheritedWidgetOfExactType<LiquidGlassRenderScope>();
    } else {
      return context.getInheritedWidgetOfExactType<LiquidGlassRenderScope>();
    }
  }

  @override
  bool updateShouldNotify(covariant InheritedWidget oldWidget) {
    return oldWidget is! LiquidGlassRenderScope ||
        oldWidget.settings != settings ||
        oldWidget.useFake != useFake;
  }
}
