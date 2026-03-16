import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_shaders/flutter_shaders.dart';
import '../liquid_glass_renderer.dart';
import 'glass_shadow.dart';
import 'internal/transform_tracking_repaint_boundary_mixin.dart';
import 'liquid_glass_blend_group.dart';
import 'liquid_glass_render_scope.dart';
import 'shaders.dart';
import 'glass_glow.dart';
import 'fake_glass.dart';

class LiquidGlass extends StatelessWidget {
  const LiquidGlass({
    required this.child,
    required this.shape,
    this.glassContainsChild = false,
    this.clipBehavior = Clip.hardEdge,
    this.shadows = const [],
    super.key,
  })  : grouped = false,
        blendGroupLink = null,
        ownLayerConfig = null,
        _auto = false;

  const LiquidGlass.auto({
    required this.child,
    required this.shape,
    LiquidGlassSettings settings = const LiquidGlassSettings(),
    bool fake = false,
    super.key,
    this.glassContainsChild = false,
    this.clipBehavior = Clip.hardEdge,
    this.shadows = const [],
  })  : grouped = true,
        blendGroupLink = null,
        ownLayerConfig = (settings, fake),
        _auto = true;

  const LiquidGlass.grouped({
    required this.child,
    required this.shape,
    super.key,
    this.glassContainsChild = false,
    this.clipBehavior = Clip.hardEdge,
    this.blendGroupLink,
    this.shadows = const [],
  })  : ownLayerConfig = null,
        grouped = true,
        _auto = false;

  const LiquidGlass.withOwnLayer({
    required this.child,
    required this.shape,
    LiquidGlassSettings settings = const LiquidGlassSettings(),
    bool fake = false,
    super.key,
    this.glassContainsChild = false,
    this.clipBehavior = Clip.hardEdge,
    this.blendGroupLink,
    this.shadows = const [],
  })  : ownLayerConfig = (settings, fake),
        grouped = false,
        _auto = false;

  final Widget child;
  final LiquidShape shape;
  final bool glassContainsChild;
  final Clip clipBehavior;
  final bool grouped;
  final GlassGroupLink? blendGroupLink;
  final (LiquidGlassSettings settings, bool fake)? ownLayerConfig;
  final List<BoxShadow> shadows;
  final bool _auto;

  @override
  Widget build(BuildContext context) {
    final hasLayer = LiquidGlassLayer.existsIn(context);
    if (_auto && hasLayer) {
      return _buildWithParentLayer(context);
    }

    if (ownLayerConfig case (final settings, final fake)) {
      if (fake) {
        return FakeGlass(
          shape: shape,
          settings: settings,
          shadows: shadows,
          child: child,
        );
      }
      return LiquidGlassLayer(
        settings: settings,
        child: LiquidGlassBlendGroup(
          blend: 0,
          child: Builder(
            builder: _buildContent,
          ),
        ),
      );
    }

    final scopeSettings = LiquidGlassRenderScope.of(context);
    final fake = scopeSettings.useFake;

    if (fake) {
      return FakeGlass.inLayer(
        shape: shape,
        shadows: shadows,
        child: child,
      );
    }

    final blendGroupLink = grouped
        ? this.blendGroupLink ?? LiquidGlassBlendGroup.maybeOf(context)
        : null;

    if (blendGroupLink == null) {
      return LiquidGlassBlendGroup(
        blend: 0,
        child: Builder(
          builder: (context) => _buildContent(
            context,
            LiquidGlassBlendGroup.of(context),
          ),
        ),
      );
    }

    return _buildContent(
      context,
      blendGroupLink,
    );
  }

