import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:motor/motor.dart';
import 'internal/glass_drag_builder.dart';

class LiquidStretch extends StatelessWidget {
  const LiquidStretch({
    required this.child,
    this.interactionScale = 1.05,
    this.stretch = .5,
    this.resistance = .08,
    this.hitTestBehavior = HitTestBehavior.opaque,
    super.key,
  });

  final double interactionScale;
  final double stretch;
  final double resistance;
  final HitTestBehavior hitTestBehavior;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (stretch == 0 && interactionScale == 1.0) {
      return child;
    }

    return GlassDragBuilder(
      behavior: hitTestBehavior,
      builder: (context, value, child) {
        final scale = value == null ? 1.0 : interactionScale;
        return SingleMotionBuilder(
          value: scale,
          motion: const Motion.smoothSpring(
            duration: Duration(milliseconds: 300),
            snapToEnd: true,
          ),
          builder: (context, value, child) => Transform.scale(
            scale: value,
            child: child,
          ),
          child: MotionBuilder(
            value: value?.withResistance(resistance) ?? Offset.zero,
            motion: value == null
                ? const Motion.bouncySpring(snapToEnd: true)
                : const Motion.interactiveSpring(snapToEnd: true),
            converter: const OffsetMotionConverter(),
            builder: (context, value, child) => RawLiquidStretch(
              stretchPixels: value * stretch,
              child: child,
            ),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}

class RawLiquidStretch extends SingleChildRenderObjectWidget {
  const RawLiquidStretch({
    required this.stretchPixels,
    required super.child,
    super.key,
  });

  final Offset stretchPixels;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return RenderRawLiquidStretch(stretchPixels: stretchPixels);
  }

  @override
  void updateRenderObject(
    BuildContext context,
    RenderRawLiquidStretch renderObject,
  ) {
    renderObject.stretchPixels = stretchPixels;
  }
}

class RenderRawLiquidStretch extends RenderProxyBox {
  RenderRawLiquidStretch({
    required Offset stretchPixels,
  }) : _stretchPixels = stretchPixels;

  Offset _stretchPixels;
  Offset get stretchPixels => _stretchPixels;
  set stretchPixels(Offset value) {
    if (_stretchPixels == value) return;
    _stretchPixels = value;
    markNeedsPaint();
  }

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    return hitTestChildren(result, position: position);
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    final transform = _getEffectiveTransform();
    if (transform == null) {
      return super.hitTestChildren(result, position: position);
    }
    return result.addWithPaintTransform(
      transform: transform,
      position: position,
      hitTest: (BoxHitTestResult result, Offset position) {
        return super.hitTestChildren(result, position: position);
      },
    );
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (child == null) return;
    final transform = _getEffectiveTransform();
    if (transform == null) {
      super.paint(context, offset);
      return;
    }
    final det = transform.determinant();
    if (det == 0 || !det.isFinite) {
      layer = null;
      return;
    }
    layer = context.pushTransform(
      needsCompositing,
      offset,
      transform,
      super.paint,
      oldLayer: layer is TransformLayer ? layer as TransformLayer? : null,
    );
  }

  @override
  void applyPaintTransform(RenderBox child, Matrix4 transform) {
    final effectiveTransform = _getEffectiveTransform();
    if (effectiveTransform != null) {
      transform.multiply(effectiveTransform);
    }
  }

  Matrix4? _getEffectiveTransform() {
    if (_stretchPixels == Offset.zero) return null;
    final scale = getScale(stretchPixels: _stretchPixels, size: size);
    return Matrix4.identity()
      ..scale(scale.dx, scale.dy, 1)
      ..translate(_stretchPixels.dx, _stretchPixels.dy);
  }

  Offset getScale({required Offset stretchPixels, required Size size}) {
    if (size.isEmpty) return const Offset(1, 1);
    final stretchX = stretchPixels.dx.abs();
    final stretchY = stretchPixels.dy.abs();
    final relativeStretchX = size.width > 0 ? stretchX / size.width : 0.0;
    final relativeStretchY = size.height > 0 ? stretchY / size.height : 0.0;
    const stretchFactor = 1.0;
    const volumeFactor = 0.5;
    final baseScaleX = 1 + relativeStretchX * stretchFactor;
    final baseScaleY = 1 + relativeStretchY * stretchFactor;
    final magnitude = math.sqrt(relativeStretchX * relativeStretchX + relativeStretchY * relativeStretchY);
    final targetVolume = 1 + magnitude * volumeFactor;
    final currentVolume = baseScaleX * baseScaleY;
    final volumeCorrection = math.sqrt(targetVolume / currentVolume);
    return Offset(baseScaleX * volumeCorrection, baseScaleY * volumeCorrection);
  }
}

extension OffsetResistanceExtension on Offset {
  Offset withResistance(double resistance) {
    if (resistance == 0) return this;
    final magnitude = math.sqrt(dx * dx + dy * dy);
    if (magnitude == 0) return Offset.zero;
    final resistedMagnitude = magnitude / (1 + magnitude * resistance);
    final scale = resistedMagnitude / magnitude;
    return Offset(dx * scale, dy * scale);
  }
}
