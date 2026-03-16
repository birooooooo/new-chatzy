import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_shaders/flutter_shaders.dart';
import '../liquid_glass_renderer.dart';
import 'glass_shadow.dart';
import 'internal/optimized_clip.dart';
import 'shaders.dart';
import 'glass_glow.dart';

class FakeGlass extends StatelessWidget {
  const FakeGlass({
    required this.shape,
    required this.child,
    this.settings = const LiquidGlassSettings(),
    this.shadows = const [],
    super.key,
  });

  const FakeGlass.inLayer({
    required this.shape,
    required this.child,
    this.shadows = const [],
    super.key,
  }) : settings = null;

  final LiquidShape shape;
  final LiquidGlassSettings? settings;
  final List<BoxShadow> shadows;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final settings = this.settings ?? LiquidGlassSettings.of(context);
    final backdropKey =
        this.settings == null ? BackdropGroup.of(context)?.backdropKey : null;

    return GlassShadow(
      shape: shape,
      shadows: shadows,
      settings: settings,
      child: OptimizedClip(
        shape: shape,
        child: ShaderBuilder(
          assetKey: ShaderKeys.fakeGlassColor,
          (context, shader, child) => RawFakeGlass(
            shape: shape,
            settings: settings,
            backdropKey: backdropKey,
            colorShader: shader,
            child: Opacity(
              opacity: settings.visibility.clamp(0, 1),
              child: GlassGlowLayer(
                child: this.child,
              ),
            ),
          ),
          child: Opacity(
            opacity: settings.visibility.clamp(0, 1),
            child: GlassGlowLayer(
              child: child!,
            ),
          ),
        ),
      ),
    );
  }
}

class RawFakeGlass extends SingleChildRenderObjectWidget {
  const RawFakeGlass({
    required this.shape,
    required super.child,
    required this.colorShader,
    this.backdropKey,
    this.settings = const LiquidGlassSettings(),
    super.key,
  });

  final LiquidShape shape;
  final LiquidGlassSettings settings;
  final BackdropKey? backdropKey;
  final ui.FragmentShader colorShader;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _RenderFakeGlass(
      shape: shape,
      settings: settings,
      backdropKey: backdropKey,
      colorShader: colorShader,
    );
  }

  @override
  void updateRenderObject(
      BuildContext context, covariant RenderObject renderObject) {
    if (renderObject is _RenderFakeGlass) {
      renderObject
        ..shape = shape
        ..settings = settings
        ..backdropKey = backdropKey
        ..colorShader = colorShader;
    }
  }
}

class _RenderFakeGlass extends RenderProxyBox {
  _RenderFakeGlass({
    required LiquidShape shape,
    required LiquidGlassSettings settings,
    required BackdropKey? backdropKey,
    required ui.FragmentShader colorShader,
  })  : _shape = shape,
        _settings = settings,
        _backdropKey = backdropKey,
        _colorShader = colorShader;

  LiquidShape _shape;
  LiquidShape get shape => _shape;
  set shape(LiquidShape value) {
    if (_shape == value) return;
    _shape = value;
    markNeedsPaint();
  }

  LiquidGlassSettings _settings;
  LiquidGlassSettings get settings => _settings;
  set settings(LiquidGlassSettings value) {
    if (_settings == value) return;
    _settings = value;
    markNeedsPaint();
  }

  BackdropKey? _backdropKey;
  BackdropKey? get backdropKey => _backdropKey;
  set backdropKey(BackdropKey? value) {
    if (_backdropKey == value) return;
    _backdropKey = value;
    markNeedsPaint();
  }

  ui.FragmentShader _colorShader;
  ui.FragmentShader get colorShader => _colorShader;
  set colorShader(ui.FragmentShader value) {
    if (_colorShader == value) return;
    _colorShader = value;
    markNeedsPaint();
  }

  final _saturationLayerHandle = LayerHandle<BackdropFilterLayer>();

  @override
  void dispose() {
    _saturationLayerHandle.layer = null;
    super.dispose();
  }

  bool get _hasBackdropEffect =>
      settings.effectiveBlur != 0 || settings.effectiveSaturation != 1;

  @override
  bool get alwaysNeedsCompositing => _hasBackdropEffect;

  @override
  BackdropFilterLayer? get layer => super.layer as BackdropFilterLayer?;

  @override
  void paint(PaintingContext context, Offset offset) {
    if (!_hasBackdropEffect) {
      this.layer = null;
      _saturationLayerHandle.layer = null;
      final path = shape.getOuterPath(offset & size);
      _paintColor(context.canvas, path);
      _paintSpecular(context.canvas, path, offset & size);
      super.paint(context, offset);
      return;
    }

    final blurFilter = ui.ImageFilter.blur(
      sigmaX: settings.effectiveBlur,
      sigmaY: settings.effectiveBlur,
      tileMode: TileMode.mirror,
    );

    final saturationFilter = _getBackdropFilter(settings);

    final layer = (this.layer ??= BackdropFilterLayer())
      ..filter = blurFilter
      ..blendMode = BlendMode.srcATop
      ..backdropKey = backdropKey;

    context.pushLayer(
      layer,
      (context, offset) {
        if (!ui.ImageFilter.isShaderFilterSupported) {
          context.setWillChangeHint();
        }
        _paintContent(
          context,
          offset,
          saturationFilter: saturationFilter,
        );
      },
      offset,
    );
  }