  Widget _buildWithParentLayer(BuildContext context) {
    final scopeSettings = LiquidGlassRenderScope.of(context);
    final fake = scopeSettings.useFake;

    if (fake) {
      return FakeGlass.inLayer(
        shape: shape,
        shadows: shadows,
        child: child,
      );
    }

    final hasGroup = LiquidGlassBlendGroup.maybeOf(context) != null;
    if (hasGroup) {
      return _buildContent(
        context,
        LiquidGlassBlendGroup.of(context),
      );
    }

    return LiquidGlassBlendGroup(
      blend: 0,
      child: Builder(
        builder: (context) => _buildContent(
          context,
          LiquidGlassBlendGroup.of(context),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, [GlassGroupLink? blendGroupLink]) {
    final settings = LiquidGlassSettings.of(context);
    if (!ui.ImageFilter.isShaderFilterSupported) {
      return FakeGlass(
        shape: shape,
        shadows: shadows,
        child: child,
      );
    }

    return GlassShadow(
      settings: settings,
      shape: shape,
      shadows: shadows,
      child: _RawLiquidGlass(
        blendGroupLink: blendGroupLink ?? LiquidGlassBlendGroup.of(context),
        shape: shape,
        glassContainsChild: glassContainsChild,
        child: ClipPath(
          clipper: ShapeBorderClipper(shape: shape),
          clipBehavior: clipBehavior,
          child: Opacity(
            opacity: settings.visibility.clamp(0, 1),
            child: GlassGlowLayer(
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

class _RawLiquidGlass extends SingleChildRenderObjectWidget {
  const _RawLiquidGlass({
    required super.child,
    required this.shape,
    required this.glassContainsChild,
    required this.blendGroupLink,
  });

  final LiquidShape shape;
  final bool glassContainsChild;
  final GlassGroupLink? blendGroupLink;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return RenderLiquidGlass(
      shape: shape,
      glassContainsChild: glassContainsChild,
      blendGroupLink: blendGroupLink,
    );
  }

  @override
  void updateRenderObject(
    BuildContext context,
    RenderLiquidGlass renderObject,
  ) {
    renderObject
      ..shape = shape
      ..glassContainsChild = glassContainsChild
      ..blendGroupLink = blendGroupLink;
  }
}

class RenderLiquidGlass extends RenderProxyBox
    with TransformTrackingRenderObjectMixin {
  RenderLiquidGlass({
    required LiquidShape shape,
    required bool glassContainsChild,
    required GlassGroupLink? blendGroupLink,
  })  : _shape = shape,
        _glassContainsChild = glassContainsChild,
        _blendGroupLink = blendGroupLink;

  late LiquidShape _shape;
  LiquidShape get shape => _shape;
  set shape(LiquidShape value) {
    if (_shape == value) return;
    _shape = value;
    markNeedsPaint();
    _updateBlendGroupLink();
  }

  bool _glassContainsChild = true;
  bool get glassContainsChild => _glassContainsChild;
  set glassContainsChild(bool value) {
    if (_glassContainsChild == value) return;
    _glassContainsChild = value;
    _updateBlendGroupLink();
  }

  GlassGroupLink? _blendGroupLink;
  set blendGroupLink(GlassGroupLink? value) {
    if (_blendGroupLink == value) return;
    _unregisterFromParentLayer();
    _blendGroupLink = value;
    _registerWithLink();
  }

  final transformLayerHandle = LayerHandle<TransformLayer>();

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _registerWithLink();
  }

  @override
  void detach() {
    _unregisterFromParentLayer();
    transformLayerHandle.layer = null;
    super.detach();
  }

  void _registerWithLink() {
    if (_blendGroupLink != null) {
      _blendGroupLink!.registerShape(
        this,
        _shape,
        glassContainsChild: _glassContainsChild,
      );
    }
  }

  void _unregisterFromParentLayer() {
    _blendGroupLink?.unregisterShape(this);
  }

  void _updateBlendGroupLink() {
    _blendGroupLink?.updateShape(
      this,
      _shape,
      glassContainsChild: _glassContainsChild,
    );
  }

  late Path _lastPath;

  @override
  void performLayout() {
    super.performLayout();
    _lastPath = shape.getOuterPath(Offset.zero & size);
    _blendGroupLink?.notifyShapeLayoutChanged(this);
  }

  @override
  void onTransformChanged() {
    _blendGroupLink?.notifyShapeLayoutChanged(this);
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    setUpLayer(offset);
  }

  void paintFromLayer(
    PaintingContext context,
    Matrix4 transform,
    Offset offset,
  ) {
    if (attached) {
      transformLayerHandle.layer = context.pushTransform(
        needsCompositing,
        offset,
        transform,
        super.paint,
        oldLayer: transformLayerHandle.layer,
      );
    }
  }

  Path getPath() {
    return _lastPath;
  }
}
