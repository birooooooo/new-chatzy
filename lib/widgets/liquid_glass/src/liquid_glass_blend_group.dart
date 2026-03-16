import 'package:flutter/widgets.dart';
import 'package:flutter_shaders/flutter_shaders.dart';
import '../liquid_glass_renderer.dart';
import 'internal/render_liquid_glass_geometry.dart';
import 'internal/transform_tracking_repaint_boundary_mixin.dart';
import 'liquid_glass.dart';
import 'liquid_glass_render_scope.dart';
import 'rendering/liquid_glass_render_object.dart';
import 'shaders.dart';

class LiquidGlassBlendGroup extends StatefulWidget {
  const LiquidGlassBlendGroup({
    required this.child,
    this.blend = 20.0,
    super.key,
  });

  final double blend;
  final Widget child;

  static const int maxShapesPerLayer = 16;

  static GlassGroupLink of(BuildContext context) {
    final inherited = _InheritedLiquidGlassBlendGroup.of(context);
    assert(inherited != null, 'No LiquidGlassBlendGroup found in context');
    return inherited!.link;
  }

  static GlassGroupLink? maybeOf(BuildContext context) {
    final inherited = _InheritedLiquidGlassBlendGroup.of(context);
    return inherited?.link;
  }

  @override
  State<LiquidGlassBlendGroup> createState() => _LiquidGlassBlendGroupState();
}

class _LiquidGlassBlendGroupState extends State<LiquidGlassBlendGroup> {
  late final GlassGroupLink _geometryLink = GlassGroupLink();

  @override
  void dispose() {
    _geometryLink.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final useFake = LiquidGlassRenderScope.of(context).useFake;
    if (useFake) {
      return _InheritedLiquidGlassBlendGroup(
        link: _geometryLink,
        child: widget.child,
      );
    }

    return _InheritedLiquidGlassBlendGroup(
      link: _geometryLink,
      child: ShaderBuilder(
        (context, shader, child) => _RawLiquidGlassBlendGroup(
          blend: widget.blend,
          shader: shader,
          link: _geometryLink,
          renderLink: InheritedGeometryRenderLink.of(context)!,
          settings: LiquidGlassRenderScope.of(context).settings,
          child: child,
        ),
        assetKey: ShaderKeys.blendedGeometry,
        child: widget.child,
      ),
    );
  }
}

class _InheritedLiquidGlassBlendGroup extends InheritedWidget {
  const _InheritedLiquidGlassBlendGroup({
    required this.link,
    required super.child,
  });

  final GlassGroupLink link;

  static _InheritedLiquidGlassBlendGroup? of(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<_InheritedLiquidGlassBlendGroup>();
  }

  @override
  bool updateShouldNotify(covariant InheritedWidget oldWidget) {
    return oldWidget is! _InheritedLiquidGlassBlendGroup ||
        oldWidget.link != link;
  }
}

class _RawLiquidGlassBlendGroup extends SingleChildRenderObjectWidget {
  const _RawLiquidGlassBlendGroup({
    required this.blend,
    required this.shader,
    required this.renderLink,
    required this.link,
    required this.settings,
    super.child,
  });

  final double blend;
  final FragmentShader shader;
  final GeometryRenderLink renderLink;
  final GlassGroupLink link;
  final LiquidGlassSettings settings;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return RenderLiquidGlassBlendGroup(
      renderLink: renderLink,
      devicePixelRatio: MediaQuery.devicePixelRatioOf(context),
      geometryShader: shader,
      settings: settings,
      link: link,
      blend: blend,
    );
  }

  @override
  void updateRenderObject(
    BuildContext context,
    RenderLiquidGlassBlendGroup renderObject,
  ) {
    renderObject
      ..blend = blend
      ..devicePixelRatio = MediaQuery.devicePixelRatioOf(context)
      ..settings = settings
      ..link = link;
  }
}