  void _paintContent(
    PaintingContext context,
    Offset offset, {
    ui.ImageFilter? saturationFilter,
  }) {
    if (saturationFilter != null) {
      final saturationLayer = (_saturationLayerHandle.layer ??=
          BackdropFilterLayer())
        ..filter = saturationFilter
        ..blendMode = BlendMode.srcATop;
      context.pushLayer(
        saturationLayer,
        _paintInnerContent,
        offset,
      );
    } else {
      _saturationLayerHandle.layer = null;
      _paintInnerContent(context, offset);
    }
  }

  void _paintInnerContent(PaintingContext context, Offset offset) {
    final path = shape.getOuterPath(offset & size);
    if (!ui.ImageFilter.isShaderFilterSupported) {
      _paintColor(context.canvas, path);
    }
    _paintSpecular(context.canvas, path, offset & size);
    super.paint(context, offset);
  }

  ui.ImageFilter? _getBackdropFilter(LiquidGlassSettings settings) {
    if (settings.effectiveSaturation == 1) {
      return null;
    }
    if (ui.ImageFilter.isShaderFilterSupported) {
      final glassColor = settings.effectiveGlassColor;
      _colorShader.setFloatUniforms((value) {
        value
          ..setSize(size)
          ..setColor(glassColor)
          ..setFloat(settings.effectiveSaturation);
      });
      return ui.ImageFilter.shader(_colorShader);
    }
    return ui.ColorFilter.matrix(
      _createSaturationMatrix(settings.effectiveSaturation),
    );
  }

  List<double> _createSaturationMatrix(double saturation) {
    const lumR = 0.299;
    const lumG = 0.587;
    const lumB = 0.114;
    final s = saturation;
    final invSat = 1.0 - s;
    return [
      lumR * invSat + s, lumG * invSat, lumB * invSat, 0, 0,
      lumR * invSat, lumG * invSat + s, lumB * invSat, 0, 0,
      lumR * invSat, lumG * invSat, lumB * invSat + s, 0, 0,
      0, 0, 0, 1, 0,
    ];
  }

  void _paintColor(Canvas canvas, Path path) {
    final color = settings.effectiveGlassColor;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawPaint(paint);
  }

  void _paintSpecular(Canvas canvas, Path path, Rect bounds) {
    final squareBounds = Rect.fromCircle(
      center: bounds.center,
      radius: bounds.size.longestSide / 2,
    );
    final lightIntensity = settings.effectiveLightIntensity.clamp(0.0, 1.0);
    final ambientStrength = settings.effectiveAmbientStrength.clamp(0.0, 1.0);
    final alpha = Curves.easeOut.transform(lightIntensity);
    final color = Colors.white.withValues(alpha: alpha);
    final rad = settings.lightAngle;
    final x = math.cos(rad);
    final y = math.sin(rad);
    final lightCoverage = ui.lerpDouble(.3, .5, lightIntensity)!;
    final alignmentWithShortestSide = (size.aspectRatio < 1 ? y : x).abs();
    final aspectAdjustment = 1 - 1 / size.aspectRatio;
    final gradientScale = aspectAdjustment * (1 - alignmentWithShortestSide);
    final inset = ui.lerpDouble(0, .5, gradientScale.clamp(0, 1))!;
    final secondInset = ui.lerpDouble(lightCoverage, .5, gradientScale.clamp(0, 1))!;

    final shader = LinearGradient(
      colors: [
        color,
        color.withValues(alpha: ambientStrength),
        color.withValues(alpha: ambientStrength),
        color,
      ],
      stops: [
        inset,
        secondInset,
        1 - secondInset,
        1 - inset,
      ],
      begin: Alignment(x, y),
      end: Alignment(-x, -y),
    ).createShader(squareBounds);

    final paint = Paint()
      ..shader = shader
      ..style = PaintingStyle.stroke
      ..strokeWidth = ui.lerpDouble(1, 2, lightIntensity)!
      ..color = color.withValues(alpha: color.a * 0.4)
      ..blendMode = BlendMode.hardLight;
    canvas.drawPath(path, paint);

    final overlay = Paint()
      ..shader = shader
      ..style = PaintingStyle.stroke
      ..strokeWidth = (settings.effectiveThickness / 20)
      ..blendMode = BlendMode.overlay;
    canvas.drawPath(path, overlay);
  }
}
