import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_shaders/flutter_shaders.dart';
import '../liquid_glass_renderer.dart';
import '../internal/render_liquid_glass_geometry.dart';
import '../internal/transform_tracking_repaint_boundary_mixin.dart';
import '../liquid_glass_render_scope.dart';
import '../logging.dart';
import '../shaders.dart';

class LiquidGlassLayer extends StatefulWidget {
  const LiquidGlassLayer({
    required this.child,
    this.settings = const LiquidGlassSettings(),
    this.fake = false,
    this.useBackdropGroup = false,
    super.key,
  });

  final Widget child;
  final LiquidGlassSettings settings;
  final bool fake;
  final bool useBackdropGroup;

  static bool existsIn(BuildContext context, {bool watch = true}) {
    return LiquidGlassRenderScope.maybeOf(context, watch: watch) != null;
  }

  @override
  State<LiquidGlassLayer> createState() => _LiquidGlassLayerState();
}

class _LiquidGlassLayerState extends State<LiquidGlassLayer>
    with SingleTickerProviderStateMixin {
  late final GeometryRenderLink _link = GeometryRenderLink();
  late final logger = Logger(LgrLogNames.layer);

  @override
  void dispose() {
    _link.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.fake || !ui.ImageFilter.isShaderFilterSupported) {
      return LiquidGlassRenderScope(
        settings: widget.settings,
        useFake: true,
        child: InheritedGeometryRenderLink(
          link: _link,
          child: BackdropGroup(child: widget.child),
        ),
      );
    }

    return RepaintBoundary(
      child: LiquidGlassRenderScope(
        settings: widget.settings,
        child: InheritedGeometryRenderLink(
          link: _link,
          child: ShaderBuilder(
            assetKey: ShaderKeys.liquidGlassRender,
            (context, shader, child) => _RawShapes(
              renderShader: shader!,
              backdropKey: widget.useBackdropGroup
                  ? BackdropGroup.of(context)?.backdropKey
                  : null,
              settings: widget.settings,
              link: _link,
              child: child!,
            ),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

class _RawShapes extends SingleChildRenderObjectWidget {
  const _RawShapes({
    required this.renderShader,
    required this.backdropKey,
    required this.settings,
    required Widget child,
    required this.link,
  }) : super(child: child);

  final ui.FragmentShader renderShader;
  final BackdropKey? backdropKey;
  final LiquidGlassSettings settings;
  final GeometryRenderLink link;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return RenderLiquidGlassLayer(
      devicePixelRatio: MediaQuery.devicePixelRatioOf(context),
      renderShader: renderShader,
      backdropKey: backdropKey,
      settings: settings,
      link: link,
    );
  }

  @override
  void updateRenderObject(
    BuildContext context,
    RenderLiquidGlassLayer renderObject,
  ) {
    renderObject
      ..link = link
      ..devicePixelRatio = MediaQuery.devicePixelRatioOf(context)
      ..settings = settings
      ..backdropKey = backdropKey;
  }
}

class RenderLiquidGlassLayer extends LiquidGlassRenderObject
    with TransformTrackingRenderObjectMixin {
  RenderLiquidGlassLayer({
    required super.renderShader,
    required super.backdropKey,
    required super.devicePixelRatio,
    required super.settings,
    required super.link,
  });

  final _shaderHandle = LayerHandle<BackdropFilterLayer>();
  final _blurLayerHandle = LayerHandle<BackdropFilterLayer>();
  final _clipPathLayerHandle = LayerHandle<ClipPathLayer>();
  final _clipRectLayerHandle = LayerHandle<ClipRectLayer>();

  @override
  Size get desiredMatteSize => switch (owner?.rootNode) {
        final RenderView rv => rv.size,
        final RenderBox rb => rb.size,
        _ => Size.zero,
      };

  @override
  Matrix4 get matteTransform => getTransformTo(null);

  @override
  void onTransformChanged() {
    needsGeometryUpdate = true;
    markNeedsPaint();
  }

  @override
  void paintLiquidGlass(
    PaintingContext context,
    Offset offset,
    List<(RenderLiquidGlassGeometry, GeometryCache, Matrix4)> shapes,
    Rect boundingBox,
  ) {
    if (!attached) return;
    final blurLayer = (_blurLayerHandle.layer ??= BackdropFilterLayer())
      ..backdropKey = backdropKey
      ..filter = ui.ImageFilter.blur(
        tileMode: TileMode.mirror,
        sigmaX: settings.effectiveBlur,
        sigmaY: settings.effectiveBlur,
      );

    final shaderLayer = (_shaderHandle.layer ??= BackdropFilterLayer())
      ..filter = ui.ImageFilter.shader(renderShader);

    final clipPath = Path();
    for (final geometry in shapes) {
      if (!geometry.$1.attached) continue;
      clipPath.addPath(
        geometry.$2.path,
        Offset.zero,
        matrix4: geometry.$3.storage,
      );
    }
    _clipPathLayerHandle.layer = context
        .pushClipPath(
      needsCompositing,
      offset,
      boundingBox,
      clipPath,
      (context, offset) {
        context.pushLayer(
          blurLayer,
          (context, offset) {
            paintShapeContents(
              context,
              offset,
              shapes,
              insideGlass: true,
            );
          },
          offset,
        );
      },
      oldLayer: _clipPathLayerHandle.layer,
    );
    _clipRectLayerHandle.layer = context.pushClipRect(
      needsCompositing,
      offset,
      boundingBox,
      (context, offset) {
        context.pushLayer(
          shaderLayer,
          (context, offset) {
            paintShapeContents(
              context,
              offset,
              shapes,
              insideGlass: false,
            );
          },
          offset,
        );
      },
      oldLayer: _clipRectLayerHandle.layer,
    );
  }

  @override
  void dispose() {
    _blurLayerHandle.layer = null;
    _shaderHandle.layer = null;
    _clipPathLayerHandle.layer = null;
    _clipRectLayerHandle.layer = null;
    super.dispose();
  }
}