class RenderLiquidGlassBlendGroup extends RenderLiquidGlassGeometry
    with TransformTrackingRenderObjectMixin {
  RenderLiquidGlassBlendGroup({
    required super.renderLink,
    required super.devicePixelRatio,
    required super.geometryShader,
    required super.settings,
    required GlassGroupLink link,
    required double blend,
  })  : _link = link,
        _blend = blend {
    link.addListener(_onLinkUpdate);
  }

  GlassGroupLink _link;
  GlassGroupLink get link => _link;
  set link(GlassGroupLink value) {
    if (_link == value) return;
    _link.removeListener(_onLinkUpdate);
    _link = value;
    value.addListener(_onLinkUpdate);
    markNeedsPaint();
  }

  double _blend = 0;
  double get blend => _blend;
  set blend(double value) {
    if (_blend == value) return;
    _blend = value;
    updateShaderWithSettings(settings, devicePixelRatio);
    markGeometryNeedsUpdate(force: true);
    markNeedsPaint();
  }

  void _onLinkUpdate() {
    markGeometryNeedsUpdate();
    markNeedsPaint();
  }

  @override
  void onTransformChanged() {
    markGeometryNeedsUpdate();
    markNeedsPaint();
  }

  @override
  void updateShaderWithSettings(
    LiquidGlassSettings settings,
    double devicePixelRatio,
  ) {
    geometryShader.setFloatUniforms(initialIndex: 2, (value) {
      value.setFloats([
        settings.refractiveIndex,
        settings.effectiveChromaticAberration,
        settings.effectiveThickness,
        blend * devicePixelRatio,
      ]);
    });
  }

  @override
  void updateGeometryShaderShapes(
    List<ShapeGeometry> shapes,
  ) {
    if (shapes.length > LiquidGlassBlendGroup.maxShapesPerLayer) {
      throw UnsupportedError(
        'Only ${LiquidGlassBlendGroup.maxShapesPerLayer} shapes are supported!',
      );
    }

    geometryShader.setFloatUniforms(initialIndex: 6, (value) {
      value.setFloat(shapes.length.toDouble());
      for (final shape in shapes) {
        final center = shape.shapeBounds.center;
        final size = shape.shapeBounds.size;
        value
          ..setFloat(shape.rawShapeType.shaderIndex)
          ..setFloat((center.dx) * devicePixelRatio)
          ..setFloat((center.dy) * devicePixelRatio)
          ..setFloat(size.width * devicePixelRatio)
          ..setFloat(size.height * devicePixelRatio)
          ..setFloat(shape.rawCornerRadius * devicePixelRatio);
      }
    });
  }

  @override
  (Rect, List<ShapeGeometry>, bool) gatherShapeData() {
    final shapes = <ShapeGeometry>[];
    final cachedShapes = geometry?.shapes ?? [];

    var anyShapeChangedInLayer =
        cachedShapes.length != link.shapeEntries.length;

    Rect? layerBounds;

    for (final (
          index,
          MapEntry(
            key: renderObject,
            value: (shape, glassContainsChild),
          )
        ) in link.shapeEntries.indexed) {
      if (!renderObject.attached || !renderObject.hasSize) continue;

      try {
        final shapeData = _computeShapeInfo(
          renderObject,
          shape,
          glassContainsChild,
        );
        shapes.add(shapeData);

        layerBounds = layerBounds?.expandToInclude(shapeData.shapeBounds) ??
            shapeData.shapeBounds;

        final existingShape =
            cachedShapes.length > index ? cachedShapes[index] : null;

        if (existingShape == null) {
          anyShapeChangedInLayer = true;
        } else if (existingShape.shapeBounds != shapeData.shapeBounds ||
            existingShape.shape != shapeData.shape) {
          anyShapeChangedInLayer = true;
        }
      } catch (e) {
        debugPrint('Failed to compute shape info: $e');
      }
    }

    return (
      (layerBounds ?? Rect.zero).inflate(blend * .25),
      shapes,
      anyShapeChangedInLayer,
    );
  }

  @override
  void paintShapeContents(
    RenderObject from,
    PaintingContext context,
    Offset offset, {
    required bool insideGlass,
  }) {
    for (final shapeEntry in link.shapeEntries) {
      final renderObject = shapeEntry.key;
      if (!renderObject.attached ||
          renderObject.glassContainsChild != insideGlass) {
        continue;
      }

      renderObject.paintFromLayer(
        context,
        renderObject.getTransformTo(from),
        offset,
      );
    }
  }

  ShapeGeometry _computeShapeInfo(
    RenderLiquidGlass renderObject,
    LiquidShape shape,
    bool glassContainsChild,
  ) {
    if (!hasSize) {
      throw StateError(
        'Cannot compute shape info because LiquidGlassGeometry has no size yet.',
      );
    }
    if (!renderObject.hasSize) {
      throw StateError(
        'Cannot compute shape info because it has no size yet.',
      );
    }
    final transformToGeometry = renderObject.getTransformTo(this);
    final blendGroupRect = MatrixUtils.transformRect(
      transformToGeometry,
      Offset.zero & renderObject.size,
    );

    return ShapeGeometry(
      renderObject: renderObject,
      shape: shape,
      glassContainsChild: glassContainsChild,
      shapeBounds: blendGroupRect,
      shapeToGeometry: transformToGeometry,
    );
  }
}

class GlassGroupLink with ChangeNotifier {
  GlassGroupLink();
  final Map<RenderLiquidGlass, (LiquidShape shape, bool glassContainsChild)>
      _shapes = {};

  List<
      MapEntry<RenderLiquidGlass,
          (LiquidShape shape, bool glassContainsChild)>> get shapeEntries =>
      _shapes.entries.toList();

  bool get hasShapes => _shapes.isNotEmpty;

  void registerShape(
    RenderLiquidGlass renderObject,
    LiquidShape shape, {
    required bool glassContainsChild,
  }) {
    _shapes[renderObject] = (shape, glassContainsChild);
    notifyListeners();
  }

  void unregisterShape(RenderLiquidGlass renderObject) {
    _shapes.remove(renderObject);
    notifyListeners();
  }

  void updateShape(
    RenderLiquidGlass renderObject,
    LiquidShape shape, {
    required bool glassContainsChild,
  }) {
    _shapes[renderObject] = (shape, glassContainsChild);
    notifyListeners();
  }

  void notifyShapeLayoutChanged(RenderObject renderObject) {
    if (_shapes.containsKey(renderObject)) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _shapes.clear();
    super.dispose();
  }
}
