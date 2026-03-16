import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import '../liquid_glass_renderer.dart';

class GlassShadow extends SingleChildRenderObjectWidget {
  const GlassShadow({
    required this.shape,
    required this.shadows,
    required this.settings,
    super.child,
    super.key,
  });

  final LiquidShape shape;
  final LiquidGlassSettings settings;
  final List<BoxShadow> shadows;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _RenderGlassShadow(
      shape: shape,
      shadows: shadows,
    );
  }

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderGlassShadow renderObject,
  ) {
    renderObject
      ..shape = shape
      ..shadows = shadows;
  }
}

class _RenderGlassShadow extends RenderProxyBox {
  _RenderGlassShadow({
    required LiquidShape shape,
    required List<BoxShadow> shadows,
  })  : _shape = shape,
        _shadows = shadows;

  LiquidShape get shape => _shape;
  LiquidShape _shape;
  set shape(LiquidShape value) {
    if (_shape == value) return;
    _shape = value;
    markNeedsPaint();
  }

  List<BoxShadow> get shadows => _shadows;
  List<BoxShadow> _shadows;
  set shadows(List<BoxShadow> value) {
    if (_shadows == value) return;
    _shadows = value;
    markNeedsPaint();
  }

  double get visibility => _visibility;
  double _visibility = 1;
  set visibility(double value) {
    if (_visibility == value) return;
    _visibility = value.clamp(0, 1);
    markNeedsPaint();
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (shadows.isNotEmpty) {
      final rect = offset & size;
      final canvas = context.canvas;

      for (final shadow in shadows) {
        final shadowRect =
            rect.shift(shadow.offset).inflate(shadow.spreadRadius);
        final paint = shadow
            .copyWith(
              blurRadius: shadow.blurRadius * visibility,
              color: shadow.color.withValues(
                alpha: shadow.color.a * visibility,
              ),
            )
            .toPaint();

        switch (shape) {
          case LiquidRoundedSuperellipse(:final borderRadius):
            canvas.drawRRect(
              RRect.fromRectAndRadius(rect, Radius.circular(borderRadius)),
              paint,
            );

          case LiquidOval():
            canvas.drawOval(shadowRect, paint);
          case LiquidRoundedRectangle(:final borderRadius):
            canvas.drawRRect(
              RRect.fromRectAndRadius(
                shadowRect,
                Radius.circular(borderRadius),
              ),
              paint,
            );
        }
      }
    }

    super.paint(context, offset);
  }
}
